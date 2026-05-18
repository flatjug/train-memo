# TrainMemo

TrainMemo is a simple SwiftUI app for keeping a daily workout routine with four rotating YouTube videos.

## Features

- Shows today's workout video from a four-day rotation.
- Opens the registered YouTube URL from the Today tab.
- Records daily completion with SwiftData.
- Displays current streak, total completed days, and a monthly completion calendar.
- Lets you edit video titles, URLs, durations, and order.
- Schedules local notifications for upcoming workout days.

## Requirements

- Xcode 16 or later
- iOS 17.0 or later
- Swift 6

## Project Structure

```text
TrainMemo/
  App/        App entry point and SwiftData container setup
  Models/     SwiftData models
  Services/   Bootstrap, workout rotation, and notification scheduling logic
  Views/      Today, history, settings, and tab views
TrainMemoTests/
  WorkoutSchedulerTests.swift
```

## Build

Open `TrainMemo.xcodeproj` in Xcode and run the `TrainMemo` scheme.

From the command line:

```sh
xcodebuild -project TrainMemo.xcodeproj \
  -scheme TrainMemo \
  -destination 'generic/platform=iOS Simulator' \
  build
```

## Tests

The unit tests focus on workout rotation, streak calculation, completed-day deduplication, and calendar grid generation.

```sh
xcodebuild -project TrainMemo.xcodeproj \
  -scheme TrainMemo \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test
```

## Notes

The app creates four placeholder videos on first launch. Edit them from the Settings tab before using the routine.
