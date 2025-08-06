//
//  InterstitialViewModel.swift
//  photo-compressor
//
//  Created by 尾野順哉 on 2025/04/20.
//

import GoogleMobileAds

class InterstitialViewModel: NSObject, ObservableObject, FullScreenContentDelegate {
    private var interstitialAd: InterstitialAd?
    /// 広告が閉じられたあとに呼ばれるコールバック（View側で設定する）
    var onAdDismissed: (() -> Void)? = nil
    
    func loadAd() async {
        print("====全画面広告の読み込み処理実施====")
        do {
            interstitialAd = try await InterstitialAd.load(
                with: "ca-app-pub-3940256099942544/4411468910", // 検証用
//                with: "ca-app-pub-2366369828485169/8247195023", // 本番用
                request: Request())
            // [START set_the_delegate]
            interstitialAd?.fullScreenContentDelegate = self
            // [END set_the_delegate]
        } catch {
            print("Failed to load interstitial ad with error: \(error.localizedDescription)")
        }
    }

    // [END load_ad]
    
    // [START show_ad]
    func showAd() {
        print("====全画面広告の表示====")
        guard let interstitialAd else {
            print("⚠️ Ad wasn't ready. Show fallback immediately.")

            // 広告がない場合でも即時に完了通知を送る
            DispatchQueue.main.async {
                self.onAdDismissed?()
            }
            return
        }

        interstitialAd.present(from: nil)
    }

    // [END show_ad]
    
    // MARK: - GADFullScreenContentDelegate methods
    
    // [START ad_events]
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }
    
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }
    
    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        print("\(#function) called")
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }
    
    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("====adDidDismissFullScreenContent====")
        print("\(#function) called")
        // Clear the interstitial ad.
        interstitialAd = nil
        
        // 広告閉じたあとにViewに通知
        DispatchQueue.main.async {
            self.onAdDismissed?()
        }
    }
    // [END ad_events]
}
