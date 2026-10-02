# Security Policy

## Reporting a vulnerability

Report security issues through GitHub Security Advisories when available. If
they are unavailable, open an issue requesting private follow-up. Do not post
sensitive data or an exploit affecting other users.

## Security model

Omarchy plugins run unsandboxed inside `omarchy-shell`. This plugin's service
entry point is a marker for Omarchy's plugin lifecycle. Its Hyprland Lua loader
reads `shell.json`, registers a keybinding and a window-open callback, and
dispatches window moves. It saves the toggle state under the user's
`XDG_STATE_HOME` (or `~/.local/state`) for the bar indicator. It makes no
network requests, installs no packages, and uses no privilege escalation.
