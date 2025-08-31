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
    private var obstacleQueue: [String] = []
    private var isSpawning = false
    
    override func didMove(to view: SKView) {
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        createRoad()
    }
    
    func spawnObstacles() {
        let types = ["People", "Grass", "Block", "Hole", "Water", "Dragon", "Tunnel"]
        let type = types.randomElement() ?? types[0]
        
    }
    
    
    func createRoad() {
        let roadPath = CGMutablePath()
        let bottomWidth: CGFloat = size.width * 0.9
        let topWidth: CGFloat = size.width * 0.2
        let roadHeight: CGFloat = size.height
        
        roadPath.move(to: CGPoint(x: size.width / 2 - bottomWidth / 2, y: 0))
        roadPath.addLine(to: CGPoint(x: size.width / 2 + bottomWidth / 2, y: 0))
        roadPath.addLine(to: CGPoint(x: size.width / 2 + topWidth / 2, y: roadHeight))
        roadPath.addLine(to: CGPoint(x: size.width / 2 - topWidth / 2, y: roadHeight))
        roadPath.closeSubpath()
        
        let road = SKShapeNode(path: roadPath)
        road.fillColor = .black
        road.lineWidth = 4
        addChild(road)
    }
    
//    override func update(_ time: TimeInterval) {
//        guard let pose = currentPose else { return }
//        
//        switch pose {
//            
//        case "HandsOnHead":
//            print("HandsOnHead")
//            
//        case "Clap":
//            print("Clap")
//            
//        case "Swimming":
//            print("Swimming")
//            
//        case "Climbing":
//            print("Climbing")
//            
//        case "Flying":
//            print("Flying")
//            
//        case "Cutting":
//            print("Cutting")
//            
//        default:
//            print("No Pose Detected")
//        }
//    }
}

struct ContentView: View {
    @State private var cameraViewModel = CameraViewModel()
    @State private var poseViewModel = PoseEstimationViewModel()
    var scene: SKScene {
        let scene = GameScene()
        scene.size = CGSize(width: 400, height: 800)
        scene.scaleMode = .resizeFill
        return scene
    }
    var body: some View {
        VStack {
//            ZStack {
//                CameraPreviewView(session: cameraViewModel.session)
//                    .edgesIgnoringSafeArea(.all)
//                PoseOverlayView(bodyParts: poseViewModel.detectedBodyParts, connections: poseViewModel.bodyConnections)
//            }
//            Text(poseViewModel.detectedPose)
//                .font(.title)
            SpriteView(scene: scene)
                .ignoresSafeArea()
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
