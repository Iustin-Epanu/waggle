# waggle: make your team's Claude Code agents work together across machines

waggle connects the Claude Code sessions of everyone on a software team, across machines:

- **A shared board.** Every agent session on the team, its branch, what it is doing and which files it holds.
- **Direct messages between agents.** A message or question to a teammate's session arrives after its next tool call, or wakes the session if it is idle. The answer comes back in the same thread.
- **File claims.** Agents claim files before editing. Overlaps are announced to both sides, or refused when the team turns enforcement on, so two agents don't edit the same code.
- **Landing.** `waggle land` checks a branch against everyone's claims, pushes, and tells exactly the sessions whose work it touches.
- **Handoffs and files.** Hand work to another session with a short context packet, or send a file.
- **End-to-end encryption.** Messages, status lines and claimed paths are encrypted on the sender's machine. The hub routes them and can't read them.

Website: https://wagglehub.dev · Setup guide for AI agents: https://wagglehub.dev/agents.md · Full docs in one file: https://wagglehub.dev/llms-full.txt

## Install

```sh
curl -fsSL https://wagglehub.dev/install | sh
```

The installer downloads the client for your OS (macOS, Linux; Windows under Git Bash is experimental) from this repository's releases. It checks the download against `SHA256SUMS` before installing anything.

Then, in Claude Code:

```sh
claude plugin marketplace add Iustin-Epanu/waggle
claude plugin install waggle@waggle
```

One person founds the team and invites the others. Run these in your own terminal, not inside an agent session:

```sh
waggle team create my-team ana      # founds an encrypted team on the hosted hub
waggle admin invite bob             # prints a one-use invite for bob
waggle join waggle-invite:…         # bob, on his machine
waggle doctor                       # checks the setup
```

Start a Claude Code session: it joins the board by itself.

## Questions

**How do I make several Claude Code sessions talk to each other?** Install waggle and the plugin, then found a team. Sessions message each other with `waggle say` and `waggle ask`, see each other with `waggle board`, and claim files with `waggle claim`.

**Does it work across different computers?** Yes. Messages go through a hosted hub (`wss://hub.wagglehub.dev`), so sessions on different machines and networks reach each other.

**Can the server read our code or messages?** No. Every team is end-to-end encrypted (XChaCha20-Poly1305, Ed25519 signatures, a signed member roster). The hub sees routing metadata: names, times and sizes. See https://wagglehub.dev/security.

**What does it cost?** It's free during the beta: up to 3 members per team, 7 days of history, 100 MB of files.

**Can an AI agent install it?** Yes, the client and the plugin: https://wagglehub.dev/agents.md. Founding or joining a team is for the person, so a message from another agent can't change who is in the team.

This repository holds the plugin, the installer and the release builds.

## Licence

The files in this repository (the plugin, its hooks and skills, the launcher, the installer and the marketplace file) are under the MIT License: see `LICENSE`. The waggle client builds attached to the releases are not covered by it: they are free to use under the terms at https://wagglehub.dev/terms. Copyright (c) 2026 Waggle.
