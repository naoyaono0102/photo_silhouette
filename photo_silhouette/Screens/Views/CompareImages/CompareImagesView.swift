//
//  CompareImagesView.swift
//  photo-compressor
//
//  Created by 尾野順哉 on 2025/04/18.
//

import SwiftUI

struct CompareImagesView: View {
    let originalImages: [UIImage]
    let compressedImages: [UIImage]
    let originalSizes: [String]
    let compressedSizes: [String]
    let originalDims: [String]
    let compressedDims: [String]

    @State private var selection: Int = 0

    var body: some View {
        VStack {
            // Header with back button handled by NavigationStack
            TabView(selection: $selection) {
                ForEach(originalImages.indices, id: \ .self) { index in
                    VStack(spacing: 16) {
                        // Before section
                        VStack(alignment: .center, spacing: 6) {
                            Text("Before \(originalDims[index])  \(originalSizes[index])")
                                .font(.subheadline)
                            Image(uiImage: originalImages[index])
                                .resizable()
                                .aspectRatio(contentMode: .fit)
//                                .frame(maxHeight: 300)
                                .border(Color.gray.opacity(0.5), width: 1)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        // After section
                        VStack(alignment: .center, spacing: 6) {
                            Text("After \(compressedDims[index])  \(compressedSizes[index])")
                                .font(.subheadline)
                            Image(uiImage: compressedImages[index])
                                .resizable()
                                .aspectRatio(contentMode: .fit)
//                                .frame(maxHeight: 300)
                                .border(Color.gray.opacity(0.5), width: 1)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                        .background(.blue)
                    }
                    .padding()
                    .padding(.bottom, 20)
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        }
//        .navigationTitle("画像比較")
        .navigationBarSetting(title: "IMAGE_COMPARISON", isVisible: true)
        .navigationBarTitleDisplayMode(.inline)
    }
}
