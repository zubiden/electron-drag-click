#import <Cocoa/Cocoa.h>
#include <Foundation/Foundation.h>
#import <objc/runtime.h>

#include <napi.h>

static IMP g_originalHitTest;
static IMP g_originalMouseEvent;

static char kIsDraggableKey;
static char kIsDraggingKey;
static char kMouseEventTypeKey;

NSView* viewUnderneathPoint(NSView* self, NSPoint point) {
  NSView *contentView = self.window.contentView;

  for (NSView *v in contentView.subviews.reverseObjectEnumerator) {
    if (v != self && ![v isKindOfClass:[NSVisualEffectView class]]) {
      NSPoint pointInView = [v convertPoint:point fromView:nil];
      if ([v hitTest:pointInView] && [v mouse:pointInView inRect:v.bounds]) {
        return v;
      }
    }
  }

  return nil;
}

NSView* swizzledHitTest(id obj, SEL sel, NSPoint point) {
  NSView* originalReturn =
    ((NSView*(*) (id, SEL, NSPoint))g_originalHitTest)(obj, sel, point);

  objc_setAssociatedObject(obj,
                           &kIsDraggableKey,
                           @(originalReturn == nil),
                           OBJC_ASSOCIATION_COPY_NONATOMIC);

  NSView* viewUnderPoint = viewUnderneathPoint(obj, point);

  return [viewUnderPoint hitTest:point];
}

void swizzledMouseEvent(id obj, SEL sel, NSEvent* theEvent) {
  NSView* view = obj;
  NSNumber* isDraggable = objc_getAssociatedObject(view.window.contentView,
                                                  &kIsDraggableKey);
  NSNumber* isDragging = objc_getAssociatedObject(obj,
                                                  &kIsDraggingKey);
  NSNumber* previousEventType = objc_getAssociatedObject(obj,
                                                         &kMouseEventTypeKey);

  if ([theEvent type] == NSEventTypeLeftMouseDown && isDraggable.boolValue) {
    NSView* self = obj;
    [self.window performWindowDragWithEvent:theEvent];
  }

  BOOL isPreviousMouseDown =
    previousEventType.integerValue == NSEventTypeLeftMouseDown;
  BOOL isCurrentMouseDragged = [theEvent type] == NSEventTypeLeftMouseDragged;

  if (isPreviousMouseDown && isCurrentMouseDragged && isDraggable.boolValue) {
    objc_setAssociatedObject(obj,
                             &kIsDraggingKey,
                             @(YES),
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
  }

  if ([theEvent type] == NSEventTypeLeftMouseUp && isDragging.boolValue) {
    objc_setAssociatedObject(obj,
                             &kIsDraggingKey,
                             @(NO),
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
  } else {
    ((void(*) (id, SEL, NSEvent*))g_originalMouseEvent)(obj, sel, theEvent);
  }

  objc_setAssociatedObject(obj,
                           &kMouseEventTypeKey,
                           @([theEvent type]),
                           OBJC_ASSOCIATION_COPY_NONATOMIC);
}

void Setup(const Napi::CallbackInfo &info) {
  auto hitTestMethod = class_getInstanceMethod(
    NSClassFromString(@"BridgedContentView"),
    NSSelectorFromString(@"hitTest:"));

  g_originalHitTest = method_setImplementation(hitTestMethod,
    (IMP)&swizzledHitTest);

  auto mouseEventMethod = class_getInstanceMethod(
    NSClassFromString(@"RenderWidgetHostViewCocoa"),
    NSSelectorFromString(@"mouseEvent:"));

  g_originalMouseEvent = method_setImplementation(mouseEventMethod,
    (IMP)&swizzledMouseEvent);
}

Napi::Object Init(Napi::Env env, Napi::Object exports) {
  exports.Set(Napi::String::New(env, "setup"),
              Napi::Function::New(env, Setup));

  return exports;
}

NODE_API_MODULE(electron_drag_click, Init)
