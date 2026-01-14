//
//  StorageService.swift
//  refomo
//

import Foundation

final class StorageService {
    static let shared = StorageService()

    private let fileName = "records.json"
    private let folderName = "Refomo"
    private let containerID = "iCloud.com.presence042.refomo"

    // Cached encoder/decoder
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = .prettyPrinted
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private lazy var storageURL: URL = {
        FileManager.default.url(forUbiquityContainerIdentifier: containerID)?
            .appendingPathComponent("Documents/\(folderName)")
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(folderName)
    }()

    private lazy var fileURL: URL = { storageURL.appendingPathComponent(fileName) }()

    private init() {}

    func save(records: [PomodoroRecord]) {
        do {
            try FileManager.default.createDirectory(at: storageURL, withIntermediateDirectories: true)
            try encoder.encode(records).write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save records: \(error)")
        }
    }

    func load() -> [PomodoroRecord] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        do {
            return try decoder.decode([PomodoroRecord].self, from: Data(contentsOf: fileURL))
        } catch {
            print("Failed to load records: \(error)")
            return []
        }
    }

    func append(record: PomodoroRecord) {
        var records = load()
        records.append(record)
        save(records: records)
    }

    func update(record: PomodoroRecord) {
        var records = load()
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
            save(records: records)
        }
    }
}
