//
//  RecordViewModel.swift
//  refomo
//

import SwiftUI
import Combine

@MainActor
final class RecordViewModel: ObservableObject {
    @Published var focusLevel = 3
    @Published var goalText = ""
    @Published var reflection = ""
    @Published var memo = ""

    var pendingRecord: PendingRecord?
    var existingRecordId: UUID?

    private let storageService = StorageService.shared

    // Cached formatter
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd, HH:mm"
        return f
    }()

    var sessionInfo: String {
        guard let p = pendingRecord else { return "" }
        return "\(p.actualDuration / 60)분"
    }

    func saveRecord(completion: @escaping () -> Void) {
        guard let p = pendingRecord else { completion(); return }

        if let recordId = existingRecordId {
            // Update existing record
            var records = storageService.load()
            if let index = records.firstIndex(where: { $0.id == recordId }) {
                records[index].actualDuration = p.actualDuration
                records[index].goal = goalText.isEmpty ? nil : goalText
                records[index].focusLevel = focusLevel
                records[index].reflection = reflection.isEmpty ? nil : reflection
                if !memo.isEmpty {
                    records[index].memo = memo
                }
                // Update meditation data if present
                if let meditationCount = p.meditationCount {
                    records[index].meditationCount = meditationCount
                }
                if let meditationSeconds = p.meditationSeconds {
                    records[index].meditationSeconds = meditationSeconds
                }
                storageService.save(records: records)
            }
        } else {
            // Create new record
            let record = PomodoroRecord(
                startTime: p.startTime,
                plannedDuration: p.plannedDuration,
                actualDuration: p.actualDuration,
                goal: goalText.isEmpty ? nil : goalText,
                focusLevel: focusLevel,
                reflection: reflection.isEmpty ? nil : reflection,
                memo: memo.isEmpty ? nil : memo,
                meditationCount: p.meditationCount,
                meditationSeconds: p.meditationSeconds
            )
            storageService.append(record: record)
        }

        reset()
        completion()
    }

    func skip(completion: @escaping () -> Void) {
        reset()
        completion()
    }

    private func reset() {
        focusLevel = 3
        goalText = ""
        reflection = ""
        memo = ""
        pendingRecord = nil
        existingRecordId = nil
    }
}
