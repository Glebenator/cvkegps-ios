# Project rules: CVKE GPS for iOS

CVKE GPS has three repositories. This repository is the native iOS app.

- [cvkegps](https://github.com/Glebenator/cvkegps): the product. Decisions (ADRs), the glossary, the shared
  measurement rules, and the progress report. Product rules there apply to this app.
- [cvkegps-android](https://github.com/Glebenator/cvkegps-android): the Android app.
- [cvkegps-ios](https://github.com/Glebenator/cvkegps-ios): this repository.

## Product

- Build a native iOS app for publication. It has the same measurement rules and product behaviour as the Android app.
- Use ASD-STE100 Simplified Technical English for instructions and documentation.
- Implement only the agreed feature scope. Do not add inactive controls or simulated production data.
- Record each intended difference from Android in an ADR in the cvkegps repository. ADR 0007 has the current list.
- Commit and push only when the user asks.

## Structure

- Use Swift, SwiftUI, and the iOS 26 design. Generate the Xcode project with XcodeGen from `project.yml`.
- Keep the measurement rules, the trip store, and the recorder in the `CVKEGPSCore` Swift package. It uses Foundation
  only. Keep UIKit, SwiftUI, Core Location, and Core Motion objects out of it.
- Keep measurements in SI units. Convert them only for display.
- Use observable models with one-way data flow. Pass dependencies through initializers.
- Keep the stored data compatible with the Android storage format, as `TripStore` and `SensorRecord` do.
- Add a dependency only when it solves a current problem. Do not add unused libraries.
- Use structured concurrency with a defined owner for each task. Do not start detached work that nothing cancels.

## Design and access

- Use system components, the app colour tokens, and standard iOS navigation.
- Support light and dark appearance, Dynamic Type up to the largest accessibility size, VoiceOver, and rotation.
- Make touch targets at least 44 points.
- Put visible text in the string catalog. Format numbers for the user's locale.
- Explain location use before the system asks. Provide a recovery action when access or location services are off.
- Show missing or old measurements as unavailable. Never show an old speed as a current speed.

## Performance and privacy

- Run location updates only while a feature needs them. Stop them when the screen is not visible.
- A trip that the user starts can record in the background with a visible Live Activity.
- Do not start or restart a trip silently in the background. The Start trip intent opens the app.
- Do not keep the screen on by default.
- Keep disk access and expensive calculations off the main actor.
- Avoid continuous animation and unnecessary view updates. Measure with Instruments before adding performance complexity.
- Do not log coordinates or include them in crash reports.
- Do not add analytics, network transmission, or cloud backup of location data without an agreed product requirement.
- Treat simulator results as functional evidence only. Measure battery use and GPS accuracy on a real iPhone.

## Tests and delivery

- Run `swift test` in `CVKEGPSCore` for measurement, storage, and recorder changes.
- Run the UI flow on a simulator for functional changes. It uses the production Core Location path with simulated
  locations from XCTest. Do not replace the whole app with a fake.
- Add unit tests only for calculations or failure cases that the UI flow cannot cover well.
- Restore the simulator appearance, text size, and location after tests.
- The workflow `.github/workflows/ios.yml` runs the core tests and the UI flow for each push to `main` and each pull
  request. Check its result before you report a change as verified.
- Inspect light mode, dark mode, and the largest text size after layout changes.
- Report what was tested, what failed, and what still needs a real iPhone.
- Keep generated output, the generated Xcode project, signing data, and Xcode user state out of Git.
- Before publication, replace the development bundle IDs, set up signing, and complete the App Store privacy details.

## Progress report

- The progress report is `PROGRESS.html` in the cvkegps repository. Its rules are in the `AGENTS.md` file there.
- After a completed iOS change, update the report in a separate change in cvkegps. Name the cvkegps-ios commit.

## Issues

- Issues for the iOS app are in GitHub Issues for `Glebenator/cvkegps-ios`. Use the `gh` CLI.
- A feature that both apps need has a parent issue in `Glebenator/cvkegps` and one sub-issue for each app.
- Use the triage labels `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, and `wontfix`.
