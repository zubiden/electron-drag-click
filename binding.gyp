{
  "targets": [
    {
      "target_name": "electron_drag_click",
      "conditions": [
        [ 'OS=="mac"', {
            # Only build the real macOS addon
            "sources": [ "electron_drag_click.mm" ],
            "include_dirs": [
              "<!@(node -p \"require('node-addon-api').include\")"
            ],
            "dependencies": [
              "<!(node -p \"require('node-addon-api').gyp\")"
            ],
            "defines": [ "NAPI_DISABLE_CPP_EXCEPTIONS" ],
            "xcode_settings": {
              "OTHER_CPLUSPLUSFLAGS": [
                "-std=c++20",
                "-stdlib=libc++",
                "-mmacosx-version-min=10.12"
              ]
            }
        }],
        [ 'OS!="mac"', {
            # On Windows (or Linux), compile nothing
            "sources": []
        }]
      ]
    }
  ]
}
