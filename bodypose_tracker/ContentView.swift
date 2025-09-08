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

class GameScene: SKScene, SKPhysicsContactDelegate {
    private var spawnInterval: TimeInterval = 4.0
    private var waitInterval: TimeInterval = 3.5
    private var minInterval: TimeInterval = 0.5
    private var spawnAcceleration: TimeInterval = 0.05
    var currentPose: String? { didSet { handlePose(currentPose)}}
    var character: SKSpriteNode!
    let stickmanTexture = SKTexture(imageNamed: "stickmanObstacle")
    let grassTexture = SKTexture(imageNamed: "grassObstacle")
    let blockTexture = SKTexture(imageNamed: "blockObstacle")
    let holeTexture = SKTexture(imageNamed: "holeObstacle")
    let waterTexture = SKTexture(imageNamed: "waterObstacle")
    let dragonTexture = SKTexture(imageNamed: "dragon")
    
    override func didMove(to view: SKView) {
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.contactDelegate = self
        createRoad()
        let spawnAction = SKAction.run { [weak self] in
            self?.spawnRandomObstacle()
        }
        let waitAction = SKAction.wait(forDuration: waitInterval)
        run(SKAction.repeatForever(SKAction.sequence([spawnAction, waitAction])))
        initiateCharacter()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let playerHitObstacle = (contact.bodyA.categoryBitMask == PhysicsCategory.player && contact.bodyB.categoryBitMask == PhysicsCategory.obstacle) || (contact.bodyA.categoryBitMask == PhysicsCategory.obstacle && contact.bodyB.categoryBitMask == PhysicsCategory.player)
        if playerHitObstacle {
            print("Game Over")
        }else {
            print("aaa")
        }
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
        
        let types = ["People", "Grass", "Block", "Hole", "Water", "Dragon"]
        let type = types.randomElement() ?? types[0]
        var obstacle: SKSpriteNode? = nil
        
        switch type {
        case "People":
            let rectangularStickman = SKSpriteNode(texture: stickmanTexture)
            rectangularStickman.size = CGSize(width: 200, height: 120)
            rectangularStickman.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 200, height: 120))
            rectangularStickman.physicsBody?.isDynamic = false
            
            rectangularStickman.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
            rectangularStickman.physicsBody?.collisionBitMask = PhysicsCategory.player
            rectangularStickman.physicsBody?.contactTestBitMask = PhysicsCategory.player
            
            obstacle = rectangularStickman
        case "Grass":
            let texturedGrass = SKSpriteNode(texture: grassTexture)
            texturedGrass.size = CGSize(width: 200, height: 120)
            texturedGrass.physicsBody = SKPhysicsBody(texture: grassTexture, size: CGSize(width: 200, height: 120))
            texturedGrass.physicsBody?.isDynamic = false
            
            texturedGrass.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
            texturedGrass.physicsBody?.collisionBitMask = PhysicsCategory.player
            texturedGrass.physicsBody?.contactTestBitMask = PhysicsCategory.player
            
            obstacle = texturedGrass
        case "Block":
            let texturedBlock = SKSpriteNode(texture: blockTexture)
            texturedBlock.size = CGSize(width: 200, height: 120)
            texturedBlock.physicsBody = SKPhysicsBody(texture: blockTexture, size: CGSize(width: 200, height: 120))
            texturedBlock.physicsBody?.isDynamic = false
            
            texturedBlock.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
            texturedBlock.physicsBody?.collisionBitMask = PhysicsCategory.player
            texturedBlock.physicsBody?.contactTestBitMask = PhysicsCategory.player
            
            obstacle = texturedBlock
        case "Hole":
            let texturedHole = SKSpriteNode(texture: holeTexture)
            texturedHole.size = CGSize(width: 200, height: 120)
            texturedHole.physicsBody = SKPhysicsBody(texture: holeTexture, size: CGSize(width: 200, height: 200))
            texturedHole.physicsBody?.isDynamic = false
            
            texturedHole.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
            texturedHole.physicsBody?.collisionBitMask = PhysicsCategory.player
            texturedHole.physicsBody?.contactTestBitMask = PhysicsCategory.player
            
            obstacle = texturedHole
        case "Water":
            let texturedWater = SKSpriteNode(texture: waterTexture)
            texturedWater.size = CGSize(width: 200, height: 120)
            texturedWater.physicsBody = SKPhysicsBody(texture: waterTexture, size: CGSize(width: 200, height: 200))
            texturedWater.physicsBody?.isDynamic = false
            
            texturedWater.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
            texturedWater.physicsBody?.collisionBitMask = PhysicsCategory.player
            texturedWater.physicsBody?.contactTestBitMask = PhysicsCategory.player
            
            obstacle = texturedWater
        case "Dragon":
            let texturedDragon = SKSpriteNode(texture: dragonTexture)
            texturedDragon.size = CGSize(width: 200, height: 120)
            texturedDragon.physicsBody = SKPhysicsBody(texture: dragonTexture, size: CGSize(width: 200, height: 200))
            texturedDragon.physicsBody?.isDynamic = false
            
            texturedDragon.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
            texturedDragon.physicsBody?.collisionBitMask = PhysicsCategory.player
            texturedDragon.physicsBody?.contactTestBitMask = PhysicsCategory.player
            
            obstacle = texturedDragon
        default:
            let rectangularStickman = SKSpriteNode(texture: stickmanTexture)
            rectangularStickman.size = CGSize(width: 200, height: 120)
            rectangularStickman.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 200, height: 120))
            rectangularStickman.physicsBody?.isDynamic = false
            
            rectangularStickman.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
            rectangularStickman.physicsBody?.collisionBitMask = PhysicsCategory.player
            rectangularStickman.physicsBody?.contactTestBitMask = PhysicsCategory.player
            
            obstacle = rectangularStickman
        }
        
        obstacle?.zPosition = 5
        obstacle?.setScale(0.5)
        obstacle?.position = CGPoint(x: X, y: startY)
        addChild(obstacle!)
        
        let scaleBigger = SKAction.scale(by: 5, duration: spawnInterval)
        let moveAction = SKAction.moveBy(x: 0, y: -roadHeight, duration: spawnInterval)
        let group = SKAction.group([moveAction, scaleBigger])
        let remove = SKAction.removeFromParent()
        obstacle!.run(SKAction.sequence([group, remove]))
    }
    func initiateCharacter(){
        let firstFrame = SKTexture(imageNamed: "IMG_0596-removebg-preview 1")
        character = SKSpriteNode(texture: firstFrame)
        character.position = CGPoint(x: size.width * 0.5, y: size.height * 0.3)
        character.zPosition = 10
        //        character.physicsBody = SKPhysicsBody(rectangleOf: character.size)
        //        character.physicsBody?.isDynamic = false
        //        character.physicsBody?.categoryBitMask = PhysicsCategory.player
        //        character.physicsBody?.collisionBitMask = PhysicsCategory.obstacle
        //        character.physicsBody?.contactTestBitMask = PhysicsCategory.obstacle
        addChild(character)
        startRunningAnimation()
    }
    func startRunningAnimation(){
        let frames = [
            SKTexture(imageNamed: "IMG_0596-removebg-preview 1"),
            SKTexture(imageNamed: "IMG_0596-removebg-preview"),
            SKTexture(imageNamed: "IMG_0599-removebg-preview"),
            SKTexture(imageNamed: "IMG_0600-removebg-preview"),
            SKTexture(imageNamed: "IMG_0602-removebg-preview"),
            SKTexture(imageNamed: "IMG_0603-removebg-preview"),
            SKTexture(imageNamed: "IMG_0604-removebg-preview"),
            SKTexture(imageNamed: "IMG_0605_1_-removebg-preview"),
            SKTexture(imageNamed: "IMG_0606-removebg-preview"),
            SKTexture(imageNamed: "IMG_0607-removebg-preview"),
            SKTexture(imageNamed: "IMG_0609-removebg-preview"),
            SKTexture(imageNamed: "IMG_0611-removebg-preview"),
            
        ]
        let runningAction = SKAction.animate(with: frames, timePerFrame: 0.1)
        let repeatRun = SKAction.repeatForever(runningAction)
        character.run(repeatRun)
    }
    
    private func handlePose(_ pose: String?) {
        guard let pose = pose else { return }
        switch pose {
            //        switch pose {
            
        case "HandsOnHead":
            print("HandsOnHead")
            
        case "Clap":
            print("Clap")
            
        case "Swimming":
            print("Swimming")
            
        case "Flying":
            print("Flying")
            
        case "Cutting":
            print("Cutting")
            
        default:
            print("No Pose Detected")
        }
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
        road.zPosition = 0
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
        poseViewModel.gameScene = scene
        return scene
    }
    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
            .overlay(
                VStack {
                    HStack {
                        VStack {
                            ZStack {
                                CameraPreviewView(session: cameraViewModel.session)
                                //                    .edgesIgnoringSafeArea(.all)
                                PoseOverlayView(bodyParts: poseViewModel.detectedBodyParts, connections: poseViewModel.bodyConnections)
                            }
                            .frame(width: 150, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding()
                            Text(poseViewModel.detectedPose)
                                .padding()
                            Spacer()
                        }
                        Spacer()
                    }
                }
            )
            .task {
                await cameraViewModel.checkpermission()
                cameraViewModel.delegate = poseViewModel
            }
    }
}

#Preview {
    ContentView()
}




struct PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 0b1
    static let obstacle: UInt32 = 0b10
}
