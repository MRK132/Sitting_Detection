# Sitting Detection App

## Overview
The Sitting Detection App is an iOS application designed to help users monitor their standing and sitting habits throughout the day. By leveraging Apple's HealthKit, the app tracks standing time and provides insights into prolonged sitting periods, promoting better health practices in daily life.

## Features
- Real-time tracking of standing time
- Calculation of continuous sitting hours during work hours (9AM-6PM)
- User-friendly interface displaying current standing status and sitting duration
- Background health data processing for up-to-date information

## Requirements
- iOS 14.0 or later
- Xcode 12.0 or later
- Swift 5.0 or later
- iPhone with HealthKit support

## Installation
1. Clone the repository:
   ```
   git clone https://github.com/MRK132/Sitting_Detection.git
   ```
2. Open the `Sitting_Detection.xcodeproj` file in Xcode.
3. Ensure you have the necessary signing capabilities and provisioning profiles set up in Xcode.
4. Build and run the app on your device or simulator.

## Usage
1. Launch the app on your iPhone.
2. Grant the necessary HealthKit permissions when prompted.
3. The main screen will display your current standing status for the hour and the maximum continuous sitting hours.
4. The app will automatically update this information periodically.
5. To manually refresh the data, you can pull down to refresh on the main screen.

### Interpreting the Data
- **Current Hour Standing Complete**: Indicates whether you've stood for at least one minute in the current hour.
- **Continuous Sitting Hours**: Shows the maximum number of hours you've been sitting continuously between 9AM and 6PM.

## HealthKit Integration
This app uses HealthKit to access your standing time data. Ensure that you have granted the app permission to read your Health data. The app specifically uses the `HKQuantityTypeIdentifierAppleStandTime` to track standing periods.

## Customization
You can adjust the work hours and standing time thresholds in the `StandingViewModel.swift` file:
- To change work hours, modify the `calendar9AM` and `calendar6PM` variables in the `fetchStandingData()` function.
- To adjust the standing time required to complete an hour, modify the condition `standingTime >= 1.0` in the same function.

## Troubleshooting
If you encounter issues with HealthKit data not updating:
1. Ensure that HealthKit permissions are granted in the iPhone's Settings app.
2. Check that your device supports HealthKit and is collecting standing data.
3. Verify that the app has background refresh capabilities enabled in the iPhone's Settings.

## Contributing
Contributions to the Sitting Detection App are welcome! Please feel free to submit a Pull Request.

## License
[MIT License]

## Contact
For any queries or support, please contact mrk.garv@gmail.com.
