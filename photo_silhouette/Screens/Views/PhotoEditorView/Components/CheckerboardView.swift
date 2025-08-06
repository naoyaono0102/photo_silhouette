//
//  CheckboardView.swift
//  photo_silhouette
//
//  Created by 尾野順哉 on 2025/08/06.
//

import SwiftUI

// MARK: — Checkerboard Background

struct CheckerboardView: View {
    /// タイル１辺のサイズ
    let squareSize: CGFloat = 12
    var body: some View {
        GeometryReader { geo in
            let rows = Int(ceil(geo.size.height / squareSize))
            let cols = Int(ceil(geo.size.width / squareSize))
            ZStack {
                ForEach(0..<rows, id: \.self) { row in
                    ForEach(0..<cols, id: \.self) { col in
                        Rectangle()
                            .fill((row + col).isMultiple(of: 2)
                                ? Color.white
                                : Color.gray.opacity(0.4))
                            .frame(width: squareSize, height: squareSize)
                            .position(x: CGFloat(col) * squareSize + squareSize / 2,
                                      y: CGFloat(row) * squareSize + squareSize / 2)
                    }
                }
            }
        }
    }
}

#Preview {
    CheckerboardView()
}
