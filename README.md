# StikPair

A simple SwiftUI iOS app that creates a pairing file **on-device**, using iOS 27+ or tvOS 11+ wireless pairing. Powered by [idevice](https://github.com/jkcoxson/idevice).

## Requirements

- **iOS 27+**
- To build: Xcode 27, Rust (`aarch64-apple-ios` + `aarch64-apple-ios-sim`), `xcodegen`

## Build

```sh
rustup target add aarch64-apple-ios aarch64-apple-ios-sim
./build-rust.sh      # builds the Rust FFI -> StikPairFFI.xcframework
xcodegen generate    # generates StikPair.xcodeproj
open StikPair.xcodeproj
```

Set your signing team and run on a device.

## Use

### iPhone or iPad

1. Tap **Pair iPhone or iPad** and grant the Local Network prompt.
2. On the device: **Settings › Privacy & Security › Developer Mode**, scroll down,
   tap **Pair with StikPair**, and enter the PIN shown in the Live Activity.
3. When the "Pairing complete" notification arrives, return to the app and tap
   **Export Pairing File**.

### Apple TV

1. On Apple TV, open **Settings › Remotes and Devices › Remote App and Devices**.
2. Tap **Pair Apple TV** in StikPair and select the Apple TV.
3. Enter the six-digit code shown on the Apple TV.
4. When pairing completes, tap **Export Pairing File**.

## License

MIT, **non-commercial**. Free for personal/non-commercial use; for commercial use contact StephenDev0@outlook.com. See [LICENSE](LICENSE).
