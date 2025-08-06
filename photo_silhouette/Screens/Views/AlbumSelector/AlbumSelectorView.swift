//
//  AlbumSelectorView.swift
//  photo-compressor
//
//  Created by 尾野順哉 on 2025/04/14.
//

import Photos
import SwiftUI

// アルバム選択用のシート
struct AlbumSelectorView: View {
    let albums: [AlbumInfo]
    @Binding var selectedAlbum: AlbumInfo?
    @Environment(\.dismiss) private var dismiss // dismiss用の環境変数

    var body: some View {
        NavigationView {
            List(albums) { album in
                Button(action: {
                    selectedAlbum = album
                    dismiss() // シートを閉じる
                }) {
                    HStack {
                        if let thumbnail = album.thumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipped()
                        } else {
                            Color.gray
                                .frame(width: 50, height: 50)
                        }
                        VStack(alignment: .leading) {
                            Text(album.title)
                                .foregroundColor(Color("TextColor"))
                            Text("\(album.count) ")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("ALBUM_SELECTION")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AlbumSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyAlbum = AlbumInfo(id: "1", title: "最近の項目", count: 10, thumbnail: nil, collection: dummyPHAssetCollection())
        AlbumSelectorView(albums: [dummyAlbum], selectedAlbum: .constant(dummyAlbum))
    }
}

/// ダミー用のPHAssetCollection（プレビュー用）
/// ※ プレビューで PHAssetCollection を生成するのは難しいため、実際のデータを確認する場合は実機またはシミュレーターでご確認ください。
func dummyPHAssetCollection() -> PHAssetCollection {
    // PHAssetCollection.fetchAssetCollections(with:options:) を使って取得可能な先頭のコレクションを返す
    let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
    guard let collection = collections.firstObject else {
        fatalError("No album available")
    }
    return collection
}
