# Third-party materials

## ATT-derived start database (MIT)

`addon/QuestMapGamepad/Data/Starts.lua` contains 3,983 quest records derived from
[AllTheThings](https://github.com/ATTWoWAddon/AllTheThings), ATT commit
`e93755e1fa7a412fd54aeedfc229e4b06a96d8bf`.

Redistribution source: [Forever Quest Pins Database/ForeverQuests.lua](https://github.com/TylerAkins/forever-quest-markers/blob/24f1c3863488e892a75d7c4a06e19aec9b85e202/Database/ForeverQuests.lua).
Its [explicit attribution](https://github.com/TylerAkins/forever-quest-markers/blob/24f1c3863488e892a75d7c4a06e19aec9b85e202/ATTRIBUTION.md)
identifies these ATT-derived Database records as MIT, separately from the GPL addon implementation.
Copyright (c) 2026 AllTheThings WoW Addon. The complete notice is in
`addon/QuestMapGamepad/Licenses/ATT-MIT.txt` and is included in every release ZIP.

Modification: renamed the namespace field `Quests` to `StartDB` and added provenance comments.
Records are otherwise unchanged. `tools/import_starts.py` pins the source commit and SHA-256.
No GPL implementation, converter, media, or scraped research files are included.

## Development and runtime APIs

Lupa is a development-only Lua runtime installed separately through pip; it is not shipped in the addon.

For future imported data, record the upstream URL, exact version/commit, applicable license,
copyright notice, covered files and transformation steps here. A repository-wide license
must not be assumed to cover third-party source data. Unverified data stays out of releases.

Questie and Forever Quest Pins informed the functional investigation; this repository is
not an official release of either project and does not include their implementation.
The game supplies UI fonts, highlight textures, quest POIs and API behavior at runtime;
these game assets are referenced, not copied into the release.
