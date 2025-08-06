//
//  SavePopupView.swift
//  white_frame
//
//  Created by 尾野順哉 on 2025/07/15.
//

import SwiftUI

// MARK: — 保存ポップアップView

struct SavePopupView<Preview: View>: View {
    let onSave: () -> Void
    let onShare: () -> Void
    let onClose: () -> Void
    let preview: Preview
    
    init(
        onSave: @escaping () -> Void,
        onShare: @escaping () -> Void,
        onClose: @escaping () -> Void,
        @ViewBuilder preview: () -> Preview
    ) {
        self.onSave = onSave
        self.onShare = onShare
        self.onClose = onClose
        self.preview = preview()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // ヘッダー
            HStack {
                Text("保存").font(.headline)
                Spacer()
                Button(action: {
                    withAnimation { onClose() }
                }) {
                    Image(systemName: "xmark")
                }
            }
            .padding(.horizontal)
            
            // 画像
            preview
                .cornerRadius(8)
                .padding(.horizontal)
                .allowsHitTesting(false)
                .background(.gray)
            
            // 保存・共有ボタン
            HStack(spacing: 40) {
                Spacer()
                Button(action: onSave) {
                    VStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down")
                        Text("保存")
                    }
                }
                Spacer()
                Button(action: onShare) {
                    VStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("共有")
                    }
                }
                Spacer()
            }
            .padding(.bottom)
        }
        .padding(.top)
    }
}
