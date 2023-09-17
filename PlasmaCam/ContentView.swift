//
//  ContentView.swift
//  PlasmaCam
//
//  Created by Aubrey Goodman on 9/16/23.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @ObservedObject var viewModel: CameraViewModel
    
    var body: some View {
        ZStack {
        VStack() {
            HStack {
                Spacer()
                if viewModel.isCapturing {
                    Text("Capture in Progress...").padding(20)
                    Button(action: { viewModel.cancel() }) {
                        Text("Cancel").padding()
                    }
                } else if !viewModel.isPreparingCapture {
                    Button(action: {
                        viewModel.prepareCapture()
                    }) {
                        Text("Start Capture").padding(20)
                    }
                    .background(.blue)
                    .foregroundColor(.white)
                }
                Spacer()
                if !viewModel.isCapturing && viewModel.hasImage {
                    Button(action: { viewModel.savePhoto() }) {
                        Text("Save Photo").padding()
                    }
                }
                Spacer()
            }
            if viewModel.isCapturing {
                Progress(viewModel: viewModel)
            } else {
                FrameCountControl(viewModel: viewModel)
                ExposureControl(viewModel: viewModel)
                ISOControl(viewModel: viewModel)
                FocusControl(viewModel: viewModel)
            }
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                // TODO: camera preview
                PreviewViewWrapper(viewModel: viewModel)
            }
            Spacer()
        }
        if viewModel.isPreparingCapture {
            Countdown(viewModel: viewModel)
        }
        }
    }
}

struct FrameCountControl: View {
    @ObservedObject var viewModel: CameraViewModel
    
    var body: some View {
        VStack {
            HStack {
                Text("Frame Count: ")
                Spacer()
                Text("\(Int(viewModel.frameCount))")
            }
            Slider(value: $viewModel.frameCount, in: 1...50, step: 1)
        }.padding()
    }
}

struct ExposureControl: View {
    @ObservedObject var viewModel: CameraViewModel
    
    var body: some View {
        VStack {
            HStack {
                Text("Exposure Time (sec): ")
                Spacer()
                Text("\(exposureStringValues[Int(viewModel.exposureTimeIndex)])")
            }
            Slider(value: $viewModel.exposureTimeIndex, in: 0...Float(exposureValues.count-1), step: 1)
        }.padding()
    }
}

struct ISOControl: View {
    @ObservedObject var viewModel: CameraViewModel
    
    var body: some View {
        VStack {
            HStack {
                Text("ISO: ")
                Spacer()
                Text("\(isoValues[Int(viewModel.isoIndex)])")
            }
            Slider(value: $viewModel.isoIndex, in: 0...Float(isoValues.count-1), step: 1)
        }.padding()
    }
}

struct FocusControl: View {
    @ObservedObject var viewModel: CameraViewModel
    
    var body: some View {
        VStack {
            HStack {
                Text("Focus: ")
                Spacer()
                Text("\(viewModel.focus)")
            }
            Slider(value: $viewModel.focus, in: 0...1, step: 0.01)
        }.padding()
    }
}

struct Progress: View {
    @ObservedObject var viewModel: CameraViewModel
    
    var body: some View {
        HStack {
            Spacer()
            Text("Frame \(viewModel.currentFrame + 1) of \(viewModel.totalFrames)")
            Spacer()
        }
    }
}

struct Countdown: View {
    @ObservedObject var viewModel: CameraViewModel
    
    var body: some View {
        VStack {
            Text("Preparing...")
                .bold()
                .foregroundColor(.white)
                .padding()
            Text("\(viewModel.captureCountdown)")
                .foregroundColor(.white)
                .font(.system(size: 64))
                .padding()
            Button(action: { viewModel.cancel() }) {
                Text("Cancel").foregroundColor(.blue).padding(20)
            }.background(.white).padding(20)
        }
        .background(.blue.opacity(0.75))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: CameraViewModel.Configurator(
            isPreparing: false,
            isCapturing: true,
            image: UIImage(named: "placeholder"),
            currentFrame: 2,
            totalFrames: 5,
            frameCount: 25,
            exposureTimeIndex: 3,
            isoIndex: 4,
            countdown: 3
        ).build())
    }
}
