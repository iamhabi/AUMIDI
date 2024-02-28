//
//  AUMIDIApp.swift
//  AUMIDI
//
//  Created by habi on 2/28/24.
//

import SwiftUI

@main
struct AUMIDIApp: App {
    var body: some Scene {
        MenuBarExtra("MIDI") {
            VStack {
                ContentView()
                
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit")
                }
            }
            .padding()
        }
        .menuBarExtraStyle(.window)
    }
}
