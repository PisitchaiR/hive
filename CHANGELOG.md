# Changelog

Notable changes per release. Tagged commits use `vX.Y.Z` shortform.

## v0.15.2 — 2026-05-26

- Fixed: splitting a pane now opens the new pane in the tab's actual current directory, not a stale cached one. Previously, `cd`'ing in a tab whose shell didn't emit `OSC 7` (fish/nu, themes that re-derive the prompt from `$PWD` via `precmd`, user rc that wipes `chpwd_functions`) left Hive's per-tab cwd cache pointing at the original workspace dir — and the new pane landed there instead of where the user actually was. Split (and Duplicate Tab) now ask the kernel for the foreground process's cwd via libproc and prefer that over the cache.


## v0.15.1 — 2026-05-26

- Fixed: agent auto-launch on systems with PTY-shim shells (Amazon Q / Kiro CLI / Fig) — previously the user's `.zshrc` `exec`'d into the shim mid-source, so the wrapper never reached `agentLaunchBlock` and the agent didn't start. Hive now launches the agent before sourcing user rc.
- Fixed: new tabs no longer land at `$HOME` — ghostty's `/usr/bin/login -fp` wrapper resets cwd, so the launcher now restores the intended directory from `HIVE_CWD` before starting the shell. New tabs again inherit the previous tab's working directory.
- About panel now shows the Info.plist version string, so dev builds reveal the commit SHA suffix (e.g. `0.15.0+8d4af42-dirty`) instead of the bare release version.

## v0.15.0 — 2026-05-25

- Quick Open (⌘P) — fuzzy-search across workspaces, open tabs, and agents from a single palette; ↩ jumps to a workspace/tab or opens a new tab in the chosen agent.
- In-app auto-update — Hive now downloads and installs the latest release in the background (Settings → About → Check for Updates); no manual DMG needed.
- Fixed: the git activity indicator now detects working-tree changes in real-time using FSEvents instead of polling.
- Fixed: agent commands (Claude, Codex, etc.) now auto-launch reliably on every new tab — previously `HIVE_AGENT` was set but the shell wrapper didn't run on some systems.
- New tabs now inherit the working directory of the active tab instead of the workspace default.
- Agent picker popover now shows the launch directory at the bottom; click it to choose a different folder before opening the agent.
- Fixed: tab bar activity indicators now show running (blue) and waiting (yellow) states alongside the existing command-failure (red) dot, matching the sidebar.

## v0.14.1 — 2026-05-22

- Drag a tab from one window's tab bar onto another window's to move it across — the terminal, its scrollback, and any running process all come with it.

## v0.14.0 — 2026-05-22

- Multiple windows — press ⌘⇧N to open a new window. Each window keeps its own workspaces, tabs, and sidebar, and every open window is restored when you relaunch kooky.

## v0.13.0 — 2026-05-22

- Custom agents based on Claude Code can now carry their own environment variables — set `ANTHROPIC_BASE_URL` / `ANTHROPIC_AUTH_TOKEN` in a custom agent's new `env` field (Settings → Agents) to point it at a Claude-compatible mirror or proxy.

## v0.12.4 — 2026-05-21

- Fixed: arrow keys in `vim` (and other full-screen programs) now work over SSH to older remote machines.

## v0.12.3 — 2026-05-21

- The tab and sidebar name now follow the terminal title — `ssh` into a remote host and the tab shows its `user@host` instead of the local folder, then reverts when you exit.

## v0.12.2 — 2026-05-20

- Antigravity CLI joins the agent menu — Google's Go-based successor to Gemini CLI.
- Fixed: picking Antigravity from the `+` menu when only the IDE is installed now surfaces a clear CLI install hint instead of accidentally opening the IDE app.

## v0.12.1 — 2026-05-19

- Check for Updates in the Kooky menu — see what's new and download the latest DMG in one click.

## v0.12.0 — 2026-05-19

- Grok Build (xAI) joins the agent menu.

## v0.11.6 — 2026-05-18

- Fixed: shell history and Tab completion now survive kooky restarts.
- Fixed: environment variables in `~/.zshenv`, `~/.zprofile`, and `~/.bash_profile` now load in kooky terminals.

## v0.11.5 — 2026-05-18

- Fixed: long Chinese / Japanese / Korean inputs no longer leave a phantom space mid-line.
- Fixed: when a long input wraps to a second line, the first line no longer disappears.

## v0.11.4 — 2026-05-18

- Fixed: Chinese / Japanese / Korean IME candidate window now shows right under the cursor instead of flying off-screen.

## v0.11.3 — 2026-05-16

- Drag a file or folder from Finder onto any kooky terminal pane → its path drops in at the cursor. Multi-file drag = space-separated paths.

## v0.11.2 — 2026-05-16

- Click anywhere on your zsh prompt to jump the cursor there.

## v0.11.1 — 2026-05-15

- Right-click menu redesigned to match kooky's brutalist style.
- Fixed: right-clicking selections that start with `-` no longer crashes the agent.
- Fixed: paste in the right-click menu now matches ⌘V behavior in zsh / vim.
- Fixed: right-clicking inside an inactive split now activates that pane first.

## v0.11.0 — 2026-05-15

- Right-click selection → "Ask <agent>". Select any text in a terminal, right-click, pick an agent → a new tab spawns with the selection as the first prompt.

## v0.10.8 — 2026-05-15

- Claude conversations resume across kooky restarts. Quit mid-conversation → next launch picks up where you left off.
- Settings → Agents → `resume-conversation-when-reopen` toggle.

## v0.10.7 — 2026-05-15

- GitHub Copilot tabs now show the mid-run "attention" dot.

## v0.10.6 — 2026-05-15

- Custom agents can inherit from a builtin — pick **Claude Code** as the base and your custom (e.g. "Claude Opus") inherits the icon, brand tint, and lifecycle tracking.
- Fixed: custom-based-on-Claude tabs now revert to Terminal when the agent exits.

## v0.10.5 — 2026-05-15

- Define your own agent. Settings → Agents → `+ add custom agent` wires any CLI as a first-class kooky agent.

## v0.10.4 — 2026-05-15

- GitHub Copilot CLI joins the agent menu.

## v0.10.3 — 2026-05-15

- Default agent for `+` and `⌘T`. Pick any agent in Settings → Agents → default to skip the popover.

## v0.10.2 — 2026-05-14

- Per-agent launch options. Each agent row in Settings has a chevron to add options like `--model opus`.

## v0.10.1 — 2026-05-14

- Customise the `+` menu — hide agents you don't use, reorder the rest.
- Settings UI redesigned with a brutalist-minimal aesthetic.

## v0.10.0 — 2026-05-14

- Cursor CLI joins the agent menu.

## v0.9.12 — 2026-05-14

- Cleaner "agent not installed" message.
- Fixed: tab icon reverts to Terminal when the agent's CLI is missing.

## v0.9.11 — 2026-05-14

- Mac-style text editing shortcuts in the shell:
  - `Cmd+←` / `Cmd+→` — beginning / end of line
  - `Option+←` / `Option+→` (or `Ctrl+←` / `Ctrl+→`) — jump by word
  - `Cmd+Backspace` — delete to start of line
  - `Option+Backspace` — delete previous word

## v0.9.10 — 2026-05-14

- Friendlier "agent not installed" message.
- Fixed: `curl | bash` installers now write to your real `~/.zshrc`.

## v0.9.9 — 2026-05-13

- Non-focused panes fully dim, including terminal content.

## v0.9.8 — 2026-05-13

- Spot the focused pane at a glance — non-focused panes dim their chrome.

## v0.9.7 — 2026-05-12

- New Settings window (`⌘,`) backed by `~/.kooky/settings.json`. v1 surfaces Font Family / Font Size / Cursor Style.
- First-launch onboarding offers to import `~/.config/ghostty/config`.

## v0.9.6 — 2026-05-12

- Smoother sidebar-collapse animation.
- Per-row Unset button in the proxy popover.
- New app icon.

## v0.9.5 — 2026-05-11

- `Shift+Enter` inserts a newline. Plain Enter still submits.
- About panel polish.

## v0.9.4 — 2026-05-11

- Status bar git state auto-refreshes during agent sessions.
- Network proxy slot in the status bar.
- Tab icon promotes when you manually launch an agent.

## v0.9.3 — 2026-05-11

- Tab icon promotes when you manually launch an agent inside a Terminal tab.

## v0.9.2 — 2026-05-11

- `exit` / `logout` closes the tab automatically.
- Reveal in Finder — right-click any tab pill or workspace row.
- Reopen Closed Tab (`⌘⇧T`).
- `⌃⇥` / `⌃⇧⇥` for per-pane tab cycling.

## v0.9.1 — 2026-05-11

- Reveal in Finder for tabs and workspaces.
- Reopen Closed Tab (`⌘⇧T`) restores agent + cwd + custom title.
- `⌃⇥` / `⌃⇧⇥` per-pane tab cycling.

## v0.9.0 — 2026-05-10

- Pane status bar showing live working-tree state — Python venv, Node version, git branch, git diff.
- Click the Node version pill → switch between installed nvm versions. Click the git branch pill → switch branches.

## v0.8.0 — 2026-05-10

- Find in scrollback (`⌘F`) per-pane. `⌘G` / `⌘⇧G` for next / previous match.
- Gemini CLI activity dot.
- OpenCode activity dot.
- Amp activity dot.

## v0.7.6 — 2026-05-09

- App icon.
- macOS 14 minimum (was 15).

## v0.7.5 — 2026-05-09

- `.app` bundle. Drag `dist/Kooky.app` into `/Applications` and launch from Spotlight.

## v0.7.4 — 2026-05-09

- Workspace-level command-failure dot — red dot on the sidebar row when any tab has a non-zero last exit.

## v0.7.3 — 2026-05-09

- Per-tab last-command status — small red dot when the most recent command exited non-zero. Hover for `exit N · 12.4s`.
- `⌘↑` / `⌘↓` to jump between prompts.

## v0.7.2 — 2026-05-09

- Manual rename for tabs and workspaces. Right-click → *Rename…*. Persists.

## v0.7.1 — 2026-05-09

- URL `⌘+click` opens in your default browser.
- Mouse shape follows libghostty (pointing-hand on URLs, resize on TUI splits).
- Font size shortcuts: `⌘=` increase, `⌘-` decrease, `⌘0` reset.
- Clear Pane (`⌘K`).
- Sidebar mode persists across launches.

## v0.7.0 — 2026-05-09

- Three-state sidebar (`full` / `compact` / `hidden`), `⌘⌃S` cycles.
- Top chrome strip with dedicated drag handle, sidebar toggle, traffic-light clearance.
- View menu becomes the navigation hub — Tab `⌘1`-`⌘9`, Workspace `⌥⌘1`-`⌥⌘9`, splits, sidebar toggle. New Help menu.
- Custom About panel.

## v0.6.0 — 2026-05-09

- Drag-reorder workspaces and tabs with animated drop indicators.
- Cross-pane tab move via drag.
- View menu with `Tab 1`-`9` and `Workspace 1`-`9` switches.
- Double-click tab bar zooms the window.
- Right-click menus show keyboard shortcut hints.

## v0.5.0 — 2026-05-08

- Recursive splits — `⌘D` splits right, `⌘⇧D` splits down, `⌘[` / `⌘]` cycles focus, `⌘W` closes a tab and collapses an empty pane.
- Right-click context menus on tabs and sidebar rows.
- Click-to-focus across panes.

## v0.4.0 — 2026-05-08

- Codex integration — sidebar shows the Codex icon while it's running.
- Auto-promote agent on hook — plain Terminal tabs that report a Claude / Codex hook upgrade to the matching template.
- IME — Chinese / Japanese / Korean / Vietnamese compose properly.

## v0.3.0 — 2026-05-08

- Agent activity dot in the sidebar — blue when processing, amber when waiting on input, hidden when idle.
- Real Claude Code integration.

## v0.2.0 — 2026-05-08

- Keyboard shortcuts: `⌘T` new tab, `⌘N` new workspace, `⌘W` close tab, `⌘⇧W` close workspace, `⌘1`-`⌘9` switch tab.
- Persistence — workspaces, tabs, agent type, and cwd survive relaunch.
- Hidden title bar; tab bar sits at the window top edge.

## v0.1.0 — 2026-05-08

First public release. Native macOS terminal with vertical-tab workspaces and one-click AI agent sessions (Claude Code / Codex / Gemini CLI / OpenCode / Amp).
