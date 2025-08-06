//
//  HapticManager.swift
//  Pomodoro Timer
//
//  Created by 尾野順哉 on 2025/04/10.
//

import CoreHaptics

class HapticManager {
    private var engine: CHHapticEngine?
    
    init() {
        prepareHaptics()
    }
    
    private func prepareHaptics() {
        // デバイスがハプティクスをサポートしているかチェック
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("ハプティックエンジンの作成に失敗: \(error.localizedDescription)")
        }
    }
    
    // 通常振動
    func playCustomHaptic() {
        // デバイスがハプティクスをサポートしているかチェック
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        // 振動の強さや鋭さ、持続時間などを指定してカスタムイベントを作成
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0) // 0.0～1.0
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5) // 0.0～1.0
        
        // 例として、1秒間の連続振動
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensity, sharpness],
            relativeTime: 0,
            duration: 1.0
        )
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("ハプティックパターンの再生に失敗: \(error.localizedDescription)")
        }
    }
}
