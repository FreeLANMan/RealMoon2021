Minetest vacuum
======

Vacuum implementation and blocks for pumping and detection of vacuum and air

* Github: [https://github.com/thomasrudin-mt/vacuum](https://github.com/thomasrudin-mt/vacuum)
* Forum topic: [https://forum.minetest.net/viewtopic.php?f=9&t=20195](https://forum.minetest.net/viewtopic.php?f=9&t=20195)

# Operation

The space/vacuum starts at 1000 blocks in the y axis (hardcoded in init.lua)

The mod defines an airlike **vacuum:vacuum** block which suffocates the player (with drowning=1).
A [spacesuit](https://github.com/mt-mods/spacesuit) or similar would help to survive in space.

Air can be pumped in to any closed structure with an airpump (vacuum:airpump).
the airpump needs air-bottles to work in vaccum. Air-bottles can be filled with an airpump on the ground.
Just place empty steel bottles in an airpump on the ground, enable it and it produces an airbottle every few seconds.

## Vacuum propagation

The vacuum sucks air out of every structure if there are leaky nodes (doors, wool, wood, etc; defined in abm.lua)

A vacuum node in a pressurized area can suck out the whole structure.

## Other nodes in space

Vacuum exposure on nodes:
* Dirt converts to gravel
* All plants convert to dry shrubs
* Leaves disappear
* Water evaporates
* Torches and ladders drop (to prevent air bubbles/cheating)

# Compatibility

Optional dependencies:
* Mesecon interaction (enable/disable airpump)
* Digilines
* Pipeworks
* Spacesuit

Tested mods:
* digtron
* technic (quarry, solar)

# Digilines

The airpump can be operated with the `digilines` mod:

```lua
-- flush room
digiline_send("airpump", { command="flush" })

-- enable pump
digiline_send("airpump", { command="enable" })

-- disable pump
digiline_send("airpump", { command="disable" })
```

# Contributors

* @Coil0 (various fixes)

# Settings

* `vacuum.disable_physics` if set, disables all abm-physics
* `vacuum.disable_mapgen` if set, disables the vacuum mapgen
* `vacuum.debug` enable debug mode (cobblestone gets placed on leaks)

# Attributions
* textures/vacuum_airpump* by ManElevation MIT (https://github.com/ManElevation/oxygenerators5.2)
