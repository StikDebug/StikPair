import SwiftUI

struct ContentView: View {
    @StateObject private var controller = PairingController.shared
    @State private var appleTVPin = ""

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            appIcon

            Text("StikPair")
                .font(.largeTitle.bold())

            content
                .frame(maxWidth: 320)

            Spacer()
        }
        .padding()
        .animation(.default, value: controller.phase)
    }

    @ViewBuilder
    private var content: some View {
        switch controller.phase {
        case .idle:
            VStack(spacing: 20) {
                Button {
                    controller.start()
                } label: {
                    Text("Pair iPhone or iPad")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .controlSize(.large)

                Button {
                    controller.browseForAppleTVs()
                } label: {
                    Text("Pair Apple TV")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .controlSize(.large)

                keepAliveOptions
            }

        case .waiting:
            VStack(spacing: 16) {
                ProgressView()
                Text("Waiting for a device to connect…")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    Text("On this device:")
                        .font(.subheadline.weight(.semibold))
                    guideStep(1, "Open the **Settings** app")
                    guideStep(2, "Go to **Privacy & Security**")
                    guideStep(3, "Tap **Developer Mode**")
                    guideStep(4, "Scroll down and tap **Pair with StikPair**")
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(.regular, in: .rect(cornerRadius: 20))

                Text("If **Pair with StikPair** doesn't show up, close the app and try again.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

        case .showPin(let pin):
            VStack(spacing: 16) {
                Text("Enter this code on your device")
                    .font(.headline)
                Text(pin)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .tracking(8)
                    .textSelection(.enabled)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .glassEffect(.regular, in: .capsule)
                ProgressView()
            }

        case .browsingAppleTV:
            VStack(spacing: 16) {
                Text("Choose an Apple TV")
                    .font(.headline)
                Text("On Apple TV, open **Settings › Remotes and Devices › Remote App and Devices**.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if controller.appleTVs.isEmpty {
                    ProgressView("Looking for Apple TVs…")
                } else {
                    ForEach(controller.appleTVs) { device in
                        Button {
                            appleTVPin = ""
                            controller.pairAppleTV(device)
                        } label: {
                            Label(device.name, systemImage: "appletv")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glass)
                        .controlSize(.large)
                    }
                }

                Button("Cancel") { controller.cancelAppleTVPairing() }
                    .buttonStyle(.glass)
            }

        case .enteringAppleTVPin(let device):
            VStack(spacing: 16) {
                Text("Pair with \(device.name)")
                    .font(.headline)
                Text("Enter the six-digit code shown on your Apple TV.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                TextField("000000", text: $appleTVPin)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .onChange(of: appleTVPin) { _, value in
                        appleTVPin = String(value.filter(\.isNumber).prefix(6))
                    }
                    .padding()
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))
                Button("Pair") {
                    controller.submitAppleTVPin(appleTVPin)
                }
                .buttonStyle(.glass)
                .controlSize(.large)
                .disabled(appleTVPin.count != 6)
                Button("Cancel") { controller.cancelAppleTVPairing() }
                    .buttonStyle(.glass)
            }

        case .pairingAppleTV(let name):
            VStack(spacing: 16) {
                ProgressView()
                Text("Pairing with \(name)…")
                    .foregroundStyle(.secondary)
                Button("Cancel") { controller.cancelAppleTVPairing() }
                    .buttonStyle(.glass)
            }

        case .success(let device):
            VStack(spacing: 12) {
                Label("Paired", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .font(.title3.bold())
                if !device.name.isEmpty {
                    Text("\(device.name) · \(device.model)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                ShareLink(item: URL(fileURLWithPath: device.pairingFilePath)) {
                    Label("Export Pairing File", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .controlSize(.large)
                .padding(.top, 4)

                Button("Done") { controller.reset() }
                    .buttonStyle(.glass)
            }

        case .failed(let message):
            VStack(spacing: 10) {
                Label("Failed", systemImage: "xmark.octagon.fill")
                    .foregroundStyle(.red)
                    .font(.title3.bold())
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)
                Button("Try Again") { controller.reset() }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .padding(.top, 4)
            }
        }
    }

    private var keepAliveOptions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Background keep-alive")
                .font(.subheadline.weight(.semibold))
            Toggle("Silent audio", isOn: $controller.keepAliveAudio)
            Toggle("Location", isOn: $controller.keepAliveLocation)
            Text("Enable one or more of these if the Live Activity doesn't start.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var appIcon: some View {
        Image("AppLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 116, height: 116)
    }

    private func guideStep(_ number: Int, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(.tint, in: Circle())
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    ContentView()
}
