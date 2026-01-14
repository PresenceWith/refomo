//
//  HistoryViewModel.swift
//  refomo
//

import SwiftUI
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var records: [PomodoroRecord] = []

    private let storageService = StorageService.shared

    // Cached formatter for date headers
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M월 d일 (E)"
        f.locale = Locale(identifier: "ko_KR")
        return f
    }()

    var groupedRecords: [Date: [PomodoroRecord]] {
        Dictionary(grouping: records) { Calendar.current.startOfDay(for: $0.startTime) }
    }

    func loadRecords() {
        records = storageService.load().sorted { $0.startTime > $1.startTime }
    }

    func updateRecord(_ record: PomodoroRecord) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[index] = record
        storageService.save(records: records)
    }

    func deleteRecord(_ record: PomodoroRecord) {
        records.removeAll { $0.id == record.id }
        storageService.save(records: records)
    }

    func formatDateHeader(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "오늘" }
        if cal.isDateInYesterday(date) { return "어제" }
        return Self.dateFormatter.string(from: date)
    }
}
