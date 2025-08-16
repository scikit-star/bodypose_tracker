//
//  CameraPreviewView.swift
//  bodypose_tracker
//
//  Created by Chuah Cheng Hang on 16/8/25.
//

import SwiftUI
import UIKit
import AVFoundation


struct CameraPreviewView: UIViewRepresentable {
    
    let session: AVCaptureSession // Gets the session
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero) // Creates a blank UI View that holds capture preview
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        previewLayer.videoGravity = .resizeAspectFill // Sets how the video should be displayed(resize to fill)
        previewLayer.frame = view.bounds
        previewLayer.connection?.videoRotationAngle = 90 // Rotate Video Feed by 90 degrees
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        Task {
            if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer { // Tries to get the front layer of UIView's layer
                previewLayer.frame = uiView.bounds // Adjust frames
            }
        }
    }
}
