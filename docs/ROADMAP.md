# Roadmap

## Implemented in 0.2.0

- Independent addon namespace and saved settings with normalization.
- Separate world-map/minimap category filters and pin sizes.
- Pure pin filtering for completed quests, low-level and repeatable quests.
- Lua 5.1 automated tests and contributor documentation.
- World-map/minimap overlays, clustering, coordinate projection and pin tooltips.
- MIT start records for 3,983 quests and native active-quest POI provider.
- Korean/English settings, controller buttons/left stick and paged pin list.
- Optional key binding and Q buttons for controller-cursor access.
- Bounded diagnostics and deterministic release packaging.

## Further coverage work

- Validate Forever APIs against the actual client and record supported builds.
- Extend objective coverage beyond representative native POIs only with verified, redistributable coordinates.
- Improve reputation, inventory and event availability when reliable APIs/data are available.
- Add inset-submap rendering and noncircular minimap skins if needed.

## Client validation still required

- Validate native controller-cursor access and optional binding assignment.
- Verify button events and stick orientation on Xbox/PlayStation-style controllers.
- Confirm game input resumes after settings close; test dialogue, combat and map transitions.

## Release gate

- Verify behavior on the actual Forever client, including NPC dialogue taint reproduction.
- Confirm the supported coordinate coverage and document known omissions.
- Verify the packaged runtime files and licenses. No research archives or development dependencies.
- Add original project artwork and English/Korean installation instructions.
- Configure a real external donation destination only once supplied by the maintainer.
- Publish a tested alpha to CurseForge; this initial repository is not that release.

All features remain free. No in-game donation solicitation or paid feature tiers.
