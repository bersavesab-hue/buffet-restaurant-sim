# Buffet Restaurant Sim — Master Production Plan

This plan defines the production order from the current playable prototype to a releasable 1.0 game.

The rule is simple: every phase must produce a playable result and pass its acceptance gate before the next phase expands scope.

---

## Baseline already complete

Current foundation already exists:

- Android debug APK pipeline
- GitHub CI with Godot 4.7.2
- 720×1280 portrait baseline
- mobile safe-area handling
- visible customer / chef / service worker
- cashier queue
- food-station queues
- multi-seat tables
- dirty-table cleaning
- finite pantry stock
- kitchen refill jobs
- temperature / air conditioning
- restroom queue
- fullness / perceived value / patience / comfort
- 5 customer appearances
- 3 station appearances
- first 6 dish visuals

This is the foundation. Do not rebuild it unless runtime evidence shows a real architectural problem.

---

# Phase 1 — v0.12 Restaurant Scene Formation

Goal: opening the game should immediately look like one coherent buffet restaurant, not a developer test room.

### Step 1.1 Compact production HUD

Do:

- keep only business-critical information visible by default
- hide detailed debug values behind one expandable control
- reduce top-panel footprint
- keep runtime diagnostics available without occupying the whole screen

Default visible:

- day/status
- customer/queue summary
- revenue/profit summary
- latest review

Expandable details:

- station stock/cost/value
- pantry
- temperature
- kitchen
- chef
- waiter
- device/safe-area
- runtime diagnostics

Acceptance:

- default top HUD does not dominate the restaurant
- debug data is still one tap away

### Step 1.2 Establish five physical zones

Restaurant must visually read as:

1. entrance / cashier
2. kitchen / staff
3. buffet line
4. dining area
5. restroom

Do:

- add floor-zone treatment
- reserve visible walking lanes
- remove the feeling that furniture is floating randomly in empty space
- keep all existing interaction points and collisions valid

Acceptance:

- first-time viewer can identify the five zones without reading debug text

### Step 1.3 Recompose furniture

Do:

- align buffet stations into one readable service line
- keep kitchen close to refill points
- move tables into a coherent dining cluster
- leave one main customer circulation lane
- keep restroom away from food service traffic

Acceptance:

- no furniture overlap
- no obvious dead corridors
- customer paths remain readable at peak load

### Step 1.4 Scene dressing pass

Add only lightweight first-pass dressing:

- floor material variation
- wall trim / window treatment
- area rugs or tile changes
- simple planters / bins / signs if they do not block paths

Do not add decorative clutter that requires new gameplay logic.

Acceptance:

- screenshot reads as a restaurant rather than a test floor

### Step 1.5 Android verification

Build APK and validate:

- startup
- UI safe area
- character scale
- touch controls
- station queues
- table sharing
- chef refill path
- waiter cleaning path
- restroom path
- FPS

Gate A:
Do not move to menu expansion until this scene works cleanly on the actual phone.

---

# Phase 2 — v0.13 Real Dish & Menu Data

Goal: dishes become gameplay objects, not merely station pictures.

### Step 2.1 Dish data model

Each dish must have:

- id
- name
- category
- purchase ingredients
- raw-to-cooked conversion
- batch size
- cook time
- satiation
- perceived value
- real cost
- popularity
- freshness decay
- unlock condition
- station compatibility

### Step 2.2 Convert first six dishes

Convert:

- fried rice
- noodles
- roast beef
- roast chicken
- shrimp
- crab

from station-level placeholder values into real DishData entries.

### Step 2.3 Menu selection before opening

Player chooses which dishes are served today.

Initial target:

- 2 staple slots
- 2 meat slots
- 2 seafood slots

No new full-screen page unless required; prefer a compact pre-opening overlay.

### Step 2.4 Customer dish choice

Customer selection considers:

- personal preference
- perceived value
- fullness
- repeat penalty
- freshness
- queue length
- availability

Gate B:
Different menu combinations must produce visibly different customer behavior and profit.

---

# Phase 3 — v0.14 Complete Business-Day Loop

Goal: one business day should feel complete from preparation to settlement.

### Step 3.1 Pre-opening phase

Player sets:

- ticket price
- menu
- initial ingredient order
- refill priorities
- AC setting
- staffing assignment

### Step 3.2 Opening phase

Restaurant operates automatically with limited player intervention.

### Step 3.3 Mid-day incidents

Add a small event pool:

- sudden group arrival
- one station empties
- heat spike
- restroom congestion
- staff overload
- temporary ingredient shortage

### Step 3.4 Closing phase

No new customers enter.
Existing customers finish and leave.

### Step 3.5 Settlement

Show:

- customer count
- revenue
- ingredient cost
- electricity
- waste
- gross profit
- average perceived value
- average rating
- bottleneck reasons
- best / worst performing dishes

Gate C:
A full day must have a clear setup → operation → consequence → learning loop.

---

# Phase 4 — v0.15 Staff Operations

Goal: staff become the main operational capacity constraint.

### Step 4.1 Chef stats

- cooking speed
- batch capacity
- category skill
- fatigue later if needed

### Step 4.2 Service worker tasks

Task queue:

- clear plates
- wipe tables
- assist queue
- refill simple supplies

### Step 4.3 Cashier staffing

Cashier capacity becomes staff-driven instead of a fixed service timer.

### Step 4.4 Staff scheduling

Before opening:

- assign chef
- assign cashier
- assign floor service

Avoid deep HR systems yet.

Gate D:
Adding/removing one staff member must create a visible operational difference.

---

# Phase 5 — v0.16 Expansion & Build Mode

Goal: player can grow from a small buffet to a larger restaurant.

### Step 5.1 Grid/build foundation

Use the locked angled grid.

Player can place:

- tables
- buffet stations
- kitchen equipment
- restroom capacity
- decor that has real effects

### Step 5.2 Placement validation

Check:

- occupied grid cells
- walking lanes
- service points
- refill points
- entrance accessibility

### Step 5.3 Expansion plots

Unlock physical floor area in stages rather than exposing a huge empty restaurant on day one.

### Step 5.4 Capacity consequences

Expansion changes:

- rent
- electricity
- cleaning workload
- walking distance
- maximum customer throughput

Gate E:
Expansion must create new operational problems, not only more empty floor space.

---

# Phase 6 — v0.17 Progression & Unlocks

Goal: give the player a long-term reason to keep playing.

Progression tracks:

- restaurant level
- restaurant star rating
- reputation
- cash
- equipment tier
- dish research
- supplier tier

Unlock examples:

- new dish lines
- premium proteins
- desserts / drinks
- larger stations
- better HVAC
- more toilets
- larger restaurant area
- new customer segments

Old dishes should remain relevant through cost/value roles instead of being deleted by higher-level dishes.

Gate F:
After 10–20 business days, player should still have meaningful unlock decisions.

---

# Phase 7 — v0.18 Content Expansion

Only after systems are stable, expand content.

Target first commercial content set:

- 25–35 dishes
- 8–12 customer archetypes
- 12–18 customer appearances
- 3 chef appearances
- 3 service-worker appearances
- 6+ table/furniture variants
- 8+ station/equipment variants
- several restaurant visual tiers

Content must remain data-driven.

Gate G:
Adding one dish or customer archetype should require data/assets, not new gameplay code.

---

# Phase 8 — v0.19 Events, Goals & Retention

Goal: prevent later days from feeling identical.

Add:

- daily goals
- weekly challenge rules
- weather modifiers
- group reservations
- customer trends
- limited-time dish demand
- critic / influencer-style customer event without real-world branding
- operational emergencies

Do not turn the game into random punishment. Events should create decisions.

Gate H:
Three consecutive business days should not play identically.

---

# Phase 9 — v0.20 Save, Tutorial, Audio & Presentation

### Step 9.1 Save system

Persist:

- progression
- unlocks
- restaurant layout
- economy
- staff
- menu research
- settings

Add versioned migrations.

### Step 9.2 Tutorial

Teach through the running restaurant, not long text pages.

### Step 9.3 Audio

Minimum:

- ambience
- footsteps
- plate sounds
- cooking
- cashier
- UI feedback
- success/failure cues

### Step 9.4 UI polish

Replace developer labels with player-facing UI.

Debug panel remains hidden behind developer mode.

Gate I:
A new tester can play without developer explanation.

---

# Phase 10 — v0.21 Balance & Monetization Preparation

First balance the game without ads.

Run simulations for:

- ticket-price ranges
- food cost
- customer capacity
- premium-food consumption
- staff throughput
- rent/electricity
- expansion pacing

Only after the economy works naturally, add optional rewarded-ad opportunities such as:

- emergency procurement
- one-time marketing boost
- temporary production assist

Never force ads to unblock basic progress.

Gate J:
The game must remain playable and economically coherent with ads disabled.

---

# Phase 11 — v0.22 Platform Adaptation

Prepare separate export concerns for:

- Android / TapTap
- WeChat Mini Game
- Douyin Mini Game

Work includes:

- package/export settings
- platform APIs
- storage limits
- performance
- review-sensitive wording
- ad SDK integration
- analytics / crash telemetry if used

Keep platform adapters outside core simulation logic.

---

# Phase 12 — v1.0 Release Candidate

Final checklist:

- no blocking crashes
- no dead queues
- no save corruption
- stable 30/60 FPS target devices
- full progression loop
- first content set complete
- tutorial complete
- economy balanced
- Android installation verified
- platform compliance pass
- release APK / package reproducible from CI

---

# Production discipline

Every phase follows the same order:

1. define behavior
2. implement data/model
3. connect scene
4. connect player controls
5. run CI
6. generate APK
7. test on phone
8. fix runtime/visual issues
9. freeze the phase
10. only then continue

Never:

- duplicate obsolete interfaces
- leave two competing implementations
- batch-generate art before one master is verified
- add new pages just because a new system exists
- hide broken simulation behind UI
- expand content before core loops are stable
