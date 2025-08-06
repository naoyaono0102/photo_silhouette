//
//  AssetThumbnail.swift
//  photo-compressor
//
//  Created by 尾野順哉 on 2025/04/14.
//

import Photos
import SwiftUI

// 各写真のサムネイルを表示する View
struct AssetThumbnail: View {
    let asset: PHAsset

    var body: some View {
        ImageThumbnailView(asset: asset)
    }
}

struct ImageThumbnailView: View {
    let asset: PHAsset
    @State private var image: UIImage? = nil

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
            } else {
                Color.gray
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        let manager = PHCachingImageManager()
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isSynchronous = false
        // リクエスト時のtargetSizeは適宜調整してください
        manager.requestImage(for: asset,
                             targetSize: CGSize(width: 300, height: 300),
                             contentMode: .aspectFill,
                             options: options) { result, _ in
            if let result {
                image = result
            }
        }
    }
}

struct AssetThumbnail_Previews: PreviewProvider {
    static var previews: some View {
        // プレビュー用に仮のPHAssetを利用する場合はダミー画像等で対応してください
        Text("AssetThumbnail Preview")
    }
}
