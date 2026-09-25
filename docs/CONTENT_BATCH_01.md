# v0.11 Content Batch 01

This batch is the first controlled content expansion after the vertical slice and phone calibration.

## Customer appearances

The game still uses one reusable customer scene.

Runtime customer appearance is selected from CustomerAppearanceLibrary:

1. base blue-gray
2. green
3. red
4. yellow
5. purple

Each appearance supplies:

- front walk frame 1
- front walk frame 2
- back walk frame 1
- back walk frame 2

Left/right directions continue to use mirrored frames.

Adding another appearance should only require:

1. four matching textures
2. one entry in CustomerAppearanceLibrary

Do not duplicate customer scenes or customer behavior scripts.

## Buffet-station appearances

The three current categories now have distinct furniture visuals:

- staple station
- meat/grill station
- seafood/ice station

All three continue using the same FoodStation script and interaction interface.

## First dish visuals

Staple:
- fried rice
- noodles

Meat:
- roast beef
- roast chicken

Seafood:
- shrimp
- crab

Dish sprites are separate from station furniture so future menu swaps do not require replacing the station itself.

## Stock-linked display

FoodStation controls the visibility of DishA and DishB.

As station stock drops:

- dish opacity decreases
- an empty station hides the visible food
- refilling restores the display automatically

This is visual feedback only; the existing stock/economy simulation remains authoritative.

## Content rule

Future batches must keep these layers separate:

customer behavior != customer appearance
food station logic != station furniture appearance
dish simulation data != dish display texture

This prevents content growth from duplicating gameplay code.
