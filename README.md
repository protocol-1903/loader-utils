[![ko-fi](https://img.shields.io/badge/Ko--fi-Donate%20-hotpink?logo=kofi&logoColor=white&style=for-the-badge)](https://ko-fi.com/protocol1903) [![](https://img.shields.io/badge/dynamic/json?color=orange&label=Factorio&query=downloads_count&suffix=%20downloads&url=https%3A%2F%2Fmods.factorio.com%2Fapi%2Fmods%2Floader-utils&style=for-the-badge)](https://mods.factorio.com/mod/loader-utils) [![](https://img.shields.io/badge/Discord-Community-blue?style=for-the-badge)](https://discord.gg/K3fXMGVc4z) [![](https://img.shields.io/badge/Github-Source-green?style=for-the-badge)](https://github.com/protocol-1903/loader-utils)

This mod is the culmination of efforts to combine and streamline [Lane Filtered Loaders](https://mods.factorio.com/mod/lane-filtered-loaders), [Loaders make full stacks](https://mods.factorio.com/mod/loaders-make-full-stacks), and [Stacking Loaders](https://mods.factorio.com/mod/stacking-loaders). This replaces those mods in a much more streamlined form.

# Modes
Stacking is not enabled by default. Since I can't have it enabled via a mod setting (engine limitation) it requires some other mod such as [Enable all feature flags](https://mods.factorio.com/mod/enable-all-feature-flags) or [Stack inserters](https://mods.factorio.com/stack-inserters) to turn it on. If that flag is found, then it also checks for technologies to increase the belt stack size. If those are not found it errors, requiring another mod to add them. For that I recommend [Stack inserters](https://mods.factorio.com/stack-inserters), but other mods may suffice. If the flag and technologies are found then stacking is enabled, loaders can stack outputs, and the full stacks only option is enabled. Full stacks only means that the loader will only output enough items to make a full stack as defined by the stack size. This can deadlock machines that produce single-stack items (asteroids, armor, etc) so use at your own risk.

Lane filtering is always available, and enabled as the default setting for loaders. Lane filtering restricts the number of filters a loader has to 2, which allows it to filter the left and right lanes independently.

Respect machine limits is always available, and disabled as the default setting for loaders. Respect machine limits forces loaders to operate like inserters do, where they only insert a small number of items into crafting machines before stopping instead of inserting up to the item cap.

# Compatibility
These changes are done to all loaders in the game (with some exceptions noted below). This mod does not add any loaders for the player to use, a mod like [AAI Loaders](https://mods.factorio.com/mod/aai-loaders) must be used to add them. This process is automatic, meaning it should be compatible with mods, but also means it has the chance to break. Let me know if any issues crop up, or if you have any features you wish to be added.

Known compatibility:
- [AAI Loaders](https://mods.factorio.com/mod/aai-loaders)
- [Krastorio 2](https://mods.factorio.com/mod/Krastorio2)
- [Deadlock's Stacking Beltboxes & Compact Loaders](https://mods.factorio.com/mod/deadlock-beltboxes-loaders)
- [Infinite Belt Stacking](https://mods.factorio.com/mod/infinite-belt-stacking)

Exceptions:
- [Editor Extensions](https://mods.factorio.com/mod/EditorExtensions) infinity loader, it's a scripted entity that has issues with being messed with

# History
Original idea requested by Sunrosa on Discord. Expanded via 2.0.14 with LoaderPrototype::per_lane_filters, 2.0.35 with LoaderPrototype::adjustable_belt_stack_size, 2.0.56 with LoaderPrototype::wait_for_full_stack, and 2.0.65 with LoaderPrototype::respect_insert_limits.
[Stacking Loaders](https://mods.factorio.com/mod/stacking-loaders)
[Lane Filtered Loaders](https://mods.factorio.com/mod/lane-filtered-loaders)
[Loaders make full stacks](https://mods.factorio.com/mod/loaders-make-full-stacks)

If you have a mod idea, let me know and I can look into it.