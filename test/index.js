const { app, BrowserWindow } = require('electron');
const electronDragClick = require('../index');

electronDragClick();

app.on('ready', () => {
  const win = new BrowserWindow({
    width: 800,
    height: 600,
    frame: false,
  });

  win.loadFile('./index.html');
});
