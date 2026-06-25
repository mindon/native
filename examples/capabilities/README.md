# zero-native capabilities example

This example shows guarded OS capabilities from trusted WebView code:

- Platform support discovery.
- Notifications.
- Clipboard text read and write.
- Message dialogs.
- Credential set, get, and delete.
- File-drop events delivered to Zig and the WebView event bridge.

Run with the system backend:

```sh
zig build run -Dplatform=macos -Dweb-engine=system
```

Run the headless test path:

```sh
zig build test -Dplatform=null
```
