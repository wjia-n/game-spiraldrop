# Spiral Drop

Spin the tower. Thread the gaps. Go FIREBALL. 🌀

A pseudo-3D arcade dropper by Wajiha: drag to rotate the wooden tower, drop
the ball through gaps, dodge red danger zones, and chain 3+ clean falls to
become a fireball that smashes everything.

- **Modes:** Classic (level progression) and Endless (score attack).
- **Difficulties:** Chill, Classic, Turbo, Inferno (Pro).
- **Customization:** 12 physical-material tower themes, 8 ball styles, and a
  custom tower + ball workshop (Pro).
- **Engine-owned state machine** with watchdog: stuck states impossible by
  construction.
- Synthesized audio (no assets): menu + gameplay music, full SFX, toggles,
  volume, lifecycle pause/resume, splash prewarm.
- Real Play Billing: `spiraldroppro` (Pro unlock), `spiraldropcoffee`,
  `spiraldropchocolate` (tips), with Free-vs-Pro screen and restore.
- Share + in-app review prompts.

## Run

```bash
flutter pub get
flutter run
```

## Test

```bash
flutter test
```

See `RULES.md` for the authoritative gameplay rules.
