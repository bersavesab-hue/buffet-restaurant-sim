# v0.12.3 Build Mode Prototype

## Goal

The purpose of this milestone is to prove that the Stage 0 restaurant can be edited by the player instead of editing main.tscn.

It intentionally starts with moving existing furniture before adding a full furniture shop/catalog.

## Entering build mode

The normal operation bar contains a 装修 button.

Entering build mode:

- pauses SceneTree
- hides normal supply / priority / environment controls
- shows the build panel
- enables RestaurantGrid overlay
- enables RestaurantCamera pan / pinch zoom
- leaves rendering and build-mode input active through PROCESS_MODE_ALWAYS

Godot 4.7 pause/process-mode behavior is used directly; the simulation is not faked with tiny time scales.

## Selecting furniture

Touch/click is converted from viewport coordinates back to world coordinates through the viewport canvas transform.

The world position is converted to a RestaurantGrid cell.

FurniturePlacementManager.get_entity_at(cell) returns the authoritative furniture entity occupying that cell.

No extra Area2D click target is required per furniture type.

## Moving

Selecting furniture stores:

- current entity
- preview grid anchor
- preview rotation

The real furniture does not move during drag.

BuildPlacementPreview draws the proposed occupied cells:

- green = valid
- red = invalid

Confirm calls FurniturePlacementManager.place().
Cancel only clears the preview.

This makes cancel behavior deterministic and avoids temporarily breaking service points or collision nodes.

## Runtime safety

Furniture currently in use cannot be moved.

Blocked examples:

- occupied table
- dirty table awaiting cleaning
- food station with customer queue
- station claimed by kitchen refill
- active cashier queue/service
- active restroom queue/service
- kitchen while chef refill job is claimed

This prevents build mode from invalidating customer/worker references.

## Removal

Prototype removal is intentionally conservative.

Allowed:

- empty BuffetTable
- idle FoodStation
- only when there are no active customers in the restaurant

Not removable yet:

- cashier
- kitchen facility
- restroom

There is no money refund yet. The button is currently “移除”, not the final “出售”.

Formal selling belongs to the upcoming furniture catalog/economy integration.

## Rotation

The placement layer already rotates footprints.

Current vertical-slice furniture has only one art orientation, so rotation primarily validates grid occupancy in this milestone.

Formal directional furniture art must be supplied before rotation is treated as final visual quality.

## Camera

When no furniture is selected:

- drag pans the restaurant
- pinch zooms on touch devices
- mouse drag/wheel remains available for desktop testing

When furniture is selected, camera navigation is temporarily disabled so drag gestures control the placement preview instead.

## Automated acceptance

CI now verifies build-mode lifecycle by loading the real main scene and checking:

- entering build mode pauses SceneTree
- build panel becomes visible
- build grid becomes visible
- camera navigation becomes enabled
- exiting restores pause state
- panel/grid hide
- camera navigation disables

Existing tests still validate:

- mobile layout
- 44×36 world
- five expansion stages
- furniture overlap/rotation/locked land
- main scene runtime self-check
