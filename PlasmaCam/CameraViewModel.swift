//
//  CameraViewModel.swift
//  PlasmaCam
//
//  Created by Aubrey Goodman on 9/16/23.
//

import Foundation
import UIKit
import AVFoundation

class CameraViewModel: ObservableObject, CameraManagerDelegate {
    private let cameraManager = CameraManager()
    
    init() {
        cameraManager.delegate = self
    }
    
    struct Configurator {
        let isPreparing: Bool
        let isCapturing: Bool
        let image: UIImage?
        let currentFrame: Int
        let totalFrames: Int
        let frameCount: Float
        let exposureTimeIndex: Int
        let isoIndex: Int
        let countdown: Int
        
        func build() -> CameraViewModel {
            let result = CameraViewModel()
            result.isPreparingCapture = isPreparing
            result.isCapturing = isCapturing
            result.image = image
            result.currentFrame = currentFrame
            result.totalFrames = totalFrames
            result.frameCount = frameCount
            result.exposureTimeIndex = Float(exposureTimeIndex)
            result.isoIndex = Float(isoIndex)
            result.captureCountdown = countdown
            return result
        }
    }

    @Published
    var image: UIImage? = nil
    
    var hasImage: Bool { return image != nil }
    
    @Published
    var isCapturing: Bool = false
    
    @Published
    var currentFrame: Int = 0
    
    @Published
    var totalFrames: Int = 0
    
    @Published
    var frameCount: Float = 1
    
    @Published
    var exposureTimeIndex: Float = 0
    
    @Published
    var isoIndex: Float = 0
    
    @Published
    var focus: Float = 0 {
        didSet {
            adjustFocus()
        }
    }
    
    @Published
    var isPreparingCapture: Bool = false
    
    @Published
    var captureCountdown: Int = 0
    
    var captureSession: AVCaptureSession { return cameraManager.captureSession }
    
    func frameReceived(image: UIImage?, frame: Int, total: Int) {
        if !isCapturing { return }
        self.image = image
        NSLog("frameReceived frame=\(frame) of \(total), size:\(image?.size.width ?? 0)x\(image?.size.height ?? 0)")
        self.currentFrame = frame
        self.totalFrames = total
    }
    
    func prepareCapture() {
        if isCapturing || isPreparingCapture { return }
        isPreparingCapture = true
        captureCountdown = 3
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            self.countdown()
        }
    }
    
    func countdown() {
        if !isPreparingCapture { return }
        captureCountdown -= 1
        if captureCountdown == 0 {
            isPreparingCapture = false
            startCapture()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.countdown()
            }
        }
    }
    
    func cancel() {
        if isCapturing {
            isCapturing = false
            totalFrames = 0
            cameraManager.cancelCapture()
        }
        else if isPreparingCapture {
            isPreparingCapture = false
        }
    }
    
    func startCapture() {
        if isCapturing { return }
        self.currentFrame = 0
        self.totalFrames = Int(frameCount)
        cameraManager.captureSequence(frameCount: Int(frameCount), duration: Double(exposureValues[Int(exposureTimeIndex)]), iso: Float(isoValues[Int(isoIndex)]), focus: focus)
    }
    
    func savePhoto() {
        guard let image = image else { return }
        UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        NSLog("saved photo")
    }
    
    func captureStarted() {
        isCapturing = true
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func captureEnded() {
        isCapturing = false
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    private func adjustFocus() {
        cameraManager.setFocus(value: focus)
    }
}

let isoValues: [Int] = [
    100, 200, 400, 800, 1600, 3200
]

let exposureValues: [Float] = [
    1/60, 1/50, 1/40, 1/30, 1/20, 1/10, 1/5, 1/4, 1/3, 1/2, 1, 2, 3, 5
]

let exposureStringValues: [String] = [
    "1/60", "1/50", "1/40", "1/30", "1/20", "1/10", "1/5", "1/4", "1/3", "1/2", "1", "2", "3", "5"
]
