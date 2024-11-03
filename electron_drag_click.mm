#import <Cocoa/Cocoa.h>
#include <Foundation/Foundation.h>
#import <objc/runtime.h>

#include <napi.h>

static IMP g_originalHitTest;
static IMP g_originalMouseEvent;

static char kAssociatedObjectKey;

NSView* viewUnderneathPoint(NSView* self, NSPoint point) {
  NSView *contentView = self.window.contentView;
  NSArray *views = [contentView subviews];

  for (NSView *v in views) {
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

  NSNumber* isDraggable = @(originalReturn == nil);
  objc_setAssociatedObject(obj,
                          &kAssociatedObjectKey,
                          isDraggable,
                          OBJC_ASSOCIATION_COPY_NONATOMIC);

  NSView* viewUnderPoint = viewUnderneathPoint(obj, point);

  return [viewUnderPoint hitTest:point];
}

void swizzledMouseEvent(id obj, SEL sel, NSEvent* theEvent) {
  ((void(*) (id, SEL, NSEvent*))g_originalMouseEvent)(obj, sel, theEvent);

  NSView* view = obj;
  NSNumber* isDragging = objc_getAssociatedObject(view.window.contentView,
                                                  &kAssociatedObjectKey);

  if ([theEvent type] == NSEventTypeLeftMouseDown && isDragging.boolValue) {
    NSView* self = obj;
    [self.window performWindowDragWithEvent:theEvent];
  }
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
