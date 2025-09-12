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

struct PhysicsCategory {
    static let none: UInt32   = 0
    static let character: UInt32 = 0x1 << 0
    static let obstacle: UInt32  = 0x1 << 1
}

enum PlayerState {
    case run, cut, swim, fly, crashout, bomb
}


class GameScene: SKScene, SKPhysicsContactDelegate {
    private var spawnInterval: TimeInterval = 4.0
    private var waitInterval: TimeInterval = 3.5
    private var minInterval: TimeInterval = 0.5
    private var spawnAcceleration: TimeInterval = 0.05
    var obstacle: SKSpriteNode? = nil
    var viewModel: GameViewModel?
    var currentPose: String? { didSet { handlePose(currentPose)}}
    var character: SKSpriteNode!
    var currentObstacle: String!
    
    var playerState: PlayerState = .run
    var runAction: SKAction!
    var swimAction: SKAction!
    var cutAction: SKAction!
    var bombAction: SKAction!
    var flyAction: SKAction!
    var crashoutAction: SKAction!
    var repeatRun: SKAction!
    var repeatSwim: SKAction!
    var repeatCut: SKAction!
    var repeatFly: SKAction!
    var repeatCrashout: SKAction!
    var repeatBomb: SKAction!
    var storedPose = ""
    
    let stickmanTexture = SKTexture(imageNamed: "stickmanObstacle")
    let grassTexture = SKTexture(imageNamed: "grassObstacle")
    let blockTexture = SKTexture(imageNamed: "blockObstacle")
    let holeTexture = SKTexture(imageNamed: "holeObstacle")
    let waterTexture = SKTexture(imageNamed: "waterObstacle")
    let dragonTexture = SKTexture(imageNamed: "dragon")
    var model: PoseEstimationViewModel
    
    init(size: CGSize, model: PoseEstimationViewModel) {
        self.model = model
        super.init(size: size)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        //setPlayerState(.idle)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var obstacleNode: SKNode?
        let playerHitObstacle = (contact.bodyA.categoryBitMask == PhysicsCategory.character && contact.bodyB.categoryBitMask == PhysicsCategory.obstacle) || (contact.bodyA.categoryBitMask == PhysicsCategory.obstacle && contact.bodyB.categoryBitMask == PhysicsCategory.character)
        if contact.bodyA.categoryBitMask == PhysicsCategory.obstacle {
            obstacleNode = contact.bodyA.node
        }else if contact.bodyB.categoryBitMask == PhysicsCategory.obstacle {
            obstacleNode = contact.bodyB.node
        }
        
        if playerHitObstacle {
            let obstacle = obstacleNode
            print("Game Over")
            if (currentObstacle == "People" && model.detectedPose == "Hands on Head Detected!") || (currentObstacle == "Grass" && model.detectedPose == "Cutting detected!") || (currentObstacle == "Grass" && model.detectedPose == "Flying detected!") || (currentObstacle == "Block" && model.detectedPose == "Flying detected!") || (currentObstacle == "Hole" && model.detectedPose == "Flying detected!") || (currentObstacle == "Water" && model.detectedPose == "Swimming") || (currentObstacle == "Dragon" && model.detectedPose == "Clap"){
                print("Correct pose!")
                obstacle!.removeFromParent()
            }else {
                viewModel?.gameOver = true
            }
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
        //        var obstacle: SKSpriteNode? = nil
        
        switch type {
        case "People":
            let rectangularStickman = SKSpriteNode(texture: stickmanTexture)
            let hitboxSize = CGSize(width: rectangularStickman.size.width * 0.09, height: rectangularStickman.size.height * 0.09)
            rectangularStickman.size = CGSize(width: 200, height: 120)
            //            rectangularStickman.setScale(0.5)
            
            rectangularStickman.name = "Stickman"
            rectangularStickman.physicsBody = SKPhysicsBody(rectangleOf: hitboxSize)
            
            rectangularStickman.physicsBody?.isDynamic = false
            
            rectangularStickman.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
            rectangularStickman.physicsBody?.collisionBitMask = PhysicsCategory.character
            rectangularStickman.physicsBody?.contactTestBitMask = PhysicsCategory.character
            
            obstacle = rectangularStickman
        case "Grass":
            let texturedGrass = SKSpriteNode(texture: grassTexture)
            let hitboxSize = CGSize(width: texturedGrass.size.width * 0.09, height: texturedGrass.size.height * 0.09)
            texturedGrass.size = CGSize(width: 200, height: 120)
            //            texturedGrass.setScale(0.5)
            texturedGrass.name = "Grass"
            texturedGrass.physicsBody = SKPhysicsBody(rectangleOf: hitboxSize)
            texturedGrass.physicsBody?.isDynamic = false
            
            texturedGrass.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
            texturedGrass.physicsBody?.collisionBitMask = PhysicsCategory.character
            texturedGrass.physicsBody?.contactTestBitMask = PhysicsCategory.character
            
            obstacle = texturedGrass
        case "Block":
            let texturedBlock = SKSpriteNode(texture: blockTexture)
            let hitboxSize = CGSize(width: texturedBlock.size.width * 0.09, height: texturedBlock.size.height * 0.09)
            texturedBlock.size = CGSize(width: 200, height: 120)
            //            texturedBlock.setScale(0.5)
            
            texturedBlock.name = "Block"
            texturedBlock.physicsBody = SKPhysicsBody(rectangleOf: hitboxSize)
            texturedBlock.physicsBody?.isDynamic = false
            
            texturedBlock.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
            texturedBlock.physicsBody?.collisionBitMask = PhysicsCategory.character
            texturedBlock.physicsBody?.contactTestBitMask = PhysicsCategory.character
            
            obstacle = texturedBlock
        case "Hole":
            let texturedHole = SKSpriteNode(texture: holeTexture)
            let hitboxSize = CGSize(width: texturedHole.size.width * 0.09, height: texturedHole.size.height * 0.09)
            texturedHole.size = CGSize(width: 200, height: 120)
            //            texturedHole.setScale(0.5)
            texturedHole.name = "Hole"
            texturedHole.physicsBody = SKPhysicsBody(rectangleOf: hitboxSize)
            texturedHole.physicsBody?.isDynamic = false
            
            texturedHole.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
            texturedHole.physicsBody?.collisionBitMask = PhysicsCategory.character
            texturedHole.physicsBody?.contactTestBitMask = PhysicsCategory.character
            
            obstacle = texturedHole
        case "Water":
            let texturedWater = SKSpriteNode(texture: waterTexture)
            let hitboxSize = CGSize(width: texturedWater.size.width * 0.09, height: texturedWater.size.height * 0.09)
            texturedWater.size = CGSize(width: 200, height: 120)
            //            texturedWater.setScale(0.5)
            texturedWater.name = "Water"
            texturedWater.physicsBody = SKPhysicsBody(rectangleOf: hitboxSize)
            texturedWater.physicsBody?.isDynamic = false
            
            texturedWater.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
            texturedWater.physicsBody?.collisionBitMask = PhysicsCategory.character
            texturedWater.physicsBody?.contactTestBitMask = PhysicsCategory.character
            
            obstacle = texturedWater
        case "Dragon":
            let texturedDragon = SKSpriteNode(texture: dragonTexture)
            let hitboxSize = CGSize(width: texturedDragon.size.width * 0.09, height: texturedDragon.size.height * 0.09)
            texturedDragon.size = CGSize(width: 200, height: 120)
            //            texturedDragon.setScale(0.5)
            texturedDragon.name = "Dragon"
            texturedDragon.physicsBody = SKPhysicsBody(rectangleOf: hitboxSize)
            texturedDragon.physicsBody?.isDynamic = false
            
            texturedDragon.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
            texturedDragon.physicsBody?.collisionBitMask = PhysicsCategory.character
            texturedDragon.physicsBody?.contactTestBitMask = PhysicsCategory.character
            
            obstacle = texturedDragon
        default:
            let rectangularStickman = SKSpriteNode(texture: stickmanTexture)
            let hitboxSize = CGSize(width: rectangularStickman.size.width * 0.09, height: rectangularStickman.size.height * 0.09)
            rectangularStickman.size = CGSize(width: 200, height: 120)
            //            rectangularStickman.setScale(0.5)
            rectangularStickman.name = "Stickman"
            rectangularStickman.physicsBody = SKPhysicsBody(rectangleOf: hitboxSize)
            rectangularStickman.physicsBody?.isDynamic = false
            
            rectangularStickman.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
            rectangularStickman.physicsBody?.collisionBitMask = PhysicsCategory.character
            rectangularStickman.physicsBody?.contactTestBitMask = PhysicsCategory.character
            
            obstacle = rectangularStickman
        }
        
        currentObstacle = type
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
    struct PhysicsCategory {
        static let none: UInt32   = 0
        static let character: UInt32 = 0x1 << 0
        static let obstacle: UInt32  = 0x1 << 1
    }
    
    func initiateCharacter(){
        let firstFrame = SKTexture(imageNamed: "IMG_0596-removebg-preview 1")
        character = SKSpriteNode(texture: firstFrame)
        character.physicsBody = SKPhysicsBody(rectangleOf: character.size)
        character.physicsBody?.categoryBitMask = PhysicsCategory.character
        
        //character.physicsBody?.contactTestBitMask = PhysicsCategory.
        character.position = CGPoint(x: size.width * 0.5, y: size.height * 0.3)
        character.zPosition = 10
        character.setScale(0.5)
        //        character.physicsBody = SKPhysicsBody(rectangleOf: character.size)
        //        character.physicsBody?.isDynamic = false
        //        character.physicsBody?.categoryBitMask = PhysicsCategory.player
        //        character.physicsBody?.collisionBitMask = PhysicsCategory.obstacle
        //        character.physicsBody?.contactTestBitMask = PhysicsCategory.obstacle
        addChild(character)
        startRunningAnimation()
    }
    func startRunningAnimation(){
        let swimTextures = [
            SKTexture(imageNamed: "IMG_0681-removebg-preview"),
            SKTexture(imageNamed: "IMG_0682-removebg-preview"),
            SKTexture(imageNamed: "IMG_0683-removebg-preview"),
            SKTexture(imageNamed: "IMG_0684-removebg-preview"),
            SKTexture(imageNamed: "IMG_0685-removebg-preview"),
            SKTexture(imageNamed: "IMG_0686-removebg-preview"),
            SKTexture(imageNamed: "IMG_0687-removebg-preview"),
            SKTexture(imageNamed: "IMG_0688-removebg-preview"),
            SKTexture(imageNamed: "IMG_0689-removebg-preview"),
            SKTexture(imageNamed: "IMG_0690-removebg-preview"),
            SKTexture(imageNamed: "IMG_0691-removebg-preview"),
            SKTexture(imageNamed: "IMG_0692-removebg-preview"),
            SKTexture(imageNamed: "IMG_0693-removebg-preview"),
            SKTexture(imageNamed: "IMG_0695-removebg-preview"),
            
            
        ]
        let flyTextures = [
            SKTexture(imageNamed: "IMG_0748-removebg-preview"),
            SKTexture(imageNamed: "IMG_0749-removebg-preview"),
            SKTexture(imageNamed: "IMG_0750-removebg-preview"),
            SKTexture(imageNamed: "IMG_0752-removebg-preview"),
            SKTexture(imageNamed: "IMG_0753-removebg-preview"),
            SKTexture(imageNamed: "IMG_0754-removebg-preview"),
            SKTexture(imageNamed: "IMG_0755-removebg-preview"),
            SKTexture(imageNamed: "IMG_0756-removebg-preview"),
            SKTexture(imageNamed: "IMG_0757-removebg-preview"),
        ]
        let cutTextures = [
            //SKTexture(imageNamed: "IMG_709-removebg-preview"),
            SKTexture(imageNamed: "IMG_0710-removebg-preview"),
            SKTexture(imageNamed: "IMG_0711-removebg-preview"),
            SKTexture(imageNamed: "IMG_0712-removebg-preview"),
            SKTexture(imageNamed: "IMG_0718-removebg-preview"),
            SKTexture(imageNamed: "IMG_0719-removebg-preview"),
            SKTexture(imageNamed: "IMG_0721-removebg-preview"),
            SKTexture(imageNamed: "IMG_0722-removebg-preview"),
            SKTexture(imageNamed: "IMG_0724-removebg-preview"),
            SKTexture(imageNamed: "IMG_0725-removebg-preview"),
        ]
        let crashoutTextures = [
            SKTexture(imageNamed: "IMG_0782-removebg-preview"),
            SKTexture(imageNamed: "IMG_0783-removebg-preview"),
            SKTexture(imageNamed: "IMG_0786-removebg-preview"),
            SKTexture(imageNamed: "IMG_0787-removebg-preview"),
            SKTexture(imageNamed: "IMG_0788-removebg-preview"),
            SKTexture(imageNamed: "IMG_0789-removebg-preview"),
            SKTexture(imageNamed: "IMG_0790-removebg-preview"),
        ]
        let bombTextures = [
            SKTexture(imageNamed: "fiery-explosion-dramatic-visual-intense-combustion-debris_191095-81825"),
            SKTexture(imageNamed: "fiery-explosion-dramatic-visual-intense-combustion-debris_191095-81825"),
            SKTexture(imageNamed: "fiery-explosion-dramatic-visual-intense-combustion-debris_191095-81825"),
//            SKTexture(imageNamed: "fiery-explosion-dramatic-visual-intense-combustion-debris_191095-81825"),
//            SKTexture(imageNamed: "fiery-explosion-dramatic-visual-intense-combustion-debris_191095-81825"),
        ]
        
        let runframes = [
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
        runAction = SKAction.animate(with: runframes, timePerFrame: 0.1)
        swimAction = SKAction.animate(with: swimTextures, timePerFrame: 0.1)
        cutAction = SKAction.animate(with: cutTextures, timePerFrame: 0.1)
        flyAction = SKAction.animate(with: flyTextures, timePerFrame: 0.1)
        crashoutAction = SKAction.animate(with: crashoutTextures, timePerFrame: 0.1)
        bombAction = SKAction.animate(with: bombTextures, timePerFrame: 0.1)
        
        repeatRun = SKAction.repeatForever(runAction)
        repeatSwim = SKAction.repeatForever(swimAction)
        repeatCrashout = SKAction.repeatForever(crashoutAction)
        repeatBomb = SKAction.repeatForever(bombAction)
        repeatCut = SKAction.repeatForever(cutAction)
        repeatFly = SKAction.repeatForever(flyAction)
        
        if model.detectedPose == "Swimming"{
            character.run(repeatSwim)
        }else if model.detectedPose == "Hands on Head Detected!"{
            character.run(repeatCrashout)
        }else if model.detectedPose == "Cutting detected!"{
            character.run(repeatCut)
        }else if model.detectedPose == "Flying detected!"{
            character.run(repeatFly)
        }else if model.detectedPose == "Clap"{
            character.run(repeatBomb)
        }else{
            character.run(repeatRun)
        }
        
        //if statement goes here
    }
    //    func startSwimmingAnimation(){
    //    let swimframes = [
    //        SKTexture(imageNamed: "james_swim"),
    //    ]
    //    let swimmingAction = SKAction.animate(with: swimframes, timePerFrame: 0.1)
    //    let repeatSwim = SKAction.repeatForever(swimmingAction)
    //    character.run(repeatSwim)
    //}
    //    func startCrashoutAnimation(){
    //    let swimframes = [
    //        SKTexture(imageNamed: "james_swim"),
    //    ]
    //    let swimmingAction = SKAction.animate(with: swimframes, timePerFrame: 0.1)
    //    let repeatSwim = SKAction.repeatForever(swimmingAction)
    //    character.run(repeatSwim)
    //}
    //    func startFlyingAnimation(){
    //    let flyframes = [
    //        SKTexture(imageNamed: "james_jump-removebg-preview"),
    //    ]
    //    let swimmingAction = SKAction.animate(with: flyframes, timePerFrame: 0.1)
    //    let repeatSwim = SKAction.repeatForever(swimmingAction)
    //    character.run(repeatSwim)
    //}
    //    func startBombingAnimation(){
    //    let swimframes = [
    //        SKTexture(imageNamed: "james_swim"),
    //    ]
    //    let swimmingAction = SKAction.animate(with: swimframes, timePerFrame: 0.1)
    //    let repeatSwim = SKAction.repeatForever(swimmingAction)
    //    character.run(repeatSwim)
    //}
    
    private func handlePose(_ pose: String?) {
        guard let pose = pose else { return }
        
        if storedPose != pose {
            character.removeAction(forKey: "animation")
            switch pose {
                //        switch pose {
                
            case "HandsOnHead":
                print("HandsOnHead")
                character.run(repeatCrashout, withKey: "animation")
            case "Clap":
                print("Clap")
                character.run(repeatBomb, withKey: "animation")
            case "Swimming":
                print("Swimming")
                character.run(repeatSwim, withKey: "animation")
            case "Flying":
                print("Flying")
                character.run(repeatFly, withKey: "animation")
            case "Cutting":
                print("Cutting")
                character.run(repeatCut, withKey: "animation")
            default:
                print("No Pose Detected")
                character.run(repeatRun, withKey: "animation")
            }
            storedPose = pose
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
    @StateObject private var viewModel = GameViewModel()
    @State private var startPage: Bool = true
    //    var scene: SKScene {
    //        let scene = GameScene(size: CGSize(width: 400, height: 800),model: poseViewModel)
    //        scene.scaleMode = .resizeFill
    //        poseViewModel.gameScene = scene
    //        scene.viewModel = viewModel
    //        return scene
    //    } -> Wrong cause its a computed property meaning it creates a new GameScene when swiftUI rerenders(@Observable in poseEstimationViewModel)
    @State private var scene: GameScene // Store in State first so it doesn't rerender
    
    init() {
        let poseViewModel = PoseEstimationViewModel()
        let scene = GameScene(size: CGSize(width: 400, height: 800), model: poseViewModel)
        scene.scaleMode = .resizeFill
        _scene = State(initialValue: scene) //_ before variable is basically initialising @State with a starting value
        _poseViewModel = State(initialValue: poseViewModel)
    }
    var body: some View {
        if startPage {
            VStack {
                //                ZStack {
                //                    CameraPreviewView(session: cameraViewModel.session)
                //                        .edgesIgnoringSafeArea(.all)
                //                    PoseOverlayView(bodyParts: poseViewModel.detectedBodyParts, connections: poseViewModel.bodyConnections)
                //                }
                Text("Welcome")
                    .font(.largeTitle)
                    .bold()
                Button {
                    startPage = false
                }label: {
                    Text("Start")
                }
                .buttonStyle(.borderedProminent)
            }
            //            .task {
            //                await cameraViewModel.checkpermission()
            //                cameraViewModel.delegate = poseViewModel
            //            }
        }else {
            if !viewModel.gameOver {
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
                    .onAppear {
                        scene.removeAllActions()
                        scene.removeAllChildren()
                        scene.viewModel = viewModel
                        poseViewModel.gameScene = scene
                    }
            }else {
                GameOverView(gameOver: $viewModel.gameOver)
            }
        }
    }
}



class GameViewModel: ObservableObject {
    @Published var gameOver: Bool = false
}

#Preview {
    ContentView()
}
