//
//  MultiSelectableAssetThumbnail.swift
//  photo-compressor
//
//  Created by 尾野順哉 on 2025/04/16.
//

import Photos
import SwiftUI

struct MultiSelectableAssetThumbnail: View {
    let asset: PHAsset
    let isSelected: Bool
    let onToggle: () -> Void

    @State private var fileSize: String = ""
    @State private var dimensions: String = ""
    @State private var fileType: String = ""

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottomTrailing) {
                // 1) GeometryReader で取得したサイズで「必ずぴったり」埋める
                AssetThumbnail(asset: asset)
                    .scaledToFill() // アスペクトは fill
                    .frame(width: proxy.size.width,
                           height: proxy.size.height) // セルサイズに明示的に固定
                    .clipped() // はみ出しをカット
                    .allowsHitTesting(false) // ◯ボタンが反応しなくなるのを防ぐ
//                    .overlay(
//                        // 左上情報
//                        HStack {
//                            Text(dimensions)
//                                .font(.caption2)
//                                .foregroundColor(.white)
//                                .padding(.horizontal, 4)
//                                .padding(.vertical, 2)
//                                .background(Color.black.opacity(0.5))
//                                .cornerRadius(4)
//                            Spacer()
//                            Text(fileSize)
//                                .font(.caption2)
//                                .foregroundColor(.white)
//                                .padding(.horizontal, 4)
//                                .padding(.vertical, 2)
//                                .background(Color.black.opacity(0.5))
//                                .cornerRadius(4)
//                        }
//                        .padding(4),
//                        alignment: .topLeading
//                    )

                // 2) ボタンも ZStack がそのままセルサイズなので、常に右下に固定
                Button(action: onToggle) {
                    ZStack {
                        if isSelected {
                            Image(systemName: "checkmark.circle")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                                .shadow(radius: 1)
                        }

                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(isSelected ? .blue : .white)
                            .shadow(radius: 1)
                    }
                }
                .padding(6)
                .buttonStyle(PlainButtonStyle())
            }
            // 3) GeometryReader の中に ZStack を置いたら、外側での .frame は不要になります
        }
        .onAppear {
            // 容量取得
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                if let data {
                    fileSize = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
                }
            }
            // 解像度情報
            dimensions = "\(asset.pixelWidth) x \(asset.pixelHeight)"
            // ファイル形式
            if let resource = PHAssetResource.assetResources(for: asset).first {
                let uti = resource.uniformTypeIdentifier
                if let ut = UTType(uti), let ext = ut.preferredFilenameExtension {
                    fileType = ext.uppercased()
                } else {
                    fileType = uti
                }
            }
        }
    }
}

//

//
//  MultiSelectableAssetThumbnail.swift
//  photo-compressor
//
//  Created by 尾野順哉 on 2025/04/16.
//

// import Photos
// import SwiftUI
//
// struct MultiSelectableAssetThumbnail: View {
//    let asset: PHAsset
//    let isSelected: Bool
//    let onToggle: () -> Void
//
//    var body: some View {
//        GeometryReader { geometry in
//            ZStack(alignment: .bottomTrailing) {
//                // セル全体のサイズに合わせて画像を表示
//                AssetThumbnail(asset: asset)
////                    .scaledToFill()
////                    .frame(width: geometry.size.width, height: geometry.size.height)
////                    .clipped()
//                // 右下に固定するオーバーレイボタン
//                Button(action: onToggle) {
//                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
//                        .resizable()
//                        // 表示サイズは変えず、タップ領域用に余裕を持たせるために背景用フレームを追加
//                        .frame(width: 50, height: 50)
//                        .foregroundColor(isSelected ? .blue : .white)
//                        .shadow(radius: 1)
//                }
//                // タップ領域を大きくするためにインビジブルな背景（透明）を追加
//                .padding(6)
////                .frame(width: 100, height: 100, alignment: .center)
//                .frame(width: 100, height: 100)
//                .background(Color.red)
//                .contentShape(Rectangle()) // タップ領域を明示的に設定
//                .zIndex(1) // 常に最前面に表示する
//            }
//        }
//        // セルが常に正方形になるようにする
//        .aspectRatio(1, contentMode: .fit)
//    }
// }

#if DEBUG
struct MultiSelectableAssetThumbnail_Previews: PreviewProvider {
    static var previews: some View {
        // プレビュー用の仮の PHAsset を生成するのが困難な場合は、代わりに固定サイズのテストビューとしてご確認ください。
        MultiSelectableAssetThumbnail(asset: PHAsset(), isSelected: true, onToggle: {})
            .frame(width: 100, height: 100)
    }
}
#endif
