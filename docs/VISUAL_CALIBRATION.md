# v0.10 Mobile Visual Calibration

This document freezes the first phone-oriented calibration pass.

## Actor scale

The vertical-slice actor master remains 96×128 source art.

Runtime display scale:

- normal walk / idle: 0.78
- eating pose: 0.80 × 0.64

This supersedes the smaller 0.65 runtime scale used in v0.7-v0.9.

Reason: the smaller version was technically valid but too small relative to a 720-wide phone canvas for reliable crowd readability.

## Furniture ratio

Furniture source scale remains:

- double table: 0.82
- buffet station: 0.82
- cashier: 0.90
- kitchen counter: 0.90
- restroom entrance: 0.86

These already match the locked 64×32 angled-grid target closely, so v0.10 does not enlarge them.

## Food-station interaction geometry

Customer service point:

- from (-132, 0)
- to (-128, 58)

This intentionally moves customers to the front side of the buffet furniture so their foot Y is greater than the station base Y. The existing Y-based z-order therefore renders the customer in front of the station during food pickup.

Chef refill point:

- from (0, -120)
- to (0, -100)

The chef still approaches from the rear side.

Food queue spacing:

- from 46
- to 54 logical pixels

This reduces crowd overlap on a phone screen.

## Tables

Double-table seat geometry remains:

- upper seat: y -92
- lower seat: y +92

This deliberately produces two different occlusion relationships:

- upper seated customer renders behind the table
- lower seated customer renders in front

That is the intended 3/4-view reading.

## Touch targets

All bottom control buttons are now configured at runtime with:

- minimum height: 52 logical pixels
- font size: 14
- keyboard focus disabled for phone play

Bottom control rows are compressed from the old 218px footprint to approximately 176px plus safe-area inset.

## Top information panel

The top panel height is no longer a hard-coded 260px.

It now uses its actual combined minimum height and clamps between:

- 220px minimum
- 258px maximum

This prevents both unnecessary blank space and text clipping.

## What still requires a real Android screenshot

CI can validate layout rules, scene boot, code and resource references. It cannot judge visual taste.

The remaining phone-only checks are:

1. whether 0.78 actor scale feels too large or too small
2. whether upper/lower table occlusion looks natural with the final sprite silhouettes
3. whether three horizontal buffet queues remain legible at peak load
4. whether the top information panel feels too dense
5. whether bottom controls are comfortable for thumb use
6. whether very tall devices need a small camera composition offset

These are visual tuning items only. They should not trigger another rewrite of the simulation architecture.
