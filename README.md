# chilllixub-minime
Fivem script to spawn mini version of their ped character and can be attached to character bone.
# QB-Core Mini Character Ped Spawner

This script allows you to spawn mini versions of your player character with all their appearance data (clothes, face features, etc.) that can be resized and attached to player bones.

## Features

- ✅ Spawns player character peds with exact appearance
- ✅ Copies all clothing, face features, hair, makeup, etc.
- ✅ Resizable/scalable (0.1x to 2.0x)
- ✅ Attachable to any player bone (head, shoulder, etc.)
- ✅ Compatible with qb-clothing, illenium-appearance, and fivem-appearance
- ✅ Full control via commands and exports

## Installation

1. Place the folder in your `resources` directory
2. Add `ensure minime-spawner` to your `server.cfg`
3. Restart your server

## Commands

### `/spawnminime [scale] [boneIndex] [zOffset]`
Spawns a mini version of your character

**Examples:**
```plaintext
/spawnminime 0.3                    -- Spawns 30% size on head
/spawnminime 0.5 24818 0.4         -- Spawns 50% size on head with 0.4 offset
```

### `/spawnminime_shoulder [scale]`
Spawns a mini-me on your right shoulder

**Example:**
```plaintext
/spawnminime_shoulder 0.3
```

### `/scaleminime [pedId] [scale]`
Changes the scale of a spawned ped

**Example:**
```plaintext
/scaleminime 1 0.5                 -- Sets ped #1 to 50% size
```

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

## Using in Other Scripts

The script exports functions you can use:

```lua
-- Spawn a mini ped
local pedId = exports['minime-spawner']:SpawnMiniPed(0.3, 24818, vector3(0.0, 0.0, 0.3))

-- Update scale
exports['minime-spawner']:UpdatePedScale(pedId, 0.5)

-- Update attachment
exports['minime-spawner']:UpdatePedAttachment(pedId, 64729, vector3(0.15, 0.0, 0.0))

-- Delete specific ped
exports['minime-spawner']:DeleteMiniPed(pedId)

-- Delete all peds
exports['minime-spawner']:DeleteAllMiniPeds()
```

## Configuration

Edit the `Config` table in `client/main.lua`:

```lua
local Config = {
    DefaultScale = 1.0,   -- Default scale when not specified
    MinScale = 0.1,       -- Minimum allowed scale
    MaxScale = 2.0        -- Maximum allowed scale
}
```

## Troubleshooting

- **Ped appears without clothes**: Make sure your appearance system is properly configured
- **Ped not attaching**: Check that the bone index is valid
- **Ped appears in weird position**: Adjust the offset values

## Credits

Created for QB-Core Framework
