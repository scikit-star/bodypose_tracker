//
//  ContentView.swift
//  bodypose_tracker
//
//  Created by T Krobot on 16/8/25.
//

import SwiftUI
import AVFoundation
import Vision

struct ContentView: View {
    @State private var cameraViewModel = CameraViewModel()
    @State private var poseViewModel = PoseEstimationViewModel()
    var body: some View {
        ZStack {
            CameraPreviewView(session: cameraViewModel.session)
                .edgesIgnoringSafeArea(.all)
            PoseOverlayView(bodyParts: poseViewModel.detectedBodyParts, connections: poseViewModel.bodyConnections)
        }
        .task {
            await cameraViewModel.checkpermission()
            cameraViewModel.delegate = poseViewModel
        }
    }
}

#Preview {
    ContentView()
}
