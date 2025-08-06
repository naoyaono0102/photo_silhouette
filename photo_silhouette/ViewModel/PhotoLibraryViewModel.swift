//
//  PhotoLibraryViewModel.swift
//  photo-compressor
//
//  Created by 尾野順哉 on 2025/04/13.
//

import Photos
import SwiftUI

class PhotoLibraryViewModel: ObservableObject {
    @Published var albums: [AlbumInfo] = []
    @Published var assets: [PHAsset] = []
    
    init() {
        requestAuthorizationAndFetchAlbums()
    }
    
    private func requestAuthorizationAndFetchAlbums() {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized || status == .limited {
                DispatchQueue.main.async {
                    self.albums = self.fetchAlbums()
                    // 初期アルバムの自動設定（例: タイトルに「最近」が含まれているアルバム）
                    if let defaultAlbum = self.albums.first(where: { $0.title.contains("最近") }) ?? self.albums.first {
                        self.loadAssets(for: defaultAlbum)
                    }
                }
            } else {
                print("❌ アクセス拒否")
            }
        }
    }
    
    private func fetchAlbums() -> [AlbumInfo] {
        var resultAlbums: [AlbumInfo] = []
        
        // Smart Albums (システムアルバム)
        let smartSubtypes: [PHAssetCollectionSubtype] = [
            .smartAlbumUserLibrary,
            .smartAlbumFavorites,
            .smartAlbumSelfPortraits,
            .smartAlbumScreenshots
        ]
        for subtype in smartSubtypes {
            let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: subtype, options: nil)
            collections.enumerateObjects { collection, _, _ in
                if let info = self.createAlbumInfo(from: collection) {
                    resultAlbums.append(info)
                }
            }
        }
        
        // User Albums
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        userAlbums.enumerateObjects { collection, _, _ in
            if let info = self.createAlbumInfo(from: collection) {
                resultAlbums.append(info)
            }
        }
        
        return resultAlbums
    }
    
    private func createAlbumInfo(from collection: PHAssetCollection) -> AlbumInfo? {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let assetsFetchResult = PHAsset.fetchAssets(in: collection, options: options)
        if assetsFetchResult.count == 0 { return nil }
        
        var thumbnail: UIImage? = nil
        let imageManager = PHCachingImageManager()
        let targetSize = CGSize(width: 80, height: 80)
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        imageManager.requestImage(for: assetsFetchResult.firstObject!, targetSize: targetSize, contentMode: .aspectFill, options: requestOptions) { image, _ in
            thumbnail = image
        }
        
        return AlbumInfo(id: collection.localIdentifier,
                         title: collection.localizedTitle ?? "Untitled",
                         count: assetsFetchResult.count,
                         thumbnail: thumbnail,
                         collection: collection)
    }
    
    func loadAssets(for album: AlbumInfo?) {
        guard let album = album else { return }
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        let result = PHAsset.fetchAssets(in: album.collection, options: options)
        
        var fetchedAssets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            fetchedAssets.append(asset)
        }
        DispatchQueue.main.async {
            self.assets = fetchedAssets
        }
    }
}


//
//// プレビュー用テストデータ
// extension PhotoLibraryViewModel {
//    static var preview: PhotoLibraryViewModel {
//        let mock = PhotoLibraryViewModel()
//        mock.albums = [
//            AlbumInfo(id: "1", title: "Mock Album 1", count: 12, thumbnail: nil, collection: PHAssetCollection()),
//            AlbumInfo(id: "2", title: "Mock Album 2", count: 34, thumbnail: nil, collection: PHAssetCollection())
//        ]
//        return mock
//    }
// }
