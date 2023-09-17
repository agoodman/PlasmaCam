//
//  PlasmaCamApp.swift
//  PlasmaCam
//
//  Created by Aubrey Goodman on 9/16/23.
//

import SwiftUI

@main
struct PlasmaCamApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: CameraViewModel())
        }
    }
}
