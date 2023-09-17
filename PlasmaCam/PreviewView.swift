//
//  PreviewView.swift
//  PlasmaCam
//
//  Created by Aubrey Goodman on 9/16/23.
//

import UIKit
import AVFoundation
import SwiftUI

class PreviewView: UIView {

    // Use AVCaptureVideoPreviewLayer as the view's backing layer.
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer? {
        layer as? AVCaptureVideoPreviewLayer
    }
    
    // Connect the layer to a capture session.
    var session: AVCaptureSession? {
        get { previewLayer?.session }
        set { previewLayer?.session = newValue }
    }
}

struct PreviewViewWrapper: UIViewRepresentable {
    @ObservedObject var viewModel: CameraViewModel
    
    func makeUIView(context: Context) -> PreviewView {
        let result = PreviewView()
        result.session = viewModel.captureSession
        return result
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.session = viewModel.captureSession
    }
}
