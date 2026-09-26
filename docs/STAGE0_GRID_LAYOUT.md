# v0.12.2 Stage 0 Grid Layout

This milestone converts the current starting restaurant from authored world positions to actual grid placement.

## Grid

- final world: 44×36
- Stage 0 unlocked region: Rect2i(13, 9, 18, 18)
- cell diamond: 64×32
- world origin: (360, 160)

The origin is intentionally lower than the first prototype value so the Stage 0 restaurant has useful portrait-screen depth without changing the cell geometry.

## Stage 0 functional layout

| Entity | Grid anchor | Footprint |
| --- | --- | --- |
| KitchenFacility | (13,14) | 4×3 |
| StapleStation | (18,10) | 3×2 |
| MeatStation | (20,12) | 3×2 |
| SeafoodStation | (22,14) | 3×2 |
| TableA | (15,17) | 2×2 |
| TableB | (16,20) | 2×2 |
| TableC | (18,22) | 2×2 |
| CashierStation | (17,24) | 3×2 |
| RestroomFacility | (25,22) | 3×3 |

These placements do not overlap and all fit inside Stage 0 unlocked land.

## Runtime registration

Every PlaceableEntity joins the group:

placeable_furniture

FurniturePlacementManager performs a deferred startup registration for entities whose:

use_grid_placement = true

The manager becomes the authoritative source for occupied grid cells.

Current Stage 0 totals:

- 9 registered furniture entities
- 57 occupied cells

The runtime self-check requires these totals before reporting success.

## Legacy position removal

For the nine migrated entities, authored top-level world position and z-index values are removed from main.tscn.

PlaceableEntity calculates:

position = RestaurantGrid.grid_to_world(grid_position)

and derives z-index from the resulting foot position.

Child service markers, collision bodies, navigation obstacles and visuals stay local to the entity and therefore move with it.

## Not migrated yet

The following remain presentation/world fixtures for now:

- floor art
- wall art
- entrance/exit markers
- decorative plants/bin/signs
- table waiting marker
- current NavigationRegion2D

They are intentionally not disguised as buildable furniture.

Next build-mode work will separate buildable decoration/floor/wall layers and later rebuild navigation from actual placed occupancy.
