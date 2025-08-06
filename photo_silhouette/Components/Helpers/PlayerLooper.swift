//
//  PlayerLooper.swift
//  video-speed-converter
//
//  Created by 尾野順哉 on 2025/05/10.
//

import AVFoundation
import Combine
import Photos

final class PlayerLooper: ObservableObject {
    @Published var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var statusObserver: NSKeyValueObservation?
    private var desiredRate: Float = 1.0
    
    init(asset: PHAsset) {
        let opts = PHVideoRequestOptions()
        opts.isNetworkAccessAllowed = true
        
        PHImageManager.default()
            .requestPlayerItem(forVideo: asset, options: opts) { [weak self] item, _ in
                guard let self, let item else { return }
                let queue = AVQueuePlayer(playerItem: item)
                let loop = AVPlayerLooper(player: queue, templateItem: item)
                
                DispatchQueue.main.async {
                    self.player = queue
                    self.looper = loop
                    queue.play()
                    // KVO で “再生中” を監視し、再開時に rate を再適用
                    self.statusObserver = queue.observe(\.timeControlStatus, options: [.new]) { queue, _ in
                        if queue.timeControlStatus == .playing {
                            queue.rate = self.desiredRate
                        }
                    }
                }
            }
    }
    
    /// 速度を更新（View から呼び出す）
    func updateRate(to rate: Float) {
        desiredRate = rate
        player?.rate = rate
    }
}
