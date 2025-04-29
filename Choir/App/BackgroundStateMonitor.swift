//
//  BackgroundStateMonitor.swift
//  Choir
//
//  Created by Augment on 4/28/25.
//

import UIKit
import SwiftUI
import Combine

/// Monitors app background state and provides notifications to SwiftUI views
class SceneDelegate: NSObject, ObservableObject {
    @Published var isInBackground = false

    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()

        // Subscribe to app lifecycle notifications
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                print("App will resign active (from SceneDelegate)")
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                print("App did enter background (from SceneDelegate)")
                self?.isInBackground = true
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                print("App will enter foreground (from SceneDelegate)")
                self?.isInBackground = false
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                print("App did become active (from SceneDelegate)")
                self?.isInBackground = false
            }
            .store(in: &cancellables)
    }
}
