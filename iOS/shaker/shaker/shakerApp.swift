//
//  shakerApp.swift
//  shaker
//
//  Created by Stan Miasnikov on 11/19/22.
//

import SwiftUI

@main
struct shakerApp: App {
    
    @StateObject private var modelData = ShakerModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(modelData)
        }
    }
    
}
