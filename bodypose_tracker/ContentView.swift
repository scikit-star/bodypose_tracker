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
    private var spawnInterval: TimeInterval = 4.0
    private var waitInterval: TimeInterval = 3.5
    private var minInterval: TimeInterval = 0.5
    private var spawnAcceleration: TimeInterval = 0.05
    
    override func didMove(to view: SKView) {
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        createRoad()
        let spawnAction = SKAction.run { [weak self] in
            self?.spawnRandomObstacle()
        }
        let waitAction = SKAction.wait(forDuration: waitInterval)
        run(SKAction.repeatForever(SKAction.sequence([spawnAction, waitAction])))
    }
    
    //    func xBoundsForRoad(y: CGFloat, bottomWidth: CGFloat, topWidth: CGFloat, roadHeight: CGFloat) -> (left: CGFloat, right: CGFloat) {
    //        let t = y / roadHeight // (linear interpolation) find the height at that time
    //        let currentWidth = bottomWidth + (topWidth - bottomWidth) * t
    //        let centerX = size.width / 2
    //        return (centerX - currentWidth / 2, centerX + currentWidth / 2)
    //    }
    
    func spawnRandomObstacle() {
        //        let bottomWidth: CGFloat = size.width * 0.9
        //        let topWidth: CGFloat = size.width * 0.2
        let roadHeight: CGFloat = size.height
        let startY = size.height
        //        let (leftx, rightx) = xBoundsForRoad(y: startY, bottomWidth: bottomWidth, topWidth: topWidth, roadHeight: roadHeight)
        let X = size.width / 2
        
        let types = ["People", "Grass", "Block", "Hole", "Water", "Dragon", "Tunnel"]
        let type = types.randomElement() ?? types[0]
        var obstacle: SKSpriteNode? = nil
        
        switch type {
        case "People":
            obstacle = SKSpriteNode(color: .systemPink, size: CGSize(width: 60, height: 60))
        case "Grass":
            obstacle = SKSpriteNode(color: .green, size: CGSize(width: 60, height: 60))
        case "Block":
            obstacle = SKSpriteNode(color: .purple, size: CGSize(width: 60, height: 60))
        case "Hole":
            obstacle = SKSpriteNode(color: .cyan, size: CGSize(width: 60, height: 60))
        case "Water":
            obstacle = SKSpriteNode(color: .blue, size: CGSize(width: 60, height: 60))
        case "Dragon":
            obstacle = SKSpriteNode(color: .red, size: CGSize(width: 60, height: 60))
        case "Tunnel":
            obstacle = SKSpriteNode(color: .white, size: CGSize(width: 60, height: 60))
        default:
            obstacle = SKSpriteNode(color: .gray, size: CGSize(width: 60, height: 60))
        }
        
        obstacle?.setScale(0.5)
        obstacle?.position = CGPoint(x: X, y: startY)
        addChild(obstacle!)
        
        let scaleBigger = SKAction.scale(by: 5, duration: spawnInterval)
        let moveAction = SKAction.moveBy(x: 0, y: -roadHeight, duration: spawnInterval)
        let group = SKAction.group([moveAction, scaleBigger])
        let remove = SKAction.removeFromParent()
        obstacle!.run(SKAction.sequence([group, remove]))
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
            //        ZStack {
            //            VStack {
            //                HStack {
                                ZStack {
                                    CameraPreviewView(session: cameraViewModel.session)
                                        .edgesIgnoringSafeArea(.all)
                                    PoseOverlayView(bodyParts: poseViewModel.detectedBodyParts, connections: poseViewModel.bodyConnections)
                                }
            Text(poseViewModel.detectedPose)
            //                    .frame(width: 100, height: 150)
            //                    Spacer()
            //                }
            //                Spacer()
            //            }
//            SpriteView(scene: scene)
//                .ignoresSafeArea()
//            //        }
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
