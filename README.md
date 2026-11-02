# CVKE GPS for iOS

[![iOS CI](https://github.com/Glebenator/cvkegps-ios/actions/workflows/ios.yml/badge.svg?branch=main)](https://github.com/Glebenator/cvkegps-ios/actions/workflows/ios.yml?query=branch%3Amain)

A native iOS speedometer and trip recorder. It shows your GPS speed, records trips in the background with a Live
Activity, and replays them on Apple Maps with speed, height, and acceleration charts. Built with SwiftUI, the Liquid
Glass design of iOS 26, Apple Maps, Core Location, Core Motion, and Swift Charts.

CVKE GPS has three repositories:

| Repository | Contents |
|---|---|
| [cvkegps](https://github.com/Glebenator/cvkegps) | The product: decisions (ADRs), glossary, shared measurement rules, and the [progress report](https://github.com/Glebenator/cvkegps/blob/main/PROGRESS.html) |
| [cvkegps-android](https://github.com/Glebenator/cvkegps-android) | The Android app |
| **cvkegps-ios** | This repository: the iOS app, with the same measurement rules and product behaviour as Android |

## Status

- **Development build.** The app is not published. The bundle IDs `com.example.cvkegps` and
  `com.example.cvkegps.widgets` are development IDs.
- **CI.** The badge above shows the result of the newest run on `main`. Select it to see all runs.
- **Verification.** The UI flow runs on a simulator with simulated locations. GPS accuracy, recording with the screen
  locked, the Live Activity buttons, the motion sensors, VoiceOver, and battery use are not yet checked on a real
  iPhone. The progress report has the dated test results and the known limits.

### What CI checks

The workflow [`ios.yml`](.github/workflows/ios.yml) runs for each push to `main` and each pull request, on a
`macos-26` runner.

| Check | How | In CI |
|---|---|---|
| Measurement rules, storage, and recorder | `swift test` in `CVKEGPSCore` | Yes |
| App, widget extension, and UI test build | `xcodebuild build-for-testing`, without signing | Yes |
| UI flow: permission, live speed, record, stop and save, replay, Settings | `test1RecordAndReplayTrip`, light mode | Yes |
| Main screens in dark mode | `test2Screens` | Yes |
| Main screens at the largest accessibility text size | `test2Screens` | Yes |
| Real iPhone checks | Manual | No |

Each run uploads the screenshots of the UI flow as the `ios-captures` artifact.

## Features

- **Speed.** The current GPS speed in a large dial, with altitude, maximum speed, and a position accuracy bar. An old or
  poor reading shows as unavailable, never as a current speed.
- **Trip recording.** Start trip and the activity in the bar above the tabs. Pause, resume, and stop from the recording
  bar or from the Live Activity on the Lock Screen and in the Dynamic Island. After Stop and save, you can resume the
  trip for 2 minutes.
- **Start anywhere.** A Control Center button and Siri and Shortcuts actions open the app to start a trip. The app never
  starts a trip without the app on screen.
- **Trips.** Saved trips grouped by day, each with its route on Apple Maps: Standard, Muted, or Satellite, with speed
  colours and start and end markers.
- **Replay.** A player for a saved trip, with the moving position on the map, moments such as the fastest speed, and
  linked speed, height, and acceleration charts.
- **Activity.** An estimate from GPS speed (bike or ski, car or transit, plane), which you can correct.
- **GPX export.** Share a trip as a GPX file.
- **Settings.** Units, altitude reference, keep screen on, map options, and trip recording accuracy.
- **Design.** Liquid Glass tabs and map controls, light and dark appearance, Dynamic Type up to the largest
  accessibility size, and VoiceOver labels.

### Differences from Android

iOS reports no satellites, so the satellite ring, the sky map, and the satellite details are Android only. A Live
Activity replaces the Android notification. Apple Maps has no style files and no terrain map, and iOS has no wallpaper
colours. [ADR 0007](https://github.com/Glebenator/cvkegps/blob/main/docs/adr/0007-build-the-ios-app-with-apple-maps-and-a-shared-swift-core.md)
has the full list and the reasons.

## Screenshots

| Speed | Trips | Saved trip | Replay |
|---|---|---|---|
| ![Speed tab with 43.2 km/h in the glass dial, altitude and maximum speed, the accuracy bar, and Start trip above the tabs](https://raw.githubusercontent.com/Glebenator/cvkegps/main/docs/progress/images/2026-11-01-ios-review-speed-readings.webp) | ![Trips tab with one trip under Today: 4:42 to 4:43 PM, 51 s, 442 m](https://raw.githubusercontent.com/Glebenator/cvkegps/main/docs/progress/images/2026-11-01-ios-review-trips-list.webp) | ![Saved trip on Apple Maps with the speed colour route, Trip saved, Resume trip, and the trip values](https://raw.githubusercontent.com/Glebenator/cvkegps/main/docs/progress/images/2026-11-01-ios-review-saved-inline.webp) | ![Trip replay with the map, the player, the moments, and the speed chart](https://raw.githubusercontent.com/Glebenator/cvkegps/main/docs/progress/images/2026-11-01-ios-review-replay-chart-titles.webp) |

1 November 2026, commit `32933fc`. iPhone 17 Pro simulator, iOS 26.2. All locations are simulated with XCTest.

## Build and run

1. Use a Mac with Xcode 26 or later. The app needs iOS 26.0 or later.
2. Install XcodeGen: `brew install xcodegen`.
3. In this folder, run `xcodegen generate`. It makes `CVKEGPS.xcodeproj`, which is not in Git.
4. Open `CVKEGPS.xcodeproj`. Select the `CVKEGPS` scheme and an iPhone simulator or a phone.
5. For a phone, select your team in Signing & Capabilities for the `CVKEGPS` and `CVKEGPSWidgets` targets. A personal
   team can need another bundle ID than the development ID `com.example.cvkegps`.
6. Run. Select **Allow precise location**, then **Allow While Using App**.

The app needs no API key.

## Tests

- **Core tests.** In `CVKEGPSCore`, run `swift test`. They cover the measurement rules, formats and settings, the route
  math, the replay calculations, the SQLite store, and the recorder. They repeat the Android calculation tests. They
  also run on Linux with the Swift toolchain and `libsqlite3-dev`.
- **UI flow.** It uses the production Core Location path with simulated locations from XCTest. It records a trip along a
  street, stops and saves it, replays it, and opens Settings. Each step attaches a screenshot.

  ```sh
  xcodebuild test -project CVKEGPS.xcodeproj -scheme CVKEGPS -destination "platform=iOS Simulator,name=<iPhone>"
  ```

Simulator results are functional evidence only. GPS accuracy, the fix source rule, recording with the screen locked,
the Live Activity, the motion sensors, and battery use need a real iPhone.

## Location, battery, and privacy

- Location runs only while a screen or a recording trip needs it. A trip records in the background only after you
  start it, and the Live Activity shows while it records.
- The app does not keep the screen on unless you choose it in Settings.
- Trips stay on the phone in a local database. The app does not upload trip records and has no analytics.
- Apple Maps receives the map area that you look at. Share as GPX sends positions and times only to the app that you
  select.

## Project structure

```text
cvkegps-ios/
  project.yml                     XcodeGen project: the app, the widget extension, and the UI tests
  CVKEGPSCore/                    Swift package, Foundation only
    TripModels.swift, Measurements.swift, Units.swift    Models, the usability rules, and units
    RouteMath.swift               Distance, gaps, route lines, and the map frame
    ActivityEstimate.swift        Provisional activity from GPS speed
    SpeedColours.swift            Speed smoothing, the trip's speed range, and colour runs
    TripReplay.swift              Replay clock, values at the playhead, barometric height, acceleration, moments, chart data
    SensorRecord.swift            Sensor chunks in the Android storage format
    DisplayFormat.swift           Locale-aware text from SI values
    Settings.swift                Stored choices in user defaults
    TripStore.swift               SQLite store with the Room schema
    TripRecorder.swift            One ordered command queue for trip changes, location demand, and sensors
  CVKEGPS/
    App/                          App entry, app model, tabs and the recording accessory, keep screen on
    Location/                     Core Location service and the Core Motion recorder
    Recording/                    Trip commands and access, trip list, Live Activity, Speed tab state
    Screens/                      Speed, GPS details, Trips, current trip, saved trip, Settings, recording notice
    Map/                          Apple Maps route map, follow modes, markers, and speed colours
    Replay/                       Replay model, panel, speed profile, and Swift Charts
    Design/                       Colour tokens, glass components, and visible text
    Resources/                    App icon, accent colour, string catalog, and privacy manifest
  CVKEGPSWidgets/                 Live Activity, Dynamic Island, and the Control Center Start trip button
  Shared/                         Live Activity attributes and the trip intents, in the app and the extension
  CVKEGPSUITests/                 The UI flow
```

## Documents

- [Progress report](https://github.com/Glebenator/cvkegps/blob/main/PROGRESS.html): status, screenshots, test evidence,
  and future work for both apps.
- [Decisions (ADRs)](https://github.com/Glebenator/cvkegps/tree/main/docs/adr) and the
  [glossary](https://github.com/Glebenator/cvkegps/blob/main/GLOSSARY.md).
- [AGENTS.md](AGENTS.md): the rules for work on this app.

Until 2 November 2026, this app was in the `ios/` folder of `cvkegps`. This repository keeps its history.

Report a problem or a request in [GitHub Issues](https://github.com/Glebenator/cvkegps-ios/issues).
