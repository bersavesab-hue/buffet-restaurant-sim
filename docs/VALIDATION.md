# v0.8 Validation & Stability

v0.8 freezes feature expansion temporarily and validates the v0.7 vertical slice.

## Automated GitHub validation

Workflow:

.github/workflows/godot-validate.yml

The workflow pins Godot 4.7.2 stable and performs:

1. Repository checkout.
2. Godot resource import in headless mode.
3. Main scene smoke run.
4. Startup self-test confirmation.
5. Parse/runtime error scan.
6. Validation log upload.

The workflow uses concurrency so new main-branch commits cancel obsolete validation runs.

## In-game diagnostics

Runtime node:

scripts/runtime_diagnostics.gd

The main scene now displays a diagnostics line.

Normal:

诊断：OK｜FPS 60

Possible warnings include:

- 顾客疑似卡住
- 收银队列持续
- 取餐队列持续
- 等座队列持续
- 厕所队列持续

These warnings are diagnostic signals, not automatic gameplay fixes. A long queue can be legitimate under heavy load, so it should be interpreted together with the restaurant state.

## Startup self-check

The game verifies that the following exist before declaring the slice healthy:

- CustomerLayer
- FoodStations
- Tables
- Kitchen
- Pantry
- ServiceWorker
- ChefWorker
- Entrance / Exit
- Core vertical-slice scenes
- Core floor/table/station visual assets
- At least 3 food stations
- At least 3 tables

A structural failure emits a Godot error and causes CI to fail.

## Manual phone validation

When running on Android, verify:

- no startup error
- diagnostics shows OK
- customer path completes
- no furniture penetration
- food-station queues advance
- two customers can share a double table
- last customer leaving dirties the table
- waiter collects and cleans it
- chef completes a refill trip
- 1× / 2× / 3× remain stable
- visual depth and character scale remain readable

If a warning appears, capture one screenshot while the warning is visible. The on-screen label should identify the subsystem first, reducing guesswork.
