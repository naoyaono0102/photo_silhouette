//
//  StateSwitch.swift
//  Pomodoro Timer
//
//  Created by 尾野順哉 on 2025/04/02.
//

import SwiftUI

// モードを切り替えるためのカスタムSegmentedControlを利用したView
struct ModeSwitch: View {
    @Binding var mode: HomeViewModel.TimerMode // 外部から現在のモードを受け取る

    var body: some View {
        SegmentedControl(
            selectedSegment: $mode,
            configuration: .init(
                selectedForegroundColor: .white,
                selectedBackgroundColor: .black.opacity(0.75),
                foregroundColor: Color("TextDarkColor"),
                backgroundColor: .gray.opacity(0.25)
            )
        )
//        .frame(width: 300)
        .padding(.horizontal)
    }
}

// 各セグメントが持つべきプロパティを定義したプロトコル
protocol SegmentTypeProtocol: CaseIterable, Identifiable, Equatable {
    var title: String { get } // セグメントの表示タイトル
    var tintColor: Color? { get } // セグメントの選択時の背景色（任意）
}

// tintColorにデフォルト値を提供（nilの場合）
extension SegmentTypeProtocol {
    var tintColor: Color? { nil }
}

// 汎用的なカスタマイズ可能なSegmentedControlのView
struct SegmentedControl<SegmentType: SegmentTypeProtocol>: View where SegmentType.AllCases == [SegmentType] {
    // セグメントの色やスタイルを指定するための設定構造体
    struct Configuration {
        var selectedForegroundColor: Color = .white
        var selectedBackgroundColor: Color = .black.opacity(0.75)
        var foregroundColor: Color = .init("TextDarkColor")
        var backgroundColor: Color = .gray.opacity(0.25)
    }

    @Binding var selectedSegment: SegmentType // 現在選択中のセグメント
    var configuration: Configuration = .init() // スタイル設定

    var body: some View {
        HStack(spacing: 0) {
            // すべてのセグメントを表示
            ForEach(SegmentType.allCases) { segment in
                Button(action: {
                    withAnimation(.interactiveSpring) {
                        selectedSegment = segment // セグメント選択時に更新
                    }
                }) {
                    ZStack {
                        Rectangle()
                            .fill(configuration.backgroundColor)

                        Text(segment.title)
                            .font(.system(size: 18, weight: .bold))
//                            .foregroundStyle(isSelected(segment: segment) ? configuration.selectedForegroundColor : configuration.foregroundColor)
                            .foregroundStyle(
                                isSelected(segment: segment)
                                    ? (segment.tintColor?.isLightColor() == true ? Color("TextDarkColor") : Color.white)
                                    : configuration.foregroundColor
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                            .background {
                                if isSelected(segment: segment) {
                                    // 選択中のセグメントの背景色
                                    Rectangle()
                                        .fill(segment.tintColor ?? configuration.selectedBackgroundColor)
                                        .frame(height: 40)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .padding(4)
                                }
                            }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // 現在のセグメントが選択中かどうか判定するメソッド
    private func isSelected(segment: SegmentType) -> Bool {
        selectedSegment == segment
    }
}

extension HomeViewModel.TimerMode: SegmentTypeProtocol {
    var title: String {
        localizedTitle // ここでローカライズ済み文字列を返す
    }

    var tintColor: Color? {
        switch self {
        case .focus:
            return Color(hex: UserDefaults.standard.string(forKey: "focusColorHex") ?? "#3B3B3B")
        case .shortBreak:
            return Color(hex: UserDefaults.standard.string(forKey: "breakColorHex") ?? "#3B3B3B")
        }
    }
}

// プレビュー表示用の設定
struct ModeSwitch_Previews: PreviewProvider {
    static var previews: some View {
        ModeSwitch(mode: .constant(.focus)) // プレビューでは初期モードを"集中"に設定
    }
}

// テキストカラーを背景の色の濃さによって白にするか黒にするか選択する
extension Color {
    func isLightColor() -> Bool {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        // 相対輝度の計算
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.7
    }
}
