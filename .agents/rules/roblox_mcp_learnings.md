# Roblox Executor MCP & Windows PowerShell Learnings

## 1. PowerShell Build Invariants
- When building Node.js / Bun projects in Windows PowerShell:
  - Do NOT use `&&` chaining syntax in PowerShell commands (use `;` instead).
  - If `npm install` fails due to missing `bun` in `prepare` scripts, execute `npm install --ignore-scripts`, then build manually with `npx tsc; node scripts/copy-assets.mjs`.

## 2. Roblox Emulator Network Connectivity
- Standard `localhost:16384` connects to the local Windows host.
- For Android Emulators (LDPlayer, BlueStacks, Nox, Android Studio), `localhost` routes inside the VM loopback. Use `10.0.2.2:16384` or the host machine's LAN IP address (`192.168.x.x:16384`) in `BridgeURL` before executing `/script.luau`.
