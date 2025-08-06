//
//  File.swift
//  ToDoList
//
//  Created by 尾野順哉 on 2025/03/29.
//


//        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
//            Task { @MainActor in
//                // 少し待ってからリクエスト（0.5秒）
//                try await Task.sleep(nanoseconds: 500_000_000)
//                if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
//                    let status = await requestTrackingPermissionAsync()
//                    switch status {
//                    case .authorized:
//                        print("Authorized")
//                    case .denied:
//                        print("Denied")
//                    case .notDetermined:
//                        print("Not Determined")
//                    case .restricted:
//                        print("Restricted")
//                    @unknown default:
//                        print("Unknown")
//                    }
//                }
//            }
//        }