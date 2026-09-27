# Roadmap

## Implemented foundation

- Independent addon namespace and saved settings with normalization.
- Separate world-map/minimap category filters and pin sizes.
- Pure pin filtering for completed quests, low-level and repeatable quests.
- Lua 5.1 automated tests and contributor documentation.

## Next: data and rendering

- Validate Forever APIs against the actual client and record supported builds.
- Define an attributed data provider for start, objective and turn-in coordinates.
- Verify licenses and data coverage before importing any data. Never invent missing coordinates.
- Render/update/recycle world-map pins without modifying native quest interaction frames.
- Add continent-level clustering, coordinate conversion and minimap rendering.
- Add prerequisite/eligibility logic as required by verified data.

## Next: settings and gamepad

- Independent map-adjacent settings entry, category checkboxes and pin sizing.
- Respect native controller mappings and display correct controller prompts.
- Open settings without a mouse; navigate, toggle, resize and close with controller.
- Restore input focus on close; test dialogue, combat and map transitions.

## Release gate

- Verify behavior on the actual Forever client, including NPC dialogue taint reproduction.
- Confirm the supported coordinate coverage and document known omissions.
- Package runtime files plus licenses only. No research archives or development dependencies.
- Add original project artwork and English/Korean installation instructions.
- Configure a real external donation destination only once supplied by the maintainer.
- Publish a tested alpha to CurseForge; this initial repository is not that release.

All features remain free. No in-game donation solicitation or paid feature tiers.
