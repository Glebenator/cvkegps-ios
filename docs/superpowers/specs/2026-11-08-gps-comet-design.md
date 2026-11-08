# GPS comet on the speed circle: design

- **Date:** 8 November 2026
- **Status:** Approved on 8 November 2026. Not built.
- **Code baseline:** `a65411a` on `clanker/trusting-brown-ku0enc` (PR #1). The comet goes on the quiet speed circle of
  that commit. Merge PR #1 before you build this.

## Intent

The Android app has a satellite ring around the speed. It is subtle, it shows real data, and it is abstract art. iOS
does not give satellite data to apps, so the iOS app cannot have that ring.

The GPS comet is the iOS answer. It is a light on the rim of the speed circle, in the signature gradient of the app
icon: electric blue into dusty rose. It uses only the values of each GPS fix. It shows how sure the GPS is about the
position, and the direction of travel with how sure that direction is.

## Goals

- Show the position accuracy and the direction of travel in an abstract, subtle form that a user can ignore.
- Use only real fix data. Every visual property has a defined meaning.
- Use the brand gradient: `Palette.accent` (blue) into `Palette.gradientEnd` (rose).
- Make the Speed screen as special on iOS as the satellite ring makes it on Android.

## Non-goals

- Height accuracy and speed accuracy. They stay in GPS details.
- Satellite data. iOS does not supply it.
- Changes to the Android app. Android keeps its satellite ring.
- The comet on maps, in replay, in the Live Activity, or in widgets.

## Anti-goals

These make the feature a failure, even if it works:

- The comet shows an old fix as current.
- The comet moves when no new data arrives (continuous animation).
- The comet is so bright or busy that it competes with the speed digits.
- The comet points in a direction that is wrong for the user (for example, north-up while the user thinks that up is
  ahead).
- The compass runs when the Speed screen is not visible.

## The look

The look comes from mockup "C · Comet". The mockup generator is not in Git. The description below is the reference.

1. **Rim.** A thin line on the edge of the quiet speed circle, about 2.5 pt wide. Its colour goes around the circle. It is
   blue at the direction of travel and fades into rose on the other side.
2. **Glow.** A soft, blurred band just outside the rim, with the same colours. It is fainter than the rim.
3. **The quiet speed circle** keeps its look (`SpeedDial` in `CVKEGPS/Screens/SpeedView.swift`). The comet is behind the
   circle or on its edge. It does not cover the digits.

### Space for the glow (designer's call)

- The rim, the glow, and the blur together reach at most 24 pt outside the circle.
- The comet draws inside the `SpeedDial` frame. It does not draw over the readings, the toolbar, or the side column, and
  it is not clipped.
- The circle diameter becomes `min(width, height, 320) − 2 × 24`, but not less than the diameter that the frame gives
  minus the free space that is already there. In practice: in portrait on an iPhone, the frame is wider than 368 pt, so
  the circle stays at 320 pt. In the accessibility layout (240 pt frame) and in the wide layout, the circle becomes up to
  48 pt smaller, so the digits there are a little smaller.
- Check the speed digits at the largest text size after this change.

## Behaviour

### Inputs

All fix inputs exist now in `GpsReading` (`SpeedModel.reading`). Use the existing rules; do not add new ones.

| Input | Source | Meaning in the comet |
|---|---|---|
| Position accuracy | `GpsReading.accuracyMeters` | Width and blur of the glow |
| Direction of travel | `GpsReading.bearingRadians`, only when `GpsReading.speedMetersPerSecond` is 1 m/s or more. This is the same rule as `TrackSample.courseRadians`. | Where the blue part is |
| Direction accuracy | `GpsReading.bearingAccuracyRadians` | How narrow the blue part is |
| Freshness | `SpeedModel` status (`.live` or `.stale`, 10 s) | Comet on or off |
| Phone heading | Core Location heading (new, see "Compass") | Turns the comet with the phone |

### Position accuracy: the glow

- Map the accuracy on a log scale from 3 m to 50 m. At 3 m or better, the glow is narrow and sharp. At 50 m, it is wide,
  soft, and faint.
- 50 m is `UsabilityLimits.maxHorizontalErrorMeters`. A fix that is worse than 50 m is not a usable position, so the
  comet does not show.
- The builder decides the exact widths, blur radii, and opacities, inside the 24 pt reach (see "Space for the glow").
  The mockup used more (about 40 pt); keep its proportions: the glow at 50 m is about twice as wide and three times as
  soft as at 3 m, and its opacity goes from 0.5 to 0.3.

### Direction of travel: the blue part

- The blue part is centred on the direction of travel, relative to the top edge of the screen (see "Compass").
- A sure direction makes a narrow blue point. An unsure direction makes a wide blue wash.
- The direction uncertainty is the combination of the course accuracy and the heading accuracy:
  √(course accuracy² + heading accuracy²). Both errors move the blue part on the screen. (Designer's call.)
- Map the combined uncertainty so that 2° or better is the narrowest and 45° or worse is the widest. When Core Location
  gives a direction but no direction accuracy, use 20° for the course part.
- The builder decides the shape of the colour curve. The mockup uses `((1 + cos(angle − direction)) / 2) ^ focus`, with
  `focus` from about 14 (sure) to 2 (unsure).

### States

| State | What shows |
|---|---|
| Fresh fix, moving, compass current | The comet points at the direction of travel, relative to the phone |
| Fresh fix, moving, no current compass | The resting comet (see the next row). The comet does not point. |
| Fresh fix, slower than 1 m/s or no direction | The resting comet: blue at the top left and rose at the bottom right, like the app icon. The glow still shows the position accuracy. |
| No fix yet, searching | No comet. The plain circle and a dash. |
| Signal lost (fix older than 10 s) | No comet. The plain circle and a dash. |
| Position worse than 50 m, or a network position | No comet |
| Location permission off, or reduced accuracy | No comet. The existing permission card stays. |

**Builder's note (designer's call):** Android draws its ring north-up when there is no compass. The comet does not do
that, because a north-up comet looks like "ahead" to a user with the phone in a car mount. Without a compass, the comet
rests and does not point.

### Compass

- Use `CLLocationManager` heading updates. They need no new permission.
- Use `trueHeading`. If it is negative (no true north yet), use the resting comet.
- If `headingAccuracy` is negative, the heading is not valid. Use the resting comet.
- If `headingAccuracy` is more than 30°, the compass is disturbed (common in a car mount). Use the resting comet.
  (Designer's call.)
- Set `headingOrientation` to the current interface orientation, so the comet is correct in landscape.
- Set a heading filter of 1°. Do not redraw for smaller changes.
- Start the compass only while the Speed tab is visible and the app is active. Stop it when the tab is not visible, the
  app goes to the background, or the screen locks. Do not use the compass for trip recording.
- Do not make a heading old by time. With the 1° filter, Core Location sends no update while the heading is steady, for
  example on a straight road, and the last heading stays correct. The heading stops being current only when Core
  Location reports a heading failure (`CLError.headingFailure`), when the accuracy becomes invalid or more than 30°, or
  when the compass stops. Then use the resting comet. (Designer's call. This differs from the 2-second limit on
  Android, which has a sensor that reports all the time.)
- Put the compass behind a small protocol, as the location access is now, so that the comet model has no Core Location
  types.
- Do not show a calibration prompt.

### Motion

- On each new fix or heading change, ease to the new comet over about 0.3 s.
- With Reduce Motion, change at once.
- Between updates, nothing moves. No timer, no repeating animation, no `TimelineView`.

### Colours and contrast

- Light and dark mode use the dynamic `Palette.accent` and `Palette.gradientEnd`. `accent` has Increase Contrast values;
  `gradientEnd` has none. Do not add new values for it. (Designer's call: the comet has no text, so it has no contrast
  requirement.)
- With Increase Contrast, make the rim stronger and the glow fainter.
- Gradient colours carry no text, so they have no contrast requirement. The speed digits keep their current contrast.

### Accessibility

- The comet is decoration for VoiceOver (`accessibilityHidden`).
- VoiceOver hears the direction of travel in words, for example "Moving north-east". (Designer's call: spoken only, no
  new visible text, so the screen stays quiet.)
  - Add the words to the accessibility label that VoiceOver reads for the position accuracy, in both forms of
    `GpsCard`: the compact row (`gps_compact`, at 5 m or better) and the full card in the `.live` state (worse than
    5 m). See "The GPS row without the accuracy bar".
  - Use 8 compass points from the true direction of travel. This needs no compass, so VoiceOver hears it whenever there
    is a direction of travel, also when the comet rests because the compass is not current.
  - Put the new words in `Localizable.xcstrings`.
- Give the comet the identifier `gps_comet` for UI tests, with a value that states the comet state: `pointing`,
  `resting`, or no element when hidden.
- The comet scales with the circle at all text sizes, including the smaller circle at accessibility sizes and the wide
  layout.

### The GPS row without the accuracy bar

The comet shows the position accuracy, so the Speed tab does not need the accuracy bar. (The owner's decision.)

- Remove `AccuracyBar` from `GpsCard` in both forms:
  - The compact row (`gps_compact`, at 5 m or better) becomes "GPS", the value ("±5 m"), and the chevron.
  - The full card in the `.live` state (worse than 5 m) shows the value as text, for example "Position accuracy ±12 m",
    in place of the bar.
- Keep the other states of the full card (searching, signal lost, permission, and the others) as they are, with their
  messages and recovery actions.
- Both forms stay a link to GPS details (`gps_card`).
- GPS details keeps its `AccuracyBar` with the scale.
- VoiceOver now reads the accuracy from the row, for example "GPS position accuracy ±5 metres. Moving north-east.", in
  place of the bar's label.

### Performance and privacy

- The comet redraws only when a new fix arrives (about 1 per second) or the heading changes by 1° or more.
- Measure frame time and energy on a real iPhone with the Speed tab open for 10 minutes. Compare with the build before
  the comet.
- Do not log headings or coordinates.

## Code shape (designer's suggestion, the builder decides)

- A pure function in `CVKEGPSCore` maps the inputs to a comet description: `nil` (hidden) or a value with the glow
  strength (0 to 1), the direction relative to the screen (or "resting"), and the focus. Core has no SwiftUI or Core
  Location types.
- A small heading source in `CVKEGPS/Location/` wraps `CLLocationManager` heading updates.
- A `SpeedComet` SwiftUI view draws the rim and the glow, for example with `AngularGradient` stops from the colour curve
  and `.blur(radius:)`, or with `Canvas`.

## Tests

- **Unit tests in `CVKEGPSCore`** for the mapping function only: the accuracy scale ends, the 50 m limit, the direction
  relative to the phone across 0°/360°, the focus ends, the resting cases, and the hidden cases.
- **UI flow** (`TripFlowUITests`): with simulated locations, check that `gps_comet` is `resting` while the simulator
  drives (the simulator has no compass), and that it disappears after the signal is lost. Add the comet to the
  screenshots for light, dark, Increase Contrast, largest text, and landscape.
- **Real iPhone (manual):** the comet points ahead with the phone held forward in a moving car or on a bike; it keeps
  pointing on a long straight road; it turns correctly when the phone turns, in portrait and landscape; it rests when
  the heading accuracy is worse than 30° (for example, near a magnet); energy as above.

## Documents to update with the change

- ADR in `cvkegps`: "Show a GPS comet on iOS instead of the satellite ring". Record the north-up decision.
- ADR 0007 in `cvkegps`: add the comet to the list of differences from Android.
- `README.md` of this repository: the Features list and the sentence about the satellite ring.
- `PROGRESS.html` in `cvkegps`: the change, the test results, and real screenshots.

## Left to the builder

- The exact curves, widths, blur, and opacities, inside the limits above.
- The drawing technique.
- The names of types and files.
