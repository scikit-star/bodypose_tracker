//
//  PostEstimationViewModel.swift
//  bodypose_tracker
//
//  Created by Chuah Cheng Hang on 16/8/25.
//

import SwiftUI
import Vision
import AVFoundation
import Observation

struct BodyConnection: Identifiable {
    let id = UUID()
    let from: HumanBodyPoseObservation.JointName
    let to: HumanBodyPoseObservation.JointName
}

@Observable
class PoseEstimationViewModel: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var detectedBodyParts: [HumanBodyPoseObservation.JointName: CGPoint] = [:] // Dictionary that represents specific body joints
    var bodyConnections: [BodyConnection] = []
    var detectedMessage: String = "POSE!"
    
    override init() {
        super.init() // runs base class initializer
        setUpBodyConnections() // prepare skeleton connections when object is created
    }
    
    private func setUpBodyConnections() {
        bodyConnections = [
            BodyConnection(from: .nose, to: .neck),
            BodyConnection(from: .neck, to: .rightShoulder),
            BodyConnection(from: .neck, to: .leftShoulder),
            BodyConnection(from: .rightShoulder, to: .rightHip),
            BodyConnection(from: .leftShoulder, to: .leftHip),
            BodyConnection(from: .rightHip, to: .leftHip),
            BodyConnection(from: .rightShoulder, to: .rightElbow),
            BodyConnection(from: .rightElbow, to: .rightWrist),
            BodyConnection(from: .leftShoulder, to: .leftElbow),
            BodyConnection(from: .leftElbow, to: .leftWrist),
            BodyConnection(from: .rightHip, to: .rightKnee),
            BodyConnection(from: .rightKnee, to: .rightAnkle),
            BodyConnection(from: .leftHip, to: .leftKnee),
            BodyConnection(from: .leftKnee, to: .leftAnkle)
        ]
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        Task {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            let frameWidth = CGFloat(CVPixelBufferGetWidth(imageBuffer))
            let frameHeight = CGFloat(CVPixelBufferGetHeight(imageBuffer))
            
            if let detectedPoints = await processFrame(sampleBuffer) {
                DispatchQueue.main.async {
                    self.detectedBodyParts = detectedPoints
                    if self.detectSwimming(from: detectedPoints, frameWidth: frameWidth, frameHeight: frameHeight) {
                        self.detectedMessage = "Swimming Detected!"
                    }else if self.detectHandsOnHead(from: detectedPoints, frameWidth: frameWidth, frameHeight: frameHeight) {
                        self.detectedMessage = "Hands on Head Detected!"
                    }else if self.cutting(from: detectedPoints){
                        self.detectedMessage = "Cutting detected!"
                    }else if self.climbing(from: detectedPoints) {
                        self.detectedMessage = "Climbing detected!"
                    }else if self.flying(from: detectedPoints) {
                        self.detectedMessage = "Flying Detected!"
                    }else if self.detectClap(from: detectedPoints, frameWidth: frameWidth, frameHeight: frameHeight) {
                        self.detectedMessage = "Clap Detected!"
                    }else { self.detectedMessage = "POSE!" }
                }
            }
        }
    }
    
    func processFrame(_ sampleBuffer: CMSampleBuffer) async -> [HumanBodyPoseObservation.JointName: CGPoint]? {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil } // Gets the image part of the CMSampleBuffer
        
        let request = DetectHumanBodyPoseRequest()
        
        do {
            let results = try await request.perform(on: imageBuffer, orientation: .none)
            if let observation = results.first {
                return extractPoints(from: observation) // converts observation into a dictionary of joint positions
            }
        } catch {
            print("Error processing frame: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    private func extractPoints(from observation: HumanBodyPoseObservation) -> [HumanBodyPoseObservation.JointName: CGPoint] {
        var detectedPoints: [HumanBodyPoseObservation.JointName: CGPoint] = [:]
        var humanJoints: [HumanBodyPoseObservation.PoseJointsGroupName] = [.face, .torso, .leftArm, .rightArm] // process all body regions inside the array for pose estimation
        
        for groupName in humanJoints {
            let jointsInGroup = observation.allJoints(in: groupName)
            for (jointName, joint) in jointsInGroup {
                if joint.confidence > 0.5 { // ensure high confidence joints are added only
                    let point = joint.location.verticallyFlipped().cgPoint // flips y axis since coordinate system is upside down and convert it into ui coordinates
                    detectedPoints[jointName] = point // store detectedPoints into the dictionary
                }
            }
        }
        return detectedPoints
    }
    private func detectClap(from detectedPoints: [HumanBodyPoseObservation.JointName: CGPoint], frameWidth: CGFloat, frameHeight: CGFloat) -> Bool {
        guard let leftWrist = detectedPoints[.leftWrist],
              let rightWrist = detectedPoints[.rightWrist] else {
            return false
        }
        let dx = (leftWrist.x - rightWrist.x) * frameWidth
        let dy = (leftWrist.y - rightWrist.y) * frameHeight
        let distance = sqrt(dx*dx + dy*dy)
        //        print(distance)
        
        return distance < 190
    }
    private func detectSwimming(from detectedPoints: [HumanBodyPoseObservation.JointName: CGPoint], frameWidth: CGFloat, frameHeight: CGFloat) -> Bool {
        guard let rightShoulder = detectedPoints[.rightShoulder],
              let leftShoulder = detectedPoints[.leftShoulder],
              let rightElbow = detectedPoints[.rightElbow],
              let leftElbow = detectedPoints[.leftElbow],
              let rightWrist = detectedPoints[.rightWrist],
              let leftWrist = detectedPoints[.leftWrist] else {
            return false
        }
        func angleBetweenJoints(shoulder: CGPoint, elbow: CGPoint, wrist: CGPoint) -> CGFloat {
            let shoulderToElbowDX = shoulder.x - elbow.x //finds vector
            let shoulderToElbowDY = shoulder.y - elbow.y
            let wristToElbowDX = wrist.x - elbow.x
            let wristToElbowDY = wrist.y - elbow.y
            
            let dot = (shoulderToElbowDX * wristToElbowDX) + (shoulderToElbowDY * wristToElbowDY) //finds how aligned the two vectors are
            let shoulderToElbowMag = sqrt((shoulderToElbowDX * shoulderToElbowDX) + (shoulderToElbowDY * shoulderToElbowDY))
            let wristToElbowMag = sqrt((wristToElbowDX * wristToElbowDX) + (wristToElbowDY * wristToElbowDY))
            guard shoulderToElbowMag > 0 && wristToElbowMag > 0 else { return 0 }
            
            let cosTheta = dot / (shoulderToElbowMag * wristToElbowMag)
            let clampedCos = max(-1, min(1, cosTheta))
            let angle = acos(clampedCos) * 180 / .pi
            
            return angle
        }
        
        //        let dxForWrist = (rightWrist.x - leftWrist.x) * frameWidth
        //        let dyForWrist = (rightWrist.y - leftWrist.y) * frameHeight
        //        let distance = sqrt((dxForWrist * dxForWrist) + (dyForWrist * dyForWrist))
        
        let rightArmAngle = angleBetweenJoints(shoulder: rightShoulder, elbow: rightElbow, wrist: rightWrist)
        let leftArmAngle = angleBetweenJoints(shoulder: leftShoulder, elbow: leftElbow, wrist: leftWrist)
        
        let checkArmStraight = abs(rightArmAngle - 180) < 30 && abs(leftArmAngle - 180) < 30
        //        let checkWrist = distance < 190
        //        print("rightArmAngle: \(abs(rightArmAngle - 180)), leftArmAngle: \(abs(leftArmAngle - 180))")
        //        let handsLevel = abs((rightWrist.y * frameHeight) - (rightShoulder.y * frameHeight)) < 20 && abs((leftWrist.y * frameHeight) - (leftShoulder.y * frameHeight)) < 20
        return checkArmStraight
    }
    private func detectHandsOnHead(from detectedPoints: [HumanBodyPoseObservation.JointName: CGPoint], frameWidth: CGFloat, frameHeight: CGFloat) -> Bool {
        guard let rightWrist = detectedPoints[.rightWrist],
              let leftWrist = detectedPoints[.leftWrist],
              let rightEye = detectedPoints[.rightEye],
              let leftEye = detectedPoints[.leftEye] else {
            return false
        }
        
        let rightWristCloseToRightEye = abs(rightWrist.y - rightEye.y) * frameHeight < 100
        let leftWristCloseToLeftEye = abs(leftWrist.y - leftEye.y) * frameHeight < 100
        
        
        let dx = (leftWrist.x - rightWrist.x) * frameWidth
        let dy = (leftWrist.y - rightWrist.y) * frameHeight
        let distance = sqrt(dx*dx + dy*dy)
        
        return leftWristCloseToLeftEye && leftWristCloseToLeftEye && distance > 210 && distance < 350
    }
    //    private func isRightHandRaised(from detectedPoints: [HumanBodyPoseObservation.JointName: CGPoint]) -> Bool{
    //        guard let rightWrist = detectedPoints[.rightWrist],
    //              let rightShoulder = detectedPoints[.rightShoulder] else{
    //            return false
    //        }
    //        return rightWrist.y < rightShoulder.y
    //    }
    
    //vars for tracking cutting motion
//    var wristYHistory: [CGFloat] = []
//    let historyLimit = 15   // number of frames to keep
//    let chopThreshold: CGFloat = -0.15  // how fast downward is considered a chop
//    let resetThreshold: CGFloat = 0.05  // upward move to reset
//    var chopInProgress = false
    
    
//    private func detectCutting(from detectedPoints: [HumanBodyPoseObservation.JointName: CGPoint]) -> Bool {
//        guard let rightWrist = detectedPoints[.rightWrist],
//              let rightShoulder = detectedPoints[.nose],
//              let rightElbow = detectedPoints[.rightElbow]else {
//            return false
//        }
//        wristYHistory.append(rightWrist.y)
//        if wristYHistory.count > historyLimit{
//            wristYHistory.removeFirst()
//        }
//        guard wristYHistory.count >= 2 else {return false}
//        let dy = wristYHistory.last! - wristYHistory.first!
//        if !chopInProgress,dy < chopThreshold, rightWrist.y < rightElbow.y {
//            chopInProgress = true
//            return true
//        } else if chopInProgress,
//                  dy > resetThreshold {
//            chopInProgress = false
//        }
//        
//        return false
//        
//    }
//    var rightWristHistory: [CGFloat] = []
//    var leftWristHistory: [CGFloat] = []
//    let flyhistoryLimit = 20
//    
//    enum FlapDirection {
//        case up, down, none
//    }
//    
//    var lastRightFlap: FlapDirection = .none
//    var lastLeftFlap: FlapDirection = .none
    
//    private func detectFlap(from detectedPoints: [HumanBodyPoseObservation.JointName: CGPoint])->Bool {
//        guard let rightWrist = detectedPoints[.rightWrist],
//              let rightShoulder = detectedPoints[.rightShoulder],
//              let leftWrist = detectedPoints[.leftWrist],
//              let leftShoulder = detectedPoints[.leftShoulder] else {
//            return false
//        }
//        
//        // wrist vs shoulder
//        let rightRelativeY = rightWrist.y - rightShoulder.y
//        let leftRelativeY  = leftWrist.y - leftShoulder.y
//        
//        rightWristHistory.append(rightRelativeY)
//        leftWristHistory.append(leftRelativeY)
//        
//        if rightWristHistory.count > historyLimit { rightWristHistory.removeFirst() }
//        if leftWristHistory.count > historyLimit { leftWristHistory.removeFirst() }
//        
//        // detect up vs down
//        let rightFlap = detectSingleFlap(relativeY: rightRelativeY, lastDirection: &lastRightFlap, side: "right")//check
//        let leftFlap = detectSingleFlap(relativeY: leftRelativeY, lastDirection: &lastLeftFlap, side: "left")//check
//        return rightFlap || leftFlap
//    }
//    
//    private func detectSingleFlap(relativeY: CGFloat, lastDirection: inout FlapDirection, side: String)-> Bool {
//        let upThreshold: CGFloat = 0.1   // wrist > shoulder
//        let downThreshold: CGFloat = -0.1 // wrist < shoulder
//        
//        if relativeY > upThreshold, lastDirection != .up {
//            print("\(side) arm flapped up")
//            lastDirection = .up
//            return true
//        } else if relativeY < downThreshold, lastDirection != .down {
//            print("\(side) arm flapped down")
//            lastDirection = .down
//            return true
//        }
//        return false
//    private func flying(from detectedPoints: [HumanBodyPoseObservation.JointName: CGPoint]) -> Bool{
//        guard let rightWrist = detectedPoints[.rightWrist],
//              let leftWrist = detectedPoints[.leftWrist],
//              let rightElbow = detectedPoints[.rightElbow],
//              let leftElbow = detectedPoints[.leftElbow],
//              let rightShoulder = detectedPoints[.rightShoulder],
//              let leftShoulder = detectedPoints[.leftShoulder]else{
//            return false
//        }
//        let rightElbowAligned = (rightElbow.y - rightShoulder.y) < 0.05
//        let leftElbowAligned = (leftElbow.y - leftShoulder.y) < 0.05
//        let rightWristAligned = (rightWrist.y - rightWrist.y) < 0.05
//        let leftWristAligned = (leftWrist.y - leftShoulder.y) < 0.05
//        
//        let leftElbowDistance = abs(leftElbow.x - leftShoulder.x)
//        let rightElbowDistance = abs(rightElbow.x - rightShoulder.x)
//        let leftWristDistance = abs(leftWrist.x - leftShoulder.x)
//        let rightWristDistance = abs(rightWrist.x - leftShoulder.x)
//        
//        let leftWristCloser = leftWristDistance < leftElbowDistance
//        let rightWristCloser = rightWristDistance < rightElbowDistance
//        
//        let bothAligned = leftElbowAligned && rightElbowAligned && leftWristAligned && rightWristAligned
//        let bothWristCloser = leftWristCloser && rightWristCloser
//        if bothAligned && bothWristCloser{
//            return true
//        }
//        return false
//    }
    let straightArmMinAngle: CGFloat = 160.0   // minimum elbow angle to consider "straight"
    let shoulderHeightTolerance: CGFloat = 0.1
    private func flying(from detectedPoints: [HumanBodyPoseObservation.JointName: CGPoint]) -> Bool{
        guard let rightWrist = detectedPoints[.rightWrist],
              let leftWrist = detectedPoints[.leftWrist],
              let rightShoulder = detectedPoints[.rightShoulder],
              let leftShoulder = detectedPoints[.leftShoulder],
              let rightElbow = detectedPoints[.rightElbow],
              let leftElbow = detectedPoints[.leftElbow]else{
            return false
        }
        let leftElbowAngle = elbowAngle(shoulder: leftShoulder, elbow: leftElbow, wrist: leftWrist)
        let leftElbowAligned = abs(leftElbow.y - leftShoulder.y) < shoulderHeightTolerance
        let leftWristAligned = abs(leftWrist.y - leftShoulder.y) < shoulderHeightTolerance
        let leftArmStraight = leftElbowAngle > straightArmMinAngle && leftElbowAligned && leftWristAligned
        
        let rightElbowAngle = elbowAngle(shoulder: rightShoulder, elbow: rightElbow, wrist: rightWrist)
        let rightElbowAligned = abs(rightElbow.y - rightShoulder.y) < shoulderHeightTolerance
        let rightWristAligned = abs(rightWrist.y - rightShoulder.y) < shoulderHeightTolerance
        let rightArmStraight = rightElbowAngle > straightArmMinAngle && rightElbowAligned && rightWristAligned
        
        return leftArmStraight && rightArmStraight
    }
//    private func cutting(from detectedPoints: [HumanBodyPoseObservation.JointName: CGPoint])-> Bool{
//        guard let rightWrist = detectedPoints[.rightWrist],
//              let leftWrist = detectedPoints[.leftWrist],
//              let nose = detectedPoints[.nose],
//              let rightShoulder = detectedPoints[.rightShoulder],
//              let leftShoulder = detectedPoints[.leftShoulder],
//              let rightElbow = detectedPoints[.rightElbow],
//              let leftElbow = detectedPoints[.leftElbow]else{
//            return false
//        }
//        let elbowAligned = ((rightElbow.y - rightShoulder.y) < 0.05 || (leftElbow.y - leftShoulder.y) < 0.05)
//        let wristAligned = ((rightWrist.y - nose.y) < 0.05 || (leftWrist.y - nose.y) < 0.05)
//        if elbowAligned && wristAligned{
//            return true
//        }
//        return false
//    }
    let straightArmMax: CGFloat = 150.0       // elbow angle must be less than this (bent arm)
    let chestHeightTolerance: CGFloat = 0.1   // y difference tolerance
    let minHorizontalOffset: CGFloat = 0.05
    private func cutting (from detectedPoints: [HumanBodyPoseObservation.JointName: CGPoint]) -> Bool{
        guard let rightElbow = detectedPoints[.rightElbow],
              let rightWrist = detectedPoints[.rightWrist],
              let rightShoulder = detectedPoints[.rightShoulder]else{
            return false
        }
        let angle = elbowAngle(shoulder: rightShoulder, elbow: rightElbow, wrist: rightWrist)
        guard angle < straightArmMax else { return false }
        let elbowAligned = abs(rightElbow.y - rightShoulder.y) < chestHeightTolerance
        let wristAligned = abs(rightWrist.y - rightShoulder.y) < chestHeightTolerance
        guard elbowAligned && wristAligned else { return false }
        let horizontalOffset = abs(rightWrist.x - rightShoulder.x)
        guard horizontalOffset > minHorizontalOffset else { return false }
                    
        return true
    }
    private func elbowAngle(shoulder: CGPoint, elbow: CGPoint, wrist: CGPoint)-> CGFloat{
        let v1 = CGPoint(x: shoulder.x - elbow.x, y: shoulder.y - elbow.y)
        let v2 = CGPoint(x: wrist.x - elbow.x, y: wrist.y - elbow.y)
                
        let dot = v1.x * v2.x + v1.y * v2.y
        let mag1 = sqrt(v1.x*v1.x + v1.y*v1.y)
        let mag2 = sqrt(v2.x*v2.x + v2.y*v2.y)
        guard mag1 > 0, mag2 > 0 else { return 0 }
                
        let cosTheta = max(-1.0, min(1.0, dot / (mag1 * mag2)))
        return acos(cosTheta) * 180.0 / .pi
    }
    private func climbing(from detectedPoints: [HumanBodyPoseObservation.JointName: CGPoint])-> Bool{
        guard let rightWrist = detectedPoints[.rightWrist],
              let leftWrist = detectedPoints[.leftWrist],
              let nose = detectedPoints[.nose]else{
            return false
        }
        if rightWrist.y < nose.y, rightWrist.y < leftWrist.y{
            return true
        }else if rightWrist.y < nose.y, leftWrist.y < rightWrist.y {
            return true
        }
        return false
    }
    
}
