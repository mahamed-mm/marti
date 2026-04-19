# Build / Test / Run

## Build

```bash
xcodebuild -project marti/Marti.xcodeproj -scheme Marti \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Unit tests (UI tests flaky in CI)

```bash
xcodebuild -project marti/Marti.xcodeproj -scheme Marti \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:MartiTests test
```

## Install + launch on booted simulator

```bash
xcrun simctl install booted /path/to/Marti.app
xcrun simctl launch booted so.Marti
```

- No XcodeBuildMCP — use `xcodebuild` directly.
- Default simulator: iPhone 17 Pro (Xcode 26.x doesn't ship iPhone 16 Pro).
