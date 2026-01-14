//
//  PomodoroRecord.swift
//  refomo
//

import Foundation

struct PomodoroRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let startTime: Date
    let plannedDuration: Int      // 설정 시간 (초)
    var actualDuration: Int?      // 실제 진행 시간 (초), nil이면 진행 중인 세션
    var goal: String?             // 목표
    var focusLevel: Int?          // 집중도 1-5
    var reflection: String?       // 회고
    var memo: String?             // 메모

    init(id: UUID = UUID(), startTime: Date, plannedDuration: Int, actualDuration: Int? = nil,
         goal: String? = nil, focusLevel: Int? = nil, reflection: String? = nil, memo: String? = nil) {
        self.id = id
        self.startTime = startTime
        self.plannedDuration = plannedDuration
        self.actualDuration = actualDuration
        self.goal = goal
        self.focusLevel = focusLevel
        self.reflection = reflection
        self.memo = memo
    }
}
