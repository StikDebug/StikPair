import Foundation

struct AppleTVDevice: Identifiable, Equatable {
    let id: String
    let name: String
    let host: String
    let port: Int
}

@MainActor
final class AppleTVDiscovery: NSObject, ObservableObject {
    @Published private(set) var devices: [AppleTVDevice] = []

    private let browser = NetServiceBrowser()
    private var services: [String: NetService] = [:]

    override init() {
        super.init()
        browser.delegate = self
    }

    func start() {
        guard services.isEmpty else { return }
        browser.searchForServices(
            ofType: "_remotepairing-manual-pairing._tcp.",
            inDomain: "local.")
    }

    func stop() {
        browser.stop()
        for service in services.values {
            service.stop()
        }
        services.removeAll()
        devices.removeAll()
    }

    private func identifier(for service: NetService) -> String {
        "\(service.name).\(service.type)\(service.domain)"
    }

    private func update(_ service: NetService) {
        guard let host = service.hostName, service.port > 0 else { return }
        let id = identifier(for: service)
        let txt = service.txtRecordData().map(NetService.dictionary(fromTXTRecord:)) ?? [:]
        let advertisedName = txt["name"].flatMap { String(data: $0, encoding: .utf8) }
        let displayName = advertisedName.flatMap { $0.isEmpty ? nil : $0 } ?? service.name
        let device = AppleTVDevice(
            id: id,
            name: displayName,
            host: host,
            port: service.port)
        devices.removeAll { $0.id == id }
        devices.append(device)
        devices.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

extension AppleTVDiscovery: NetServiceBrowserDelegate {
    nonisolated func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didFind service: NetService,
        moreComing: Bool
    ) {
        Task { @MainActor in
            let id = identifier(for: service)
            services[id] = service
            service.delegate = self
            service.resolve(withTimeout: 6)
        }
    }

    nonisolated func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didRemove service: NetService,
        moreComing: Bool
    ) {
        Task { @MainActor in
            let id = identifier(for: service)
            services.removeValue(forKey: id)
            devices.removeAll { $0.id == id }
        }
    }
}

extension AppleTVDiscovery: NetServiceDelegate {
    nonisolated func netServiceDidResolveAddress(_ sender: NetService) {
        Task { @MainActor in update(sender) }
    }

    nonisolated func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
        Task { @MainActor in update(sender) }
    }
}
