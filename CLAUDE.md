# Pulse — notes for Claude

- Run `make check` after every change; it must stay green with no warnings.
- `swift test`/`swift build` need `--build-system native` and the Testing framework paths from the Makefile — use the make targets.
- Verify visual changes with `make preview` and look at `build/preview.png` (screen capture is not permitted on this Mac).
- `make install` replaces /Applications/Pulse.app and relaunches it.
- Keep it light: idle CPU should stay around 1% or lower.
