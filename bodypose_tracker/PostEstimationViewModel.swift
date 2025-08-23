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
    var clapMessage: String = "CLAP!"
    
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
                    if self.detectClap(from: detectedPoints, frameWidth: frameWidth, frameHeight: frameHeight) {
                        self.clapMessage = "Clap Detected!"
                    }
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
        print(distance)
        
        return distance < 190
    }
}
