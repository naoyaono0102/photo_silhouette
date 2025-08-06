//
//  Untitled.swift
//  video-compressor
//
//  Created by 尾野順哉 on 2025/04/29.
//

import SwiftUI
import UIKit

// MARK: — 共有シートのラッパー（変更不要）
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController,
                                context: Context) {}
}
