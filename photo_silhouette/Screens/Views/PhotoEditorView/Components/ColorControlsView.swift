//
//  ColorControlsView.swift
//  white_frame
//
//  Created by 尾野順哉 on 2025/07/10.
//

import SwiftUI

// MARK: - カラー選択コントロール

struct ColorControlsView: View {
    @Binding var mode: ColorMode
    @Binding var selectedSimple: Color
    @Binding var selectedGradient: [Color]

    // シンプルモード用カラーパレット
    private let simpleColors: [Color] = [
        .white, .black,
        // 赤・ピンク系
        Color(red: 1.0, green: 0.8, blue: 0.82), // Pastel Red
        Color(red: 0.95, green: 0.7, blue: 0.8), // original pink
        .red,

        // オレンジ・イエロー系
        Color(red: 1.0, green: 0.95, blue: 0.7), // original yellow
        Color(red: 1.0, green: 0.85, blue: 0.7), // Pastel Orange
        .yellow,

        // グリーン系
        Color(red: 0.8, green: 1.0, blue: 0.8), // Pastel Green
        Color(red: 0.7, green: 0.9, blue: 0.85), // original mint-ish
        .green,
        .mint,

        // ブルー・パープル系
        Color(red: 0.8, green: 0.9, blue: 1.0), // Pastel Blue
        Color(red: 0.8, green: 0.7, blue: 0.9), // original purple
        .blue,
        .purple,
    ]

    // グラデーションモード用プリセット
    private let gradientPalettes: [[Color]] = [
        [.pink, .yellow],
        [.yellow, .red],
        [.orange, .pink],
        [.purple, .pink],
        [.red, .purple], // レッド→パープル
        [.green, .mint], // グリーン→ミント
        [.green, .blue],
        [.blue, .cyan], // ブルー→シアン
        [.blue, .purple],
        [.purple, .indigo],
    ]

    private let itemSize: CGFloat = 28

    // カスタムピッカー制御
    @State private var showCustomSimplePicker = false
    @State private var customSimpleColor: Color = .white
    @State private var showCustomGradientPicker = false
    @State private var customGradientStart: Color = .red
    @State private var customGradientEnd: Color = .blue

    var body: some View {
        VStack {
            // モード切替を中央寄せ
            HStack(spacing: 16) {
                ForEach(ColorMode.allCases) { item in
                    Text(LocalizedStringKey(item.title))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(item == mode ? Color("MainAccentColor") : Color.clear)
                        .foregroundColor(item == mode ? .white : Color.accentColor)
                        .clipShape(Capsule())
                        .onTapGesture { withAnimation { mode = item } }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 12)

            // 色一覧を横スクロール、上下に余白
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if mode == .simple {
                        ForEach(simpleColors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: itemSize, height: itemSize)
                                .overlay(
                                    Circle().stroke(color == selectedSimple ? Color.accentColor : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture { selectedSimple = color }
                        }
                        // カラーピッカー追加
                        ColorPicker("", selection: $customSimpleColor)
                            .labelsHidden()
                            .frame(width: itemSize, height: itemSize)
                            .clipShape(Circle())
                            .onChange(of: customSimpleColor) { new in
                                selectedSimple = new
                            }
                    } else {
                        ForEach(gradientPalettes.indices, id: \.self) { i in
                            let grad = gradientPalettes[i]
                            Circle()
                                .fill(LinearGradient(gradient: Gradient(colors: grad), startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: itemSize, height: itemSize)
                                .overlay(
                                    Circle().stroke(grad == selectedGradient ? Color.accentColor : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture { selectedGradient = grad }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
    }
}

// MARK: — プレビュー設定

#if DEBUG
struct ColorControlsView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var mode: ColorMode = .simple
        @State private var simpleColor: Color = .init(red: 0.94, green: 0.78, blue: 0.80)
        @State private var gradient: [Color] = [Color(red: 0.94, green: 0.78, blue: 0.80), Color(red: 0.96, green: 0.90, blue: 0.76)]
        var body: some View {
            ColorControlsView(
                mode: $mode,
                selectedSimple: $simpleColor,
                selectedGradient: $gradient
            )
            .padding()
            .previewLayout(.sizeThatFits)
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
#endif
