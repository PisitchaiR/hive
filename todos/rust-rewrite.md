# Rust Rewrite Plan — Hive Terminal

## Goal

Rewrite Hive in Rust for cross-platform support (macOS → Linux → Windows), long-term maintainability, and performance. Current Swift + libghostty stack stays in production while Rust core is built in parallel.

## Stack Decision

| Layer | Library | Reason |
|-------|---------|--------|
| UI | `iced` | Elm-style state management fits Hive's workspace model |
| Rendering | `wgpu` (via iced) | GPU-accelerated, cross-platform |
| VT emulation | `alacritty_terminal` | Battle-tested, handles edge cases |
| PTY | `portable-pty` (wezterm) | macOS/Linux/Windows abstraction |
| Font | `cosmic-text` | Shaping + subpixel rendering |
| IPC / hook | Keep existing unix socket protocol | HiveHook binary stays unchanged |

## Phases

### Phase 1 — Core Terminal (no UI)
- [ ] PTY spawn via `portable-pty`
- [ ] Feed output into `alacritty_terminal` VT state machine
- [ ] Read back cell grid and render to terminal (stdout proof-of-concept)
- [ ] Verify: `htop`, `vim`, color output work correctly

### Phase 2 — Basic Windowed Renderer
- [ ] `iced` window with `wgpu` backend
- [ ] Render cell grid (glyph atlas + `cosmic-text`)
- [ ] Keyboard input → PTY write
- [ ] Mouse scroll
- [ ] Resize handling (PTY SIGWINCH)

### Phase 3 — Session Model
- [ ] Port `Session` concept (one PTY per tab)
- [ ] Port `PaneNode` tree (splits + tabs) into iced widget tree
- [ ] OSC 7 cwd tracking
- [ ] Shell integration script generation (port `ShellIntegration.swift`)

### Phase 4 — Workspace + Agent Layer
- [ ] Port `Workspace` and `WorkspaceStore` state model
- [ ] HookServer (unix socket listener) — reuse same JSON protocol
- [ ] `AgentTemplate` definitions (builtin + custom)
- [ ] Activity state tracking per session

### Phase 5 — Persistence + Settings
- [ ] `state.json` read/write (same schema for migration compatibility)
- [ ] `settings.json` — custom agents, theme, font, sidebar mode
- [ ] Window restore on launch

### Phase 6 — macOS Polish
- [ ] Native menu bar (iced supports this)
- [ ] Cmd+, settings panel
- [ ] Drag-and-drop tab reorder
- [ ] System color scheme / dark mode

### Phase 7 — Cross-platform
- [ ] Linux build (test on Ubuntu)
- [ ] Windows build (ConPTY via `portable-pty`)
- [ ] CI matrix: macOS + Linux + Windows

## Migration Strategy

- Swift version stays in `main` branch — shipped to users
- Rust rewrite lives in `rust` branch (or separate repo)
- Phase 1–2 can be done without touching Swift code
- Switch to Rust build when Phase 4 is complete and stable
- Keep `HiveHook` binary protocol unchanged so hooks work on both versions

## References

- [alacritty_terminal](https://github.com/alacritty/alacritty/tree/master/alacritty_terminal)
- [portable-pty](https://github.com/wezterm/wezterm/tree/main/pty)
- [iced](https://github.com/iced-rs/iced)
- [cosmic-text](https://github.com/pop-os/cosmic-text)
- [wezterm source](https://github.com/wezterm/wezterm) — reference implementation
