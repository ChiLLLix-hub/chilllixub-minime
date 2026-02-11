# chilllixub-minime
Fivem script to spawn mini version of their ped character and can be attached to character bone.
# QB-Core Mini Character Ped Spawner

This script allows you to spawn mini versions of your player character with all their appearance data (clothes, face features, etc.) that can be resized and attached to player bones.

## Features

- ✅ Spawns player character peds with exact appearance
- ✅ Copies all clothing, face features, hair, makeup, etc.
- ✅ Resizable/scalable (0.1x to 2.0x)
- ✅ Attachable to any player bone (head, shoulder, etc.)
- ✅ Configurable animations and emotes (sitchair, salute, wave, dance, etc.)
- ✅ Compatible with qb-clothing, illenium-appearance, and fivem-appearance
- ✅ Full control via commands and exports

## Installation

1. Place the folder in your `resources` directory
2. Add `ensure minime-spawner` to your `server.cfg`
3. Restart your server

## Commands

### `/spawnminime [scale] [boneIndex] [zOffset] [animKey]`
Spawns a mini version of your character

**Examples:**
```plaintext
/spawnminime 0.3                    -- Spawns 30% size on head
/spawnminime 0.5 24818 0.4         -- Spawns 50% size on head with 0.4 offset
/spawnminime 0.3 24818 0.3 salute  -- Spawns with salute animation
/spawnminime 0.2 24818 0.3 sitchair -- Spawns with sitting animation
```

### `/spawnminime_shoulder [scale] [animKey]`
Spawns a mini-me on your right shoulder

**Example:**
```plaintext
/spawnminime_shoulder 0.3
/spawnminime_shoulder 0.3 wave     -- Spawns with wave animation
```

### `/scaleminime [pedId] [scale]`
Changes the scale of a spawned ped

**Example:**
```plaintext
/scaleminime 1 0.5                 -- Sets ped #1 to 50% size
```

### `/animminime [pedId] [animKey]`
Sets or changes the animation/emote of a spawned mini-ped

**Examples:**
```plaintext
/animminime 1 salute              -- Applies salute animation to ped #1
/animminime 1 sitchair            -- Applies sit chair animation to ped #1
/animminime 1                     -- Clears animation from ped #1
```

### `/listanims`
Lists all available animations

### `/deleteminime [pedId]`
Deletes a specific spawned ped

**Example:**
```plaintext
/deleteminime 1
```

### `/deleteallminime`
Deletes all spawned mini-peds

## Common Bone Indexes

- **24818** - Head (IK_Head)
- **64729** - Right Shoulder (SKEL_R_Clavicle)
- **10706** - Left Shoulder (SKEL_L_Clavicle)
- **31086** - Right Hand (SKEL_R_Hand)
- **60309** - Left Hand (SKEL_L_Hand)
- **11816** - Pelvis/Hip (SKEL_Pelvis)

## Available Animations

The script includes several predefined animations/emotes:

- **sitchair** - Sitting on a chair
- **sitchair2** - Sitting on ground (picnic style)
- **salute** - Military salute
- **wave** - Friendly wave
- **dance** - Dance animation
- **smoke** - Smoking
- **guard** - Guard stance

Use `/listanims` command to see all available animations in-game.

## Using in Other Scripts

The script exports functions you can use:

```lua
-- Spawn a mini ped
local pedId = exports['minime-spawner']:SpawnMiniPed(0.3, 24818, vector3(0.0, 0.0, 0.3))

-- Spawn with animation
local pedId = exports['minime-spawner']:SpawnMiniPed(0.3, 24818, vector3(0.0, 0.0, 0.3), 'salute')

-- Update scale
exports['minime-spawner']:UpdatePedScale(pedId, 0.5)

-- Update attachment
exports['minime-spawner']:UpdatePedAttachment(pedId, 64729, vector3(0.15, 0.0, 0.0))

-- Update animation
exports['minime-spawner']:UpdatePedAnimation(pedId, 'sitchair')

-- Clear animation
exports['minime-spawner']:UpdatePedAnimation(pedId, nil)

-- Delete specific ped
exports['minime-spawner']:DeleteMiniPed(pedId)

-- Delete all peds
exports['minime-spawner']:DeleteAllMiniPeds()
```

## Configuration

Edit the `Config` table in `client.lua`:

```lua
local Config = {
    DefaultScale = 1.0,   -- Default scale when not specified
    MinScale = 0.1,       -- Minimum allowed scale
    MaxScale = 2.0,       -- Maximum allowed scale
    -- Animations can be customized here
    Animations = {
        sitchair = {type = "scenario", name = "PROP_HUMAN_SEAT_CHAIR"},
        salute = {type = "anim", dict = "mp_player_int_uppersalute", anim = "mp_player_int_salute", flags = 49},
        -- Add more animations as needed
    }
}
```

## Troubleshooting

- **Ped appears without clothes**: Make sure your appearance system is properly configured
- **Ped not attaching**: Check that the bone index is valid
- **Ped appears in weird position**: Adjust the offset values

## Credits

Created for QB-Core Framework
