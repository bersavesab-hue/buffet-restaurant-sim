# Restaurant World & Expansion Foundation

This document freezes the long-term restaurant world size before the build/decor system is implemented.

## Final world

Logical build grid:

- 44 columns
- 36 rows
- isometric cell footprint: 64×32 logical pixels
- one persistent restaurant world
- no scene switching between expansion tiers

The player only sees and can build inside the currently unlocked region.

## Expansion stages

### Stage 0 — 街角小店
- 18×18 unlocked cells
- Rect2i(13, 9, 18, 18)
- intended for the starting buffet

### Stage 1 — 扩建餐厅
- 24×22
- Rect2i(10, 7, 24, 22)

### Stage 2 — 中型自助
- 30×26
- Rect2i(7, 5, 30, 26)

### Stage 3 — 大型综合自助
- 36×30
- Rect2i(4, 3, 36, 30)

### Stage 4 — 旗舰自助餐厅
- 44×36
- Rect2i(0, 0, 44, 36)
- final full buildable footprint

Each stage contains the previous one. Expansion therefore reveals additional buildable cells without moving the existing restaurant to another scene.

## Coordinate system

RestaurantGrid owns all grid/world conversion:

- grid_to_world(cell)
- world_to_grid(position)
- snap_world_to_grid(position)
- is_cell_unlocked(cell)
- get_unlocked_world_bounds()
- get_full_world_bounds()

Future furniture placement must use these methods rather than duplicating isometric coordinate math.

## Camera

RestaurantCamera supports:

- one-finger/mouse drag
- two-finger pinch zoom
- mouse-wheel zoom for desktop testing
- zoom limits
- clamp to the current unlocked restaurant region
- expansion-stage bound updates

The controller is attached now but navigation_enabled is false while the current v0.12.1 handcrafted layout is still being migrated to the build grid.

This prevents the user from panning into unfinished blank expansion space during the current prototype.

When grid migration is complete, the same controller will be enabled instead of introducing a second camera implementation.

## Current scene migration rule

The existing small restaurant is treated as the Stage 0 authored prototype.

Do not immediately delete its current positions.

Migration order later:

1. establish PlaceableEntity
2. define furniture footprints
3. assign grid cells to the existing tables/stations/equipment
4. generate furniture world positions from RestaurantGrid
5. rebuild navigation from placed furniture
6. enable RestaurantCamera navigation
7. remove remaining hard-coded furniture coordinates

No duplicate furniture system should remain after migration.

## Navigation

Current NavigationRegion2D still covers the existing prototype floor.

It is intentionally not expanded to the full 44×36 world yet.

Dynamic navigation rebuilding belongs to the build-mode phase, because navigation must reflect the player’s actual furniture layout, not simply the maximum purchased land.

## Rendering layers

Long-term world hierarchy:

RestaurantWorld
- floor layer
- wall layer
- back decoration layer
- furniture layer
- actor layer
- effects
- build grid / interaction layer

Godot 4.7 provides TileMapLayer for tile-based 2D map layers; floor/wall authoring can migrate to TileMapLayer when the build editor is introduced, while furniture remains scene-based entities.

## Acceptance tests

CI verifies:

- final size is exactly 44×36
- there are exactly five expansion stages
- Stage 0 is 18×18
- final stage unlocks the whole world
- every stage contains the previous stage
- grid→world→grid conversion round-trips
- locked cells remain locked in Stage 0
- corner cells unlock in Stage 4
- final world spans far beyond one phone screen
