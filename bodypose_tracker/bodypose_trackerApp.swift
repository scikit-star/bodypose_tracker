//
//  bodypose_trackerApp.swift
//  bodypose_tracker
//
//  Created by T Krobot on 16/8/25.
//

import SwiftUI

@main
struct bodypose_trackerApp: App {
    @State private var poseDetector = PoseEstimationViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
