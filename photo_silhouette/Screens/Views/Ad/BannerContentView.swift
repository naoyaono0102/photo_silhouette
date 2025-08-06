//
//  GoogleAdmob.swift
//  ToDoList
//
//  Created by 尾野順哉 on 2025/03/27.
//

import GoogleMobileAds
import SwiftUI

// Google Admob Banner Ad View
struct BannerContentView: View {
    // [START add_banner_to_view]

    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let adSize = currentOrientationAnchoredAdaptiveBanner(width: screenWidth)

        BannerViewContainer(adSize)
            .frame(width: screenWidth, height: adSize.size.height)
            .onAppear {
                print("screenWidth: \(screenWidth)")
                print("adSize: \(adSize)")
            }
    }
}

struct BannerContentView_Previews: PreviewProvider {
    static var previews: some View {
//        BannerContentView(navigationTitle: "Banner")
        BannerContentView()
    }
}

// [START create_banner_view]
private struct BannerViewContainer: UIViewRepresentable {
    let adSize: AdSize

    init(_ adSize: AdSize) {
        self.adSize = adSize
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.addSubview(context.coordinator.bannerView)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.bannerView.adSize = adSize
    }

    func makeCoordinator() -> BannerCoordinator {
        return BannerCoordinator(self)
    }

    // [END create_banner_view]

    // [START create_banner]
    class BannerCoordinator: NSObject, BannerViewDelegate {
        @MainActor
        private(set) lazy var bannerView: BannerView = {
            let banner = BannerView(adSize: parent.adSize)
            banner.adUnitID = "ca-app-pub-3940256099942544/2435281174" // 検証用
//            banner.adUnitID = "ca-app-pub-2366369828485169/8981692191" // 本番用
            banner.load(Request())
            banner.delegate = self
            return banner
        }()

        let parent: BannerViewContainer

        init(_ parent: BannerViewContainer) {
            self.parent = parent
        }

        // [END create_banner]

        // MARK: - GADBannerViewDelegate methods

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("DID RECEIVE AD.")

// 広告ネットワークの情報を確認
#if DEBUG
            if let responseInfo = bannerView.responseInfo {
                // adNetworkInfoArrayから広告ネットワークの詳細情報を取得
                for networkInfo in responseInfo.adNetworkInfoArray {
                    print("Description: \(networkInfo.description ?? "No description")")
                    print("Latency: \(networkInfo.latency ?? -1)")
                    print("Error: \(networkInfo.error?.localizedDescription ?? "No error")")
                }
            }
#endif
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("FAILED TO RECEIVE AD: \(error.localizedDescription)")

            // エラー情報を詳細に表示
            if let responseInfo = bannerView.responseInfo {
                // エラー詳細を表示
                for networkInfo in responseInfo.adNetworkInfoArray {
                    // `networkName`, `errorCode`, `errorMessage` は正しくないプロパティ
                    // `description` と `error` プロパティを使用する
                    print("== エラー詳細を表示 ==")
                    print("Network Description: \(networkInfo.description)")
                    print("Error: \(networkInfo.error?.localizedDescription ?? "No error")")
                }
            }
        }
    }
}
