# Meandros

A Roblox Studio plugin that generates mazes with configurable algorithms and settings.

## Toolchain

Managed by [Rokit](https://github.com/rojo-rbx/rokit) (`rokit.toml`). Run `rokit install` after cloning.
- **rojo** — builds `plugin/src/` into the plugin file
- **wally** — Luau package manager
- **wally-package-types** — generates Luau types for Wally packages
- **lune** — runs the test suite
- **selene** / **StyLua** — lint / format

## Dev and release builds

There are two Rojo project files with the same tree:

- `plugin.project.json` — **release** build (what gets published)
- `dev.project.json` — **dev** build: identical, plus a `DEV_BUILD` BoolValue in the root folder

`plugin/src/Config.luau` checks for `DEV_BUILD` and derives everything that must differ between the builds:
`Config.isDevMode`, `Config.pluginName` (`Meandros (DEV)`), `Config.widgetId`, `Config.settingsPrefix`
(`MeandrosDev_` vs `Meandros_`) and `Config.log(...)` (prints only in dev). Both builds can be installed at once.
Never hardcode the plugin name, widget id or settings keys — read them from `Config`. Use `Config.log` instead of
`print` for debug output.

## Build & develop

```bash
rokit install && wally install   # first time after cloning

# Dev: build Meandros_Dev.rbxm straight into Studio's local Plugins folder and rebuild on every save
npm run watch

# Release: build/Meandros.rbxm (drag into Studio → right-click → Publish as Plugin)
npm run build

# Install the release build locally next to the dev build
npm run install-release

# Run the Lune test suite (.lune/tests)
npm test

# Lint
selene plugin/src/
```

Studio reloads the dev plugin automatically when the file changes, **if** Studio's "reload plugins on file change"
setting is on (Studio Settings → search "reload"; restart Studio once after enabling). Local plugins don't appear
in Manage Plugins. Each reload prints `unloading` / `loading version …` in Output for the dev build.

## Project structure

```
plugin/
  Version.txt                   -- plugin version; must be bumped every commit
  Packages/                     -- Wally-managed packages; do not edit
  src/
    init.server.luau            -- entry point; mounts the React root into CoreGui
    App/
      init.luau                 -- root App React component
      Page.luau                 -- page wrapper/transition component
      Theme.luau                -- theme colors and styling values
      Components/
        Navigation/             -- sidebar and sidebar buttons
        PrimitiveComponents/    -- generic UI building blocks (Button, Dropdown, TextLabel, ...)
        StudioComponents/       -- thin React wrappers around Studio API objects
      Hooks/                    -- custom React hooks (useSpring)
      StatusPages/              -- one page per sidebar section (Home, Build, Structure, Appearance, Settings)
    Assets/
      Icons.luau                -- icon asset ID references
    Builder/                    -- turns generated grids into Parts in the workspace
    Classes/                    -- generic data structures (Stack)
    Data/
      Constants.luau            -- shared constant values
    Generators/                 -- maze grid + generation algorithms
      MazeGenerator.luau        -- algorithm registry; runs a generation to completion
      Algorithms/               -- one module per maze algorithm (RandomizedDepthFirstSearch)
    Services/                   -- workspace-facing orchestration (MazeService: preview/revert/build)
    Utils/                      -- small pure helper functions
.lune/
  tests/                        -- automated tests, run with Lune via `npm test`
  manual-tests/                 -- tests run by hand during development
PCAssets/                       -- source images (plugin icons, cursors) uploaded as Roblox assets
tools/
  test.js                       -- runs every .luau file in .lune/tests via Lune
plugin.project.json             -- Rojo project: release build
dev.project.json                -- Rojo project: dev build (release + DEV_BUILD marker)
wally.toml                      -- Luau package dependencies
rokit.toml                      -- toolchain pin (rojo, wally, wally-package-types, lune, selene, StyLua)
.vscode/                        -- workspace settings + recommended extensions (committed)
```

## Architecture

The plugin is a single-context Roblox Studio plugin (no client/server split). The entry point (`init.server.luau`) creates a React root mounted to `CoreGui` and tears it down when the plugin unloads.

All UI is built with React (`jsdotlua/react` + `jsdotlua/react-roblox`). `StudioComponents/` wraps imperative Studio API calls (e.g. `plugin:CreateToolbar`) in React components using `useEffect` so they are created/destroyed with the component lifecycle.

## Key conventions

**Naming**:
- Files: `PascalCase.luau`
- React components: PascalCase functions exported as the module itself (`return MyComponent`)
- Variables and function params: `camelCase`
- Luau types: `PascalCase` with `export type`

**Requires**: Use relative `script.Parent` chains. No path aliases.

**React elements**: Use `local e = React.createElement` at the top of each component file.

**Plugin context**: The `plugin` global is passed as a prop from the entry point down through the tree. Use `StudioPluginContext` to avoid prop-drilling when it gets deep.

## Dependencies (Wally)

| Package | Purpose |
|---|---|
| React | UI framework |
| ReactRoblox | React renderer for Roblox |
| Sift | Immutable table utilities (arrays, dictionaries, sets) |
| Ripple | Spring/tween motion library (backs the `useSpring` hook) |
| Charm | Atomic state management (the `*Slice.luau` modules) |
| ReactCharm | React bindings for Charm atoms |

## Linting & formatting

- **Selene**: `selene.toml` with `std = "roblox"`.
- **StyLua**: Set as the Luau formatter in `.vscode/settings.json` with format on save. Autosave is `onFocusChange`
  on purpose: every save triggers a rebuild and a plugin reload in Studio.

## Workflow

**Commit messages**: Prefix with `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, or `test:` (e.g. `feat: add Kruskal maze generator`). Enforced by the `commit-msg` hook in `.githooks/` — run `git config core.hooksPath .githooks` once after cloning to enable it.

**Version bump**: `plugin/Version.txt` must be raised on every commit (the same hook compares the staged version against `HEAD`'s). Bump patch for fixes/chores, minor for features, per semver.

**Plan before multi-file changes**: For anything touching more than one file (a new generation algorithm, a new Studio component tree, a cross-cutting refactor), write a short plan first — expected behavior, affected files, how it'll be verified — before writing code. Single-file fixes and small tweaks don't need this.

## What to avoid

- Don't edit `plugin/Packages/` — managed by Wally.
- Don't hand-edit `plugin.project.json` without making the same change in `dev.project.json` (the two trees must
  stay identical apart from `DEV_BUILD`) and checking that `rojo build` still succeeds for both.
- Don't use `game:GetService()` for services that don't exist in a plugin context — prefer the `plugin` API directly.
- Don't add global state at module level; keep all state inside React components or contexts.
