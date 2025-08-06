//
//  File 2.swift
//  ToDoList
//
//  Created by 尾野順哉 on 2025/03/29.
//


.onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
                    // リクエスト後の状態に応じた処理を行う
                    switch status {
                    case .authorized:
                        print("Authorized")
                    case .denied:
                        print("denied")
                    case .notDetermined:
                        print("Not Determined")
                    case .restricted:
                        print("Restricted")
                    @unknown default:
                        print("Unknown")
                    }
                })
            }