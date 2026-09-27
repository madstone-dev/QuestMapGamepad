# Contributing

Issues and pull requests are welcome in Korean or English. The repository is maintained
by madstone-dev; contributors do not need to join a GitHub organization.

- Discuss substantial changes in an issue first. Use a topic branch (for example `codex/map-pins`).
- Submit only code/data you have the right to contribute. New original code uses MIT.
- Identify external sources and licenses in THIRD_PARTY_NOTICES.md before importing them.
- Run the tests and describe how the change was checked in-game when applicable.
- Do not attach account files, tokens or unredacted logs with personal information.
- Keep quest interaction and protected gamepad actions in Blizzard's native UI.

Automated tests do not establish absence of UI taint. A release needs in-game checks for
NPC dialogue, entering/leaving combat, map transitions, controller focus and closing settings.
