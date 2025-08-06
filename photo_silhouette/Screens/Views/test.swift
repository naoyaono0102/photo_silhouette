//
//  test.swift
//  photo-compressor
//
//  Created by 尾野順哉 on 2025/04/16.
//

import SwiftUI

struct test: View {
    var isSaving: Bool = false
    var body: some View {
        if isSaving {
            ProgressView("保存中...")
                .padding(30)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 10)
        } else {
            Text("保存しました")
                .padding(30)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 10)
                .transition(.opacity)
        }
    }
}

#Preview {
    test()
}
