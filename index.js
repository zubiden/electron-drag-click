let setup = () => {
  console.warn('electron-drag-click: Unsupported platform.');
};

if (process.platform === 'darwin') {
  const binding = require('bindings')('electron_drag_click.node');
  setup = binding.setup;
}

module.exports = setup;
