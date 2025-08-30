//
//  ContentView.swift
//  bodypose_tracker
//
//  Created by T Krobot on 16/8/25.
//

import SwiftUI
import AVFoundation
import Vision
import SpriteKit

class GameScene: SKScene {
    var currentPose: String? = nil
    override func didMove(to view: SKView) {
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
    }
    
    override func update(_ time: TimeInterval) {
        guard let pose = currentPose else { return }
        
        switch pose {
            
        case "HandsOnHead":
            print("HandsOnHead")
            
        case "Clap":
            print("Clap")
            
        case "Swimming":
            print("Swimming")
            
        case "Climbing":
            print("Climbing")
            
        case "Flying":
            print("Flying")
            
        case "Cutting":
            print("Cutting")
            
        default:
            print("No Pose Detected")
        }
    }
}

struct ContentView: View {
    @State private var cameraViewModel = CameraViewModel()
    @State private var poseViewModel = PoseEstimationViewModel()
    @Environment(PoseEstimationViewModel.self) private var detector
    @State private var scene = GameScene(size: UIScreen.main.bounds.size)
    var body: some View {
        VStack {
            //            ZStack {
            //                CameraPreviewView(session: cameraViewModel.session)
            //                    .edgesIgnoringSafeArea(.all)
            //                PoseOverlayView(bodyParts: poseViewModel.detectedBodyParts, connections: poseViewModel.bodyConnections)
            //            }
            //            Text(poseViewModel.detectedPose)
            SpriteView(scene: scene)
                .onChange(of: detector.detectedPose) { _, newPose in
                    scene.currentPose = newPose
                }
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
