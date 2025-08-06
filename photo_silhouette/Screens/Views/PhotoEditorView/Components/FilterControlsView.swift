//
//  FilterControlsView.swift
//  white_frame
//
//  Created by 尾野順哉 on 2025/07/14.
//

import SwiftUI
import CoreImage

struct FilterControlsView: View {
    @Binding var selectedFilter: FilterType
    let originalImage: UIImage?
    
    // MARK: – thumbnail cache
    @State private var thumbnailCache: [FilterType: UIImage] = [:]
    @State private var isLoading = false
    
    // サムネイルの直径
    private let thumbSize: CGFloat = 56
    // セルの余白
    private let paddingSize: CGFloat = 4
    // 枠線の太さ
    private let borderWidth: CGFloat = 2
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(FilterType.allCases) { filter in
                    VStack(spacing: 6) {
                        // サムネイル
                        Group {
                            if let thumb = thumbnailCache[filter] {
                                Image(uiImage: thumb)
                                    .resizable()
                            } else {
                                Circle()
                                    .fill(Color.secondary.opacity(0.3))
                            }
                        }
                        .scaledToFill()
                        .frame(width: thumbSize, height: thumbSize)
                        .clipShape(Circle())
//                        if let img = originalImage {
//                            Image(uiImage: thumbnail(for: filter, base: img))
//                                .resizable()
//                                .scaledToFill()
//                                .frame(width: thumbSize, height: thumbSize)
//                                .clipShape(Circle())
//                        } else {
//                            Circle()
//                                .fill(Color.secondary.opacity(0.3))
//                                .frame(width: thumbSize, height: thumbSize)
//                        }
                        
                        // フィルター名
                        Text(filter.displayName)
                            .font(.caption2)
                    }
                    // セル全体の余白
                    .padding(paddingSize)
                    // 選択中のみ枠線を描画 (strokeBorder で内側に均一に描画)
                    .overlay(
                        Rectangle()
                            .strokeBorder(
                                filter == selectedFilter ? Color("MainAccentColor") : Color.clear,
                                lineWidth: borderWidth
                            )
                    )
                    .onTapGesture { selectedFilter = filter }
                }
            }
            .padding(.horizontal)
        }
        .onAppear(perform: generateThumbnailsIfNeeded)
    }
    
    /// Generate thumbnails only once, on a downsampled base image
    private func generateThumbnailsIfNeeded() {
        guard !isLoading, thumbnailCache.isEmpty, let base = originalImage else { return }
        isLoading = true
        
        let targetSize = CGSize(width: thumbSize * 2, height: thumbSize * 2)
        // Create a small base thumbnail to speed up filtering
        let baseThumb = downsample(image: base, to: targetSize)
        
        DispatchQueue.global(qos: .userInitiated).async {
            var newCache: [FilterType: UIImage] = [:]
            let ciContext = CIContext(options: nil)
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            
            for filter in FilterType.allCases {
                // Apply filter to the small base thumbnail
                let filtered = apply(filter: filter, to: baseThumb, context: ciContext)
                
                // Center-crop & ensure exact target size
                let thumb = renderer.image { _ in
                    let scale = max(
                        targetSize.width / filtered.size.width,
                        targetSize.height / filtered.size.height
                    )
                    let newSize = CGSize(
                        width: filtered.size.width * scale,
                        height: filtered.size.height * scale
                    )
                    let origin = CGPoint(
                        x: (targetSize.width - newSize.width) / 2,
                        y: (targetSize.height - newSize.height) / 2
                    )
                    filtered.draw(in: CGRect(origin: origin, size: newSize))
                }
                newCache[filter] = thumb
            }
            
            DispatchQueue.main.async {
                thumbnailCache = newCache
                isLoading = false
            }
        }
    }
    
    /// Downsample a UIImage to the given size
    private func downsample(image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let aspect = max(size.width / image.size.width,
                             size.height / image.size.height)
            let newSize = CGSize(width: image.size.width * aspect,
                                 height: image.size.height * aspect)
            let origin = CGPoint(
                x: (size.width - newSize.width) / 2,
                y: (size.height - newSize.height) / 2
            )
            image.draw(in: CGRect(origin: origin, size: newSize))
        }
    }
    
    /// Apply a CI filter to a UIImage
    private func apply(filter: FilterType, to image: UIImage, context: CIContext) -> UIImage {
        guard let ciName = filter.ciName,
              let ciInput = CIImage(image: image),
              let filterObj = CIFilter(name: ciName) else { return image }
        filterObj.setValue(ciInput, forKey: kCIInputImageKey)
        if filter == .sepia {
            filterObj.setValue(0.8, forKey: kCIInputIntensityKey)
        }
        guard let output = filterObj.outputImage,
              let cgImg = context.createCGImage(output, from: output.extent) else {
            return image
        }
        return UIImage(cgImage: cgImg, scale: image.scale, orientation: image.imageOrientation)
    }
    
    /// フィルター適用 → 中央クロップ & リサイズ の順序で処理し、プレビューと同じ見た目を保証
    private func thumbnail(for filter: FilterType, base: UIImage) -> UIImage {
        // 1) フル解像度でフィルターを適用
        let filteredFull: UIImage = {
            guard let ciName = filter.ciName,
                  let ciInput = CIImage(image: base)
            else { return base }
            let filterObj = CIFilter(name: ciName)
            filterObj?.setValue(ciInput, forKey: kCIInputImageKey)
            if filter == .sepia {
                filterObj?.setValue(0.8, forKey: kCIInputIntensityKey)
            }
            let context = CIContext()
            if let output = filterObj?.outputImage,
               let cgimg = context.createCGImage(output, from: output.extent) {
                return UIImage(cgImage: cgimg, scale: base.scale, orientation: base.imageOrientation)
            }
            return base
        }()
        
        // 2) フィルタ済み画像を中央クロップ & リサイズ
        let targetSize = CGSize(width: thumbSize * 2, height: thumbSize * 2)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            let scale = max(targetSize.width / filteredFull.size.width,
                            targetSize.height / filteredFull.size.height)
            let newSize = CGSize(width: filteredFull.size.width * scale,
                                 height: filteredFull.size.height * scale)
            let origin = CGPoint(x: (targetSize.width - newSize.width) / 2,
                                 y: (targetSize.height - newSize.height) / 2)
            filteredFull.draw(in: CGRect(origin: origin, size: newSize))
        }
    }
}
