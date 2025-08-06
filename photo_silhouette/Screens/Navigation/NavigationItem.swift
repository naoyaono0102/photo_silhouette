//
//  Untitled.swift
//  ToDoList
//
//  Created by 尾野順哉 on 2025/03/21.
//

import Photos
import UIKit

// 画面遷移の情報
struct NavigationItem: Hashable {
    let id: ScreenID
    
    // PHOTO_EDITOR へ渡したい情報を optional プロパティとして追加
    let asset: PHAsset?          // アルバムから選んだとき用
    let capturedUIImage: UIImage? // カメラ撮影直後に渡すとき用
    
    // ───────────────────────────────────────────────────
    // 〈新規〉“ペイロード無し”用イニシャライザ
    // どの画面にも渡すデータがない場合はこちらを使う
    init(id: ScreenID) {
        self.id = id
        self.asset = nil
        self.capturedUIImage = nil
    }
    
    // 〈既存〉PHAsset を渡したいとき用
    init(id: ScreenID, asset: PHAsset) {
        self.id = id
        self.asset = asset
        self.capturedUIImage = nil
    }
    
    // 〈既存〉UIImage を渡したいとき用
    init(id: ScreenID, capturedUIImage: UIImage) {
        self.id = id
        self.capturedUIImage = capturedUIImage
        self.asset = nil
    }
}
