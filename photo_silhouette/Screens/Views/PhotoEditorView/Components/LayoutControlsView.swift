//
//  LayoutControlsView.swift
//  white_frame
//
//  Created by 尾野順哉 on 2025/07/11.
//

import SwiftUI

struct LayoutControlsView: View {
    @Binding var selectedLayout: FrameLayout

    // 実際の写真部分とフレーム外形のサイズ定義
    private let pictureSizes: [FrameLayout: CGSize] = [
        .mini: CGSize(width: 46, height: 62),
        .square: CGSize(width: 62, height: 62),
        .wide: CGSize(width: 99, height: 62),
    ]
    private let frameSizes: [FrameLayout: CGSize] = [
        .mini: CGSize(width: 54, height: 86),
        .square: CGSize(width: 72, height: 86),
        .wide: CGSize(width: 108, height: 86),
    ]

    var body: some View {
        HStack(spacing: 24) {
            ForEach(FrameLayout.allCases) { layout in
                let picSize = pictureSizes[layout]!
                let frmSize = frameSizes[layout]!

                Spacer()
                HStack(spacing: 0) {
                    LayoutOptionView(
                        pictureSize: picSize,
                        frameSize: frmSize,
                        isSelected: layout == selectedLayout
                    ) {
                        selectedLayout = layout
                    }
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

private struct LayoutOptionView: View {
    let pictureSize: CGSize
    let frameSize: CGSize
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        ZStack {
            // フレーム（白、角丸なし）
            Rectangle()
                .fill(Color.white)
                .frame(width: frameSize.width, height: frameSize.height)
                .overlay(
                    Rectangle()
                        .stroke(isSelected ? Color("MainAccentColor") : .clear, lineWidth: 2)
                )

            // 写真部分（グレー）を上寄せ
            Rectangle()
//                .fill(Color.secondary.opacity(0.4))
                .fill(Color("ImageColor"))
                .frame(width: pictureSize.width, height: pictureSize.height)
                .offset(
                    y: -((frameSize.height - pictureSize.height) * 0.25)
                )
        }
        .contentShape(Rectangle()) // タップ領域をフレーム全体に
        .onTapGesture(perform: action)
    }
}
