//
//  ContentView.swift
//  AUMIDI
//
//  Created by habi on 2/28/24.
//

import SwiftUI
import CoreAudioKit

class AudioDeviceViewModel: ObservableObject {
    @Published var list: [AudioDevice] = []
    @Published var currentIndex: Int = 0
}

struct ContentView: View {
    
    @ObservedObject private var outputDeviceViewModel: AudioDeviceViewModel
    
    init() {
        self.outputDeviceViewModel = AudioDeviceViewModel()
        
        updateDefaultOutputDevice()
        
        addDefaultOutputDeviceChangeListener()
        addDevicesChangeListener()
    }
    
    var body: some View {
        HStack {
            Picker("Default Output Device", selection: $outputDeviceViewModel.currentIndex) {
                ForEach(
                    Array(zip(outputDeviceViewModel.list.indices, outputDeviceViewModel.list)),
                    id: \.0
                ) { index, device in
                    if let name = device.name {
                        Text(name).tag(index)
                    }
                }
            }
            .pickerStyle(.menu)
            .onChange(of: outputDeviceViewModel.currentIndex) { _, index in
                let selectedDevice = outputDeviceViewModel.list[index]
                
                changeDefaultOutputDevice(AudioDevice: selectedDevice)
            }
        }
        .padding()
    }
    
    private func changeDefaultOutputDevice(AudioDevice audioDevice: AudioDevice) {
        var address = AudioUtils.createAudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice
        )
        
        var audioDeviceID = audioDevice.audioDeviceID
        let propSize: UInt32 = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            propSize,
            &audioDeviceID
        )
    }
    
    private func updateDefaultOutputDevice() {
        let defaultOutputDevice = AudioUtils.getDefaultOutputDevice()
        let outputDevices = AudioUtils.getOutputDevices()

        let outputIndex = outputDevices.firstIndex(where: {$0.audioDeviceID == defaultOutputDevice.audioDeviceID}) ?? 0

        outputDeviceViewModel.list = outputDevices
        outputDeviceViewModel.currentIndex = outputIndex
    }
    
    private func addDefaultOutputDeviceChangeListener() {
        AudioUtils.setListener(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            DispatchQueue: DispatchQueue.main,
            listener: {
                updateDefaultOutputDevice()
            }
        )
    }
    
    private func addDevicesChangeListener() {
        AudioUtils.setListener(
            mSelector: kAudioHardwarePropertyDevices,
            DispatchQueue: DispatchQueue.main,
            listener: {
                updateDefaultOutputDevice()
            }
        )
    }
}

#Preview {
    ContentView()
}
