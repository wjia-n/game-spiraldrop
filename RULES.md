# Spiral Drop — Rules

The authoritative source of truth for Spiral Drop gameplay. The engine must
enforce these rules; if implementation conflicts with this document, fix the
implementation.

## 1. Objective
Guide the ball down the spiral tower by rotating the tower with drag input.
Fall through gaps in the platforms to score. Survive as long as possible:
- **Classic mode:** clear every platform on a level to advance to the next,
  faster level.
- **Endless mode:** fall forever — every platform cleared adds depth and
  score; there is no last level.

## 2. Setup
- A vertical tower of platforms is generated at level start (Classic:
  `min(10 + level*2, 34)` platforms; Endless: 40, extended forever).
- The ball spawns above the first platform.
- A 3-2-1 countdown runs before play begins.
- Player input: horizontal drag rotates the tower (rotation velocity with
  friction).

## 3. Turn order
Real-time game — there are no turns. The engine advances physics every frame
(`SpiralEngine.tick(dt)`), owned entirely by the engine state machine.

## 4. Legal moves
- Drag left/right anywhere on screen to spin the tower.
- Fall through a platform's **gap** (the carved opening) — scores points and
  continues the fall.
- While in **Fireball** state, the ball smashes straight through any
  platform, including red zones.

## 5. Illegal moves
- There are no "moves" to declare illegal; the only losing interaction is
  touching a **red danger zone** while not in Fireball state (instant game
  over).
- Missing a gap simply bounces the ball off the platform (no penalty beyond
  lost momentum and reset fireball progress).

## 6. Captures
N/A — no capturing mechanic.

## 7. Special rules
- **Fireball:** falling through 3+ consecutive platform gaps without bouncing
  ignites Fireball. Fireball smashes platforms (red zones included) for +50
  each and keeps the fall going. Bouncing ends Fireball.
- **Red zones:** sections of platforms painted red. Touching one while not
  in Fireball ends the run immediately.
- **Smash streak:** consecutive smashed platforms while in Fireball count up
  (SMASH x2, x3, …) and shake the screen.
- Difficulty scales with level: gravity and fall speed rise, gaps narrow,
  red zones become more frequent.

## 8. Scoring
- Gap fall-through: +10 (+40 while Fireball).
- Fireball platform smash: +50.
- Level clear bonus (Classic): 100 + 10 × level.
- Bounces score nothing.

## 9. Winning conditions
- Classic: there is no final win — the win is each level cleared and the
  growing score. (Victory fanfare plays on every level clear.)
- Beating your personal best is celebrated with a NEW BEST fanfare.

## 10. Draw conditions
N/A — single-player arcade game.

## 11. AI strategy
N/A — no opponents or bots.

## 12. Edge cases
- Ball exactly on a gap edge: resolved by center-line test — the ball's
  horizontal center must be inside the gap span.
- Drag during countdown/pause/overlays: ignored (engine only accepts input
  in `playing` phase).
- App backgrounded mid-run: the engine watchdog auto-pauses play when
  frames stop arriving; music pauses and resumes via lifecycle hooks.
- Rotation never wraps into an invalid angle: `relAngle` always normalizes
  to [-π, π].

## 13. Test cases
- `spiral_engine_test.dart`:
  1. `start()` → countdown phase, then auto-transitions to playing.
  2. Ticking advances the ball downward (gravity applies).
  3. Drag only affects rotation in `playing` phase.
  4. Red-zone hit while not Fireball → game over.
  5. Three consecutive gap falls → Fireball active.
  6. Fireball survives a red-zone hit (platform smashed instead).
  7. Watchdog re-arms a stalled countdown and auto-pauses stalled play.
  8. `restart()` resets score/level and re-runs countdown.
- `settings_profile_test.dart`:
  1. Profile encodes/decodes as ONE JSON string (roundtrip).
  2. Legacy `spiraldrop_best` / `spiraldrop_best_level` migrate into the
     profile.
  3. Corrupt profile JSON falls back to defaults (never crashes).
  4. No `setStringList` is used for the profile anywhere.
