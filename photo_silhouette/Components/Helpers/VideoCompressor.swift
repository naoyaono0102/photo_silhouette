//
//  VideoCompressor.swift
//  video-compressor
//
//  Created by 尾野順哉 on 2025/04/29.
//

import AVFoundation
import AVKit
import Photos
import SwiftUI

/// ヘルパー：単一動画を圧縮する
class VideoCompressor {
    /// asset → 出力URL に向けて圧縮／パススルー
    static func compress(
        asset: PHAsset,
        resolutionPercent pPercent: Double,
        bitratePercent bPercent: Double,
        includeAudio: Bool,
        fileType: AVFileType,
        preset: String = AVAssetExportPresetHighestQuality,
        to outputURL: URL,
        progressHandler: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        print("==== 圧縮処理開始 =====")
        print(">> プリセット名：\(preset)")

        let opts = PHVideoRequestOptions()
        opts.isNetworkAccessAllowed = true
        PHImageManager.default().requestAVAsset(forVideo: asset, options: opts) { avAsset, _, _ in
            guard let sourceAsset = avAsset else {
                return completion(.failure(NSError(domain: "compress", code: -1)))
            }

            // オーディオ除去時：動画トラックのみの Composition を作成
            var exportAsset: AVAsset = sourceAsset
            if !includeAudio {
                let composition = AVMutableComposition()
                guard let videoTrack = sourceAsset.tracks(withMediaType: .video).first,
                      let compTrack = composition.addMutableTrack(
                          withMediaType: .video,
                          preferredTrackID: kCMPersistentTrackID_Invalid
                      ) else {
                    return completion(.failure(NSError(domain: "compress", code: -2)))
                }
                do {
                    try compTrack.insertTimeRange(
                        CMTimeRange(start: .zero, duration: sourceAsset.duration),
                        of: videoTrack,
                        at: .zero
                    )
                    compTrack.preferredTransform = videoTrack.preferredTransform
                } catch {
                    return completion(.failure(error))
                }
                exportAsset = composition
            }

            // パススルー判定: プリセットが Passthrough または 解像度・ビットレート変更なし
            let isPassthrough = (preset == AVAssetExportPresetPassthrough) || (pPercent == 100 && bPercent == 100)

            // ビデオコンポジション準備（パススルーでない場合）
            var videoComposition: AVMutableVideoComposition?
            if !isPassthrough {
                guard let videoTrack = exportAsset.tracks(withMediaType: .video).first else {
                    return completion(.failure(NSError(domain: "compress", code: -3)))
                }
                let t0 = videoTrack.preferredTransform
                let natSize = videoTrack.naturalSize.applying(t0)
                let scale = CGFloat(pPercent / 100)

                // 偶数ピクセルに丸め
                let rawW = abs(natSize.width * scale)
                let rawH = abs(natSize.height * scale)
                let targetSize = CGSize(width: floor(rawW / 2) * 2, height: floor(rawH / 2) * 2)

                let comp = AVMutableVideoComposition()
                comp.renderSize = targetSize
                comp.frameDuration = CMTime(value: 1, timescale: Int32(videoTrack.nominalFrameRate))

                let instruction = AVMutableVideoCompositionInstruction()
                instruction.timeRange = CMTimeRange(start: .zero, duration: exportAsset.duration)
                let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)

                // 向き + スケール をそのまま適用
                let transform = t0.concatenating(CGAffineTransform(scaleX: scale, y: scale))
                layer.setTransform(transform, at: .zero)

                instruction.layerInstructions = [layer]
                comp.instructions = [instruction]
                videoComposition = comp
            }

            // エクスポートプリセット決定
            let presetNameToUse = isPassthrough ? AVAssetExportPresetPassthrough : preset

            // AVAssetExportSession の生成
            guard let exportSession = AVAssetExportSession(
                asset: exportAsset,
                presetName: presetNameToUse
            ) else {
                return completion(.failure(NSError(domain: "compress", code: -4)))
            }

            // ログ出力
            print("supportedFileTypes for preset \(presetNameToUse):", exportSession.supportedFileTypes)

            // videoComposition をセット
            if let comp = videoComposition {
                exportSession.videoComposition = comp
            }

            // 出力設定
            exportSession.outputURL = outputURL
            exportSession.outputFileType = fileType
            exportSession.shouldOptimizeForNetworkUse = true

            // ビットレート制限
            if !isPassthrough && (pPercent != 100 || bPercent != 100) {
                if let videoTrack = exportAsset.tracks(withMediaType: .video).first {
                    let origBps = Double(videoTrack.estimatedDataRate)
                    let areaRatio = pow(pPercent / 100, 2)
                    let targetBps = origBps * (bPercent / 100) * areaRatio
                    exportSession.fileLengthLimit = Int64(targetBps / 8.0 * exportAsset.duration.seconds)
                }
            }

            // 進捗監視
            DispatchQueue.main.async {
                let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { t in
                    progressHandler(Double(exportSession.progress))
                    if exportSession.progress >= 1.0 {
                        t.invalidate()
                    }
                }
                RunLoop.main.add(timer, forMode: .common)
            }

            // 実行
            exportSession.exportAsynchronously {
                DispatchQueue.main.async {
                    switch exportSession.status {
                    case .completed:
                        completion(.success(outputURL))
                    default:
                        completion(.failure(exportSession.error ?? NSError(domain: "export", code: -5)))
                    }
                }
            }
        }
    }
}

/// ヘルパー：単一動画を圧縮する
// class VideoCompressor {
//    /// asset → 出力URL に向けて圧縮／パススルー
//    static func compress(
//        asset: PHAsset,
//        resolutionPercent pPercent: Double,
//        bitratePercent bPercent: Double,
//        includeAudio: Bool,
//        fileType: AVFileType,
//        preset: String = AVAssetExportPresetHighestQuality,
//        to outputURL: URL,
//        progressHandler: @escaping (Double) -> Void,
//        completion: @escaping (Result<URL, Error>) -> Void
//    ) {
//        print("==== 圧縮処理開始 =====")
//        print(">> プリセット名：\(preset)")
//
//        let opts = PHVideoRequestOptions()
//        opts.isNetworkAccessAllowed = true
//        PHImageManager.default().requestAVAsset(forVideo: asset, options: opts) { avAsset, _, _ in
//            guard let sourceAsset = avAsset else {
//                return completion(.failure(NSError(domain: "compress", code: -1)))
//            }
//
//            // オーディオ除去時：動画のみの AVAsset を作成
//            var exportAsset: AVAsset = sourceAsset
//            if !includeAudio {
//                let composition = AVMutableComposition()
//                guard let videoTrack = sourceAsset.tracks(withMediaType: .video).first,
//                      let compTrack = composition.addMutableTrack(
//                          withMediaType: .video,
//                          preferredTrackID: kCMPersistentTrackID_Invalid
//                      ) else {
//                    return completion(.failure(NSError(domain: "compress", code: -2)))
//                }
//                do {
//                    try compTrack.insertTimeRange(
//                        CMTimeRange(start: .zero, duration: sourceAsset.duration),
//                        of: videoTrack,
//                        at: .zero
//                    )
//                    compTrack.preferredTransform = videoTrack.preferredTransform
//                } catch {
//                    return completion(.failure(error))
//                }
//                exportAsset = composition
//            }
//
//            // パススルー判定: ユーザー指定プリセット or 解像度・ビットレート変更なし
//            let passthroughByPreset = (preset == AVAssetExportPresetPassthrough)
//            let passthroughBySettings = (pPercent == 100 && bPercent == 100 && includeAudio)
//            let isPassthrough = passthroughByPreset || passthroughBySettings
//
//            // ビデオコンポジション準備（パススルー以外）
//            var videoComposition: AVMutableVideoComposition?
//            if !isPassthrough {
//                guard let videoTrack = exportAsset.tracks(withMediaType: .video).first else {
//                    return completion(.failure(NSError(domain: "compress", code: -3)))
//                }
//                let t0 = videoTrack.preferredTransform
//                let natSize = videoTrack.naturalSize.applying(t0)
//                let scale = CGFloat(pPercent / 100)
//
//                let targetSize = CGSize(
//                    width: abs(natSize.width * scale),
//                    height: abs(natSize.height * scale)
//                )
//
//                let comp = AVMutableVideoComposition()
//                comp.renderSize = targetSize
//                comp.frameDuration = CMTime(value: 1, timescale: Int32(videoTrack.nominalFrameRate))
//
//                let instruction = AVMutableVideoCompositionInstruction()
//                instruction.timeRange = CMTimeRange(start: .zero, duration: exportAsset.duration)
//                let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
//                layer.setTransform(
//                    t0.concatenating(CGAffineTransform(scaleX: scale, y: scale)),
//                    at: .zero
//                )
//                instruction.layerInstructions = [layer]
//                comp.instructions = [instruction]
//                videoComposition = comp
//            }
//
//            // エクスポートプリセット決定
//            let presetNameToUse = isPassthrough
//                ? AVAssetExportPresetPassthrough
//                : preset
//
//            // AVAssetExportSession の生成
//            guard let exportSession = AVAssetExportSession(
//                asset: exportAsset,
//                presetName: presetNameToUse
//            ) else {
//                return completion(.failure(NSError(domain: "compress", code: -4)))
//            }
//
//            // サポートされる出力ファイルタイプをログ出力
//            print("supportedFileTypes for preset \(presetNameToUse):", exportSession.supportedFileTypes)
//
//            // videoComposition をセット
//            if let comp = videoComposition {
//                exportSession.videoComposition = comp
//            }
//
//            // 出力設定
//            exportSession.outputURL = outputURL
//            exportSession.outputFileType = fileType
//            exportSession.shouldOptimizeForNetworkUse = true
//
//            // ビットレート制限（リサイズまたはビットレート変更がある場合のみ）
//            if !isPassthrough && (pPercent != 100 || bPercent != 100 || !includeAudio) {
//                if let videoTrack = exportAsset.tracks(withMediaType: .video).first {
//                    let origBps = Double(videoTrack.estimatedDataRate)
//                    let areaRatio = pow(pPercent / 100, 2)
//                    let targetBps = origBps * (bPercent / 100) * areaRatio
//                    exportSession.fileLengthLimit = Int64(targetBps / 8.0 * exportAsset.duration.seconds)
//                }
//            }
//
//            // 進捗監視
//            DispatchQueue.main.async {
//                let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { t in
//                    progressHandler(Double(exportSession.progress))
//                    if exportSession.progress >= 1.0 {
//                        t.invalidate()
//                    }
//                }
//                RunLoop.main.add(timer, forMode: .common)
//            }
//
//            // 実行
//            exportSession.exportAsynchronously {
//                DispatchQueue.main.async {
//                    switch exportSession.status {
//                    case .completed:
//                        completion(.success(outputURL))
//                    default:
//                        completion(.failure(exportSession.error ?? NSError(domain: "export", code: -5)))
//                    }
//                }
//            }
//        }
//    }
// }

/// ヘルパー：単一動画を圧縮する
// class VideoCompressor {
//    /// asset → 出力URL に向けて圧縮／パススルー
//    static func compress(
//        asset: PHAsset,
//        resolutionPercent pPercent: Double,
//        bitratePercent bPercent: Double,
//        includeAudio: Bool,
//        fileType: AVFileType,
//        preset: String = AVAssetExportPresetHighestQuality,
//        to outputURL: URL,
//        progressHandler: @escaping (Double) -> Void,
//        completion: @escaping (Result<URL, Error>) -> Void
//    ) {
//        print("==== 圧縮処理開始 =====")
//        print(">> プリセット名：\(preset)")
//
//        let opts = PHVideoRequestOptions()
//        opts.isNetworkAccessAllowed = true
//        PHImageManager.default().requestAVAsset(forVideo: asset, options: opts) { avAsset, _, _ in
//            guard let source = avAsset else {
//                return completion(.failure(NSError(domain: "compress", code: -1)))
//            }
//
//            // パススルー判定
//            let isPassthrough = pPercent == 100 && bPercent == 100 && includeAudio
//
//            // ここでセッションを作る
//            let export: AVAssetExportSession? = {
//                let presetNameToUse = isPassthrough
//                    ? AVAssetExportPresetPassthrough
//                    : preset
//                return AVAssetExportSession(asset: source, presetName: presetNameToUse)
//            }()
//
//            guard let exportSession = export else {
//                return completion(.failure(NSError(domain: "compress", code: -2)))
//            }
//
//            // ← ここで supportedFileTypes をプリント
//            print("supportedFileTypes for preset \(preset):", exportSession.supportedFileTypes)
//
//            // 以下、出力先や videoComposition／audioMix の設定…
//            exportSession.outputURL = outputURL
//            exportSession.outputFileType = fileType
//
//            let session: AVAssetExportSession? = {
//                if isPassthrough {
//                    return AVAssetExportSession(asset: source, presetName: AVAssetExportPresetPassthrough)
//                } else {
//                    // 回転・リサイズ＋ビットレート制限
//                    guard let videoTrack = source.tracks(withMediaType: .video).first else { return nil }
//                    let t0 = videoTrack.preferredTransform
//                    let nat = videoTrack.naturalSize.applying(t0)
//                    let p = CGFloat(pPercent / 100)
//                    let targetSize = CGSize(width: abs(nat.width * p), height: abs(nat.height * p))
//
//                    let comp = AVMutableVideoComposition()
//                    comp.renderSize = targetSize
//                    comp.frameDuration = CMTime(value: 1, timescale: Int32(videoTrack.nominalFrameRate))
//                    let instr = AVMutableVideoCompositionInstruction()
//                    instr.timeRange = CMTimeRange(start: .zero, duration: source.duration)
//                    let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
//                    layer.setTransform(t0.concatenating(.init(scaleX: p, y: p)), at: .zero)
//                    instr.layerInstructions = [layer]
//                    comp.instructions = [instr]
//
//                    let s = AVAssetExportSession(asset: source, presetName: preset)
//                    s?.videoComposition = comp
//                    return s
//                }
//            }()
//            guard let export = session else {
//                return completion(.failure(NSError(domain: "compress", code: -2)))
//            }
//            export.outputURL = outputURL
//            export.outputFileType = fileType
//            export.shouldOptimizeForNetworkUse = true
//            if !includeAudio {
//                export.audioMix = AVAudioMix()
//            }
//            // ビットレート制限（パススルー以外）
//            if pPercent != 100 || bPercent != 100 {
//                if let videoTrack = source.tracks(withMediaType: .video).first {
//                    let origBps = Double(videoTrack.estimatedDataRate)
//                    let areaRatio = pow(pPercent / 100, 2)
//                    let targetBps = origBps * (bPercent / 100) * areaRatio
//                    export.fileLengthLimit = Int64(targetBps / 8.0 * source.duration.seconds)
//                }
//            }
//
//            // 進捗監視
//            DispatchQueue.main.async {
//                let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { t in
//                    progressHandler(Double(export.progress))
//                    if export.progress >= 1.0 {
//                        t.invalidate()
//                    }
//                }
//                RunLoop.main.add(timer, forMode: .common)
//            }
//
//            export.exportAsynchronously {
//                DispatchQueue.main.async {
//                    switch export.status {
//                    case .completed: completion(.success(outputURL))
//                    default: completion(.failure(export.error ?? NSError(domain: "export", code: -3)))
//                    }
//                }
//            }
//        }
//    }
// }
