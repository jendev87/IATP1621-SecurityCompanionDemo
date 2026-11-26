//
//  SecurityCompanionDemoApp.swift
//  SecurityCompanionDemo
//
//  Created by thinkpalm on 10/11/26.
//

import SwiftUI

@main
struct SecurityCompanionDemoApp: App {
    
    @State private var container = AppContainer()
    
    var body: some Scene {
        WindowGroup {
            ContentView(container: container)
        }
    }
}
