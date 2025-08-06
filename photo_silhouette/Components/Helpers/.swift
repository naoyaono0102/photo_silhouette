//
//  Formatters.swift
//  video-compressor
//
//  Created by 尾野順哉 on 2025/04/29.
//

import Foundation

///// ビットレート表示用ヘルパー
//enum Formatters {
//    static func bitrateString(from mbps: Double) -> String {
//        if mbps >= 1.0 {
//            return String(format: "%.1f Mbps", mbps)
//        } else {
//            return String(format: "%.0f kbps", mbps * 1000)
//        }
//    }
//}

enum Formatters {
    /// 1024-based file size: bytes → “123 KB” or “1.2 MB”
    static func fileSizeString(_ bytes: Int) -> String {
        let b = Double(bytes)
        let kb = b / 1_024.0
        if kb < 1 {
            return String(format: "%.0f B", b)
        } else if kb < 1_024 {
            return String(format: "%.0f KB", kb)
        } else {
            let mb = kb / 1_024.0
            return String(format: "%.1f MB", mb)
        }
    }
    
    /// decimal bitrate: bytes & duration → “123 kbps” or “1.2 Mbps”
    /// (we still divide bits by 1_000_000 to get Mbps)
    static func bitrateString(bytes: Int, duration: TimeInterval) -> String {
        guard duration > 0 else { return "–" }
        let bits = Double(bytes) * 8.0
        let mbps = bits / duration / 1_000_000.0
        if mbps >= 1 {
            return String(format: "%.1f Mbps", mbps)
        } else {
            let kbps = mbps * 1_000
            return String(format: "%.0f kbps", kbps)
        }
    }
}
