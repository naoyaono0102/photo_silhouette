//
//  PlayerViewController.swift
//  video-compressor
//
//  Created by 尾野順哉 on 2025/04/29.
//

import SwiftUI
import UIKit

/// UIKit の UIImagePickerController を SwiftUI から呼び出すラッパー
struct ImagePicker: UIViewControllerRepresentable {
    /// カメラ or フォトライブラリを使い分けるための sourceType
    enum SourceType {
        case camera
        case photoLibrary
        
        var uiImagePickerSourceType: UIImagePickerController.SourceType {
            switch self {
            case .camera: return .camera
            case .photoLibrary: return .photoLibrary
            }
        }
    }
    
    @Environment(\.presentationMode) private var presentationMode
    let sourceType: SourceType
    /// 撮影・選択が終わったときに呼ばれるクロージャ
    let onImagePicked: (UIImage) -> Void
    
    // UIKit の UIImagePickerController を生成
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType.uiImagePickerSourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false  // 必要に応じて true にして編集可にできる
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // 特に更新は不要
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// Coordinator：UIImagePicker の delegate を受け取る
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        // 撮影（またはフォトライブラリ選択）が終了したとき
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            // オリジナルの画像を取得する
            if let uiImage = info[.originalImage] as? UIImage {
                parent.onImagePicked(uiImage)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        // キャンセルされたとき
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
