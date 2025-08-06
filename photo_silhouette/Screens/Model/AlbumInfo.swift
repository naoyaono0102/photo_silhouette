//
//  AlbumInfo.swift
//  photo-compressor
//
//  Created by 尾野順哉 on 2025/04/15.
//

import Photos
import UIKit

struct AlbumInfo: Identifiable, Equatable {
    let id: String
    let title: String
    let count: Int
    let thumbnail: UIImage?
    let collection: PHAssetCollection
}
