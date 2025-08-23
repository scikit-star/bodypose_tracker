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
    @State private var clapMessage = PoseEstimationViewModel().clapMessage
    var body: some View {
        VStack {
            ZStack {
                CameraPreviewView(session: cameraViewModel.session)
                    .edgesIgnoringSafeArea(.all)
                PoseOverlayView(bodyParts: poseViewModel.detectedBodyParts, connections: poseViewModel.bodyConnections)
            }
            Text(clapMessage)
                .font(.title)
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
