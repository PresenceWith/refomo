//
//  SoundService.swift
//  refomo
//

import AVFoundation
import UIKit

final class SoundService {
    static let shared = SoundService()

    // Cached generators for better performance
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let selection = UISelectionFeedbackGenerator()

    private init() {
        // Prepare generators for lower latency
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactSoft.prepare()
        selection.prepare()
    }

    func playCompletionSound() { AudioServicesPlaySystemSound(1103) }

    func playHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light:  impactLight.impactOccurred()
        case .medium: impactMedium.impactOccurred()
        case .heavy:  impactHeavy.impactOccurred()
        default:      UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
    }

    func playSelectionHaptic() { selection.selectionChanged() }

    /// Soft haptic for breath phase transitions during meditation
    func playBreathTransitionHaptic() {
        impactSoft.impactOccurred(intensity: 0.5)
    }
}
