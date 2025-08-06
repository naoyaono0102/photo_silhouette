//
//  CircleProgressBar.swift
//  Pomodoro Timer
//
//  Created by 尾野順哉 on 2025/04/02.
//

import SwiftUI

struct CircleProgressBar: View {
    // 進捗率（0.0～1.0）
    var progress: Double

    // 残り時間（秒）
    var timeRemaining: TimeInterval

    var modeColor: Color = .init("ProgressBarColor")

    var body: some View {
        // 分と秒に変換
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        let timeString = "\(minutes):\(String(format: "%02d", seconds))"

        // 円形のProgress bar
        ZStack {
            // 背景の円
            Circle()
                .stroke(
                    modeColor.opacity(0.3),
                    lineWidth: UIDevice.current.userInterfaceIdiom == .pad
                        ? 45
                        : 30
                )

            // 進行状況の円
//            Circle()
//                .trim(from: 0.0, to: progress)
//                .stroke(Color("ProgressBarColor"), style: StrokeStyle(lineWidth: 30, lineCap: .round))
//                .rotationEffect(.degrees(-90)) // 開始位置を上に調整
//                .animation(.easeInOut(duration: 0.5), value: progress)
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(
                    modeColor,
                    style: StrokeStyle(
                        lineWidth: UIDevice.current.userInterfaceIdiom == .pad ? 45 : 30,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            // 中央のテキスト
            VStack {
                Text(timeString)
//                Text("\(Int(ceil(timeRemaining)))") // 秒表示を1秒単位に丸める
                    .font(
                        .system(
                            size: UIDevice.current.userInterfaceIdiom == .pad ? 100 : 36,
                            weight: .bold
                        )
                    )
                    .foregroundColor(Color("TextDarkColor"))
                    .monospacedDigit() // 等幅フォント対応
            }
        }
        .frame(
            width: UIDevice.current.userInterfaceIdiom == .pad
                ? max(UIScreen.main.bounds.width, UIScreen.main.bounds.height) < 1200 ? 500 : 600
                : 300,
            height: UIDevice.current.userInterfaceIdiom == .pad
                ? max(UIScreen.main.bounds.width, UIScreen.main.bounds.height) < 1200 ? 500 : 600
                : 300
        )
    }
}

#Preview {
    @Previewable var progress = 0.6
    @Previewable var timeRemaining: TimeInterval = 600

    CircleProgressBar(progress: progress, timeRemaining: timeRemaining)
}
