//
//  PinsService.swift
//  Pulse Pro
//
//  Created by Alexander Grebenyuk on 9/30/21.
//  Copyright © 2021 kean. All rights reserved.
//

import Foundation
import PulseCore
import AppKit
import CommonCrypto
import Combine

final class PinsService: ObservableObject {
    private let serviceId: String
    private let pinsStoreURL: URL
    private let psc: NSPersistentStoreCoordinator
    
    @Published private(set) var pinnedMessageIds: Set<NSManagedObjectID> = []
    @Published private(set) var pinnedRequestIds: Set<NSManagedObjectID> = []
    
    private static var services: [URL: PinsService] = [:]
    
    private var isDirty = false
    private weak var timer: Timer?
    private var cancellables: [AnyCancellable] = []
    
    init(store: LoggerStore) {
        self.serviceId = (store.storeURL.absoluteString.data(using: .utf8) ?? Data()).sha256
        self.pinsStoreURL = URL.pins.appendingFilename(serviceId)
        self.psc = store.container.persistentStoreCoordinator

        readPinsFromDisk()
        
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.savePinsToDiskIfNeeded()
        }

        NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification, object: nil).sink { [weak self] _ in
            self?.savePinsToDiskIfNeeded()
        }.store(in: &cancellables)
    }
    
    // MARK: Shared Services
    
    static func service(for store: LoggerStore) -> PinsService {
        if let service = PinsService.services[store.storeURL] {
            return service
        }
        let service = PinsService(store: store)
        PinsService.services[store.storeURL] = service
        return service
    }
    
    // MARK: Managing Pins
    
    func isPinned(_ message: LoggerMessageEntity) -> Bool {
        pinnedMessageIds.contains(message.objectID)
    }
    
    func isPinned(_ request: LoggerNetworkRequestEntity) -> Bool {
        pinnedRequestIds.contains(request.objectID)
    }
    
    func togglePin(for message: LoggerMessageEntity) {
        _togglePin(for: message)
        if let request = message.request {
            _togglePin(for: request)
        }
    }
    
    private func _togglePin(for message: LoggerMessageEntity) {
        if pinnedMessageIds.remove(message.objectID) == nil {
            pinnedMessageIds.insert(message.objectID)
        }
        isDirty = true
    }
    
    func togglePin(for request: LoggerNetworkRequestEntity) {
        _togglePin(for: request)
        if let message = request.message {
            _togglePin(for: message)
        }
    }
    
    private func _togglePin(for request: LoggerNetworkRequestEntity) {
        if pinnedRequestIds.remove(request.objectID) == nil {
            pinnedRequestIds.insert(request.objectID)
        }
        isDirty = true
    }
    
    func removeAllPins() {
        pinnedMessageIds.removeAll()
        pinnedRequestIds.removeAll()
        isDirty = true
    }
    
    // MARK: Persistence
    
    private func readPinsFromDisk() {
        guard let data = try? Data(contentsOf: pinsStoreURL),
              let store = try? JSONDecoder().decode(PinsStore.self, from: data) else { return }
        
        for pin in store.pins {
            if let objectID = psc.managedObjectID(forURIRepresentation: pin.objectURL) {
                switch pin.type {
                case .message: pinnedMessageIds.insert(objectID)
                case .request: pinnedRequestIds.insert(objectID)
                }
            }
        }
    }
    
    private func savePinsToDiskIfNeeded() {
        guard isDirty else { return }
        
        var pins: [PinEntity] = []
        for id in pinnedMessageIds {
            pins.append(PinEntity(type: .message, objectURL: id.uriRepresentation()))
        }
        for id in pinnedRequestIds {
            pins.append(PinEntity(type: .request, objectURL: id.uriRepresentation()))
        }
        let store = PinsStore(pins: pins)
        
        do {
            let data = try JSONEncoder().encode(store)
            try data.write(to: pinsStoreURL)
            isDirty = false
        } catch {
            NSLog("Failed to save pins: \(error)")
        }
    }
}

private struct PinsStore: Codable {
    var pins: [PinEntity]
}

private struct PinEntity: Codable {
    enum PinType: Codable {
        case message
        case request
    }
    let type: PinType
    let objectURL: URL
}

private extension URL {
    static var pins: URL {
        let url = Files.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingDirectory("Pins") ?? URL(fileURLWithPath: "/dev/null")
        Files.createDirectoryIfNeeded(at: url)
        return url
    }
}

private extension Data {
    /// Calculates SHA256 from the given string and returns its hex representation.
    ///
    /// ```swift
    /// print("http://test.com".data(using: .utf8)!.sha256)
    /// // prints "8b408a0c7163fdfff06ced3e80d7d2b3acd9db900905c4783c28295b8c996165"
    /// ```
    var sha256: String {
        let hash = withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            CC_SHA256(bytes.baseAddress, CC_LONG(count), &hash)
            return hash
        }
        return hash.map({ String(format: "%02x", $0) }).joined()
    }
}
