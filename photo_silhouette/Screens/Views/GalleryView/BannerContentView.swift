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
//    let navigationTitle: String
    
    // [START add_banner_to_view]
    var body: some View {
        GeometryReader { geometry in
            let adSize = currentOrientationAnchoredAdaptiveBanner(width: geometry.size.width)
            
            VStack(spacing: 0) {
                BannerViewContainer(adSize)
                    .frame(width: geometry.size.width, height: adSize.size.height) // 幅も固定
            }
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
            banner.adUnitID = "ca-app-pub-2366369828485169/4970286880"
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
        }
        
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("FAILED TO RECEIVE AD: \(error.localizedDescription)")
        }
    }
}
