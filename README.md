# electron-drag-click

## Description

```js
$ npm i electron-drag-click
```

This Native Node Module allows you to change the behavior of how frameless
Electron browser windows handle pointer events on macOS. Chromium's built-in
mechanism ignores pointer events in draggable regions in frameless windows.
This module changes the built-in hit testing so in frameless windows pointer
events are propagated even in draggable regions.

It is based on my earlier PR in the Electron repository (https://github.com/electron/electron/pull/38208), which after some discussion with maintainers was decided not to be
merged in, and rather be handled in a separate Native Module.

The code is using ObjectiveC's runtime method swizzling capability, which allows
you to alter the implementation of an existing selector. Shoutout to [@tzahola](https://github.com/tzahola), who helped me dealing with these APIs.

## Usage

``` typescript
const { app, BrowserWindow } = require('electron');
const electronDragClick = require('electron-drag-click');

electronDragClick();

app.on('ready', () => {
  const win = new BrowserWindow({
    width: 800,
    height: 600,
    frame: false,
  });

  win.loadFile('./index.html');
});
```
