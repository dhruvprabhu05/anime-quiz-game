# Notes for Claude

This is a Roblox game (Luau, synced into Studio with Rojo via `default.project.json`).

## Layout

- `src/shared/` (ReplicatedStorage.Shared): `Config.luau` (game constants and product IDs), `Remotes.luau` (remote names + helpers), `Data/` (archetypes and questions).
- `src/server/` (ServerScriptService.Server): `Main.server.luau` starts the modules in `Services/` (`PlayerDataService`, `GamePassService`, `QuizService`, `MonetizationService`).
- `src/client/` (StarterPlayerScripts.Client): `Main.client.luau` starts `Audio/MusicPlayer` and mounts the React Luau UI from `UI/App.luau`.
- `Packages/` (ReplicatedStorage.Packages): React Luau from Wally. Git-ignored; recreate with `wally install`. If Wally can't reach its index from a sandboxed shell, `python3 tools/wally_fetch.py . '{"React":"jsdotlua/react@17.2.1","ReactRoblox":"jsdotlua/react-roblox@17.2.1"}'` downloads the same packages straight from api.wally.run.

## Rules

- **Before any UI work, read `docs/roblox-ui-guide.md`** and follow its checklist.
- **After UI work, add what you learned** to the guide's "Lessons log" (newest first, dated).
- No repeated literals: `Theme` for UI values, `Config` for game values, `Remotes.Events` / `Remotes.Functions` for remote names.
- Type-check before committing: `rojo sourcemap default.project.json -o sourcemap.json` then `luau-lsp analyze --platform=roblox --definitions=globalTypes.d.luau --sourcemap=sourcemap.json --ignore "Packages/**" src` (definitions from the luau-lsp repo's `scripts/globalTypes.d.luau`).
- Never commit secrets: the Roblox API key lives in `.env`, which is git-ignored.
