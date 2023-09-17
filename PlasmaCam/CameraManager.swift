//
//  CameraManager.swift
//  PlasmaCam
//
//  Created by Aubrey Goodman on 9/16/23.
//

import Foundation
import AVFoundation
import UIKit

protocol CameraManagerDelegate {
    func captureStarted()
    func frameReceived(image: UIImage?, frame: Int, total: Int)
    func captureEnded()
}

class CameraManager: NSObject {
    let captureSession: AVCaptureSession = AVCaptureSession()
    let stillOutput = AVCapturePhotoOutput()
    let captureDevice: AVCaptureDevice?
    let valid: Bool
    
    var delegate: CameraManagerDelegate? = nil
    
    private var compositeImage: UIImage? = nil
    
    private var isCapturing: Bool = false
    private var currentFrame: Int = -1
    private var totalFrames: Int = 0

    override init() {
        guard let device = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) else {
            valid = false
            captureDevice = nil
            super.init()
            return
        }
        captureDevice = device
        do {
            let videoInput = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                valid = false
                super.init()
                return
            }
            if captureSession.canAddOutput(stillOutput) {
                captureSession.addOutput(stillOutput)
            } else {
                valid = false
                super.init()
                return
            }
            captureSession.sessionPreset = .photo
            valid = true
        } catch {
            valid = false
        }
        super.init()
        captureSession.startRunning()
    }
    
    func setFocus(value: Float) {
        guard let device = captureDevice, let _ = try? device.lockForConfiguration() else { return }
        device.setFocusModeLocked(lensPosition: value) { _ in
            DispatchQueue.main.async {
                device.unlockForConfiguration()
            }
        }
    }
    
    func captureSequence(frameCount: Int, duration: Double, iso: Float, focus: Float) {
        DispatchQueue.main.async {
            if self.isCapturing { return }
            self.compositeImage = nil
            self.totalFrames = frameCount
            self.currentFrame = 0
            self.startCapturing(duration: duration, iso: iso, focus: focus)
        }
    }
    
    func cancelCapture() {
        DispatchQueue.main.async {
            if !self.isCapturing { return }
            self.totalFrames = 0
            self.isCapturing = false
            self.delegate?.captureEnded()
        }
    }
    
    private func startCapturing(duration: Double, iso: Float, focus: Float) {
        delegate?.captureStarted()
        // setup device exposure
        guard let device = captureDevice, let _ = try? device.lockForConfiguration() else { return }
        isCapturing = true
        device.exposureMode = .locked
        device.focusMode = .locked
        let durationTime: CMTime = CMTime(seconds: duration, preferredTimescale: 1000)
        let clampedIso = max(device.activeFormat.minISO, min(device.activeFormat.maxISO, iso))
        NSLog("capturing with duration=\(durationTime.value), iso=\(clampedIso)")
        device.setFocusModeLocked(lensPosition: focus) { _ in
            DispatchQueue.main.async {
                device.setExposureModeCustom(duration: durationTime, iso: clampedIso) { _ in
                    DispatchQueue.main.async {
                        device.unlockForConfiguration()
                        self.captureNext()
                    }
                }
            }
        }
    }
    
    private func captureNext() {
        NSLog("captureNext(\(currentFrame) of \(totalFrames))")
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        stillOutput.isHighResolutionCaptureEnabled = true
        stillOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            DispatchQueue.main.async {
                self.delegate?.frameReceived(image: nil, frame: -1, total: 0)
            }
            return
        }
        DispatchQueue.main.async {
            NSLog("received bytes=\(data.count), size=\(image.size.width)x\(image.size.height)")
            if let existing = self.compositeImage {
//                let newImage = PlasmaCam.compositeImage(image1: existing, image2: image)
                let newImage = existing.mergeWith(topImage: image)
                self.compositeImage = newImage
            } else {
                self.compositeImage = image
            }
            self.delegate?.frameReceived(image: self.compositeImage, frame: self.currentFrame, total: self.totalFrames)
            if self.currentFrame < self.totalFrames {
                self.currentFrame += 1
                self.captureNext()
            } else {
                self.isCapturing = false
                self.delegate?.captureEnded()
            }
        }
    }
}

//
// Return composite image of image2 overlayed on image1
//
func compositeImage(image1: UIImage, image2: UIImage, blendMode: CGBlendMode = .plusLighter) -> UIImage? {
    let bounds1 = CGRect(x: 0, y: 0, width: image1.size.width, height: image1.size.height)
    let bounds2 = CGRect(x: 0, y: 0, width: image2.size.width, height: image2.size.height)
//    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
    guard let img1 = image1.cgImage, let img2 = image2.cgImage else { return nil }
    let ctx = CGContext(data: nil,
                        width: img1.width,
                        height: img1.height,
                        bitsPerComponent: img1.bitsPerComponent,
                        bytesPerRow: img1.bytesPerRow,
                        space: img1.colorSpace!,
                        bitmapInfo: bitmapInfo.rawValue)!
    ctx.draw(img1, in: bounds1)
    ctx.setBlendMode(blendMode)
    ctx.draw(img2, in: bounds2)
    guard let comp = ctx.makeImage() else { return nil }
    return UIImage(cgImage: comp)
}

extension UIImage {
  func mergeWith(topImage: UIImage) -> UIImage {
    let bottomImage = self

    UIGraphicsBeginImageContext(size)


    let areaSize = CGRect(x: 0, y: 0, width: bottomImage.size.width, height: bottomImage.size.height)
    bottomImage.draw(in: areaSize)

    topImage.draw(in: areaSize, blendMode: .plusLighter, alpha: 1.0)

    let mergedImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return mergedImage
  }
}
