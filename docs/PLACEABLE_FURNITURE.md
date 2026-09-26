# Placeable Furniture Foundation

This document defines the furniture architecture used by future build/decor mode.

## Core classes

### FurnitureDefinition

A data-only Resource.

Fields:

- item_id
- display_name
- category
- footprint
- build_cost
- required_stage
- allow_rotation
- comfort
- tags

Godot Resources are used because they can be exported, saved independently and reused by multiple scene instances.

### PlaceableEntity

Base Node2D for placeable furniture.

Responsibilities:

- hold FurnitureDefinition
- know its grid anchor
- know its rotation
- calculate occupied cells
- validate against unlocked land
- convert grid coordinates to world coordinates
- move its whole child hierarchy together

Interaction points such as SeatPoint, ServicePoint, RefillPoint and CleanPoint remain children of the furniture scene, so they automatically follow the entity when it moves.

### FurniturePlacementManager

Owns occupancy.

Responsibilities:

- reject overlap
- reserve occupied cells
- move already placed furniture
- release old cells
- remove furniture
- query the entity occupying a cell

It does not contain table, food-station or customer-specific logic.

## First migrated objects

Current v0.12.1 restaurant now attaches furniture definitions to:

- TableA
- TableB
- TableC
- StapleStation
- MeatStation
- SeafoodStation

BuffetTable and FoodStation now inherit PlaceableEntity.

Their gameplay behavior remains unchanged.

Current hard-coded world positions are intentionally preserved for this migration step by keeping use_grid_placement=false.

## Initial furniture data

### Wooden double table

- id: table_double_wood
- footprint: 2×2
- category: table
- stage: 0
- rotation: allowed

### Basic staple station

- id: station_staple_basic
- footprint: 3×2
- category: food station
- stage: 0

### Basic meat station

- id: station_meat_basic
- footprint: 3×2
- category: food station
- stage: 0

### Basic seafood station

- id: station_seafood_basic
- footprint: 3×2
- category: food station
- stage: 0

Numbers such as build cost are first-pass balance data and can change without changing the furniture architecture.

## Next migration batch

Next objects to migrate:

1. cashier
2. kitchen workstation
3. restroom
4. decoration entities
5. floor/wall editing

After all functional furniture is placeable:

1. assign Stage 0 grid cells to the current restaurant
2. enable use_grid_placement
3. delete remaining hand-authored furniture positions
4. rebuild navigation from actual furniture occupancy
5. enable RestaurantCamera drag/pinch
6. add build-mode UI

## CI guarantees

Automated tests verify:

- FurnitureDefinition validation
- rotated footprint swapping
- grid snapping
- occupied-cell count
- overlap rejection
- moving an entity releases old cells
- locked expansion land rejects placement
- final expansion permits placement
- removing furniture releases cells

Runtime startup also verifies that current tables and food stations are placeable and have FurnitureDefinition data.
