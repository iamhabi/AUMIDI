//
//  AudioDevice.swift
//  AUMIDI
//
//  Created by habi on 2/28/24.
//

import Foundation
import CoreAudio

public class AudioDevice: Identifiable {
    public var audioDeviceID: AudioDeviceID
    
    public var hasOutput: Bool {
        get {
            getHasOutput()
        }
    }
    
    public var uid: String? {
        get {
            getUID()
        }
    }
    
    public var name: String? {
        get {
            getName()
        }
    }
    
    init(deviceID: AudioDeviceID) {
        self.audioDeviceID = deviceID
    }
    
    private func getHasOutput() -> Bool {
        var address: AudioObjectPropertyAddress = AudioUtils.createAudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeOutput
        )

        var propSize: UInt32 = MemoryLayout<CFString?>.u_size
        
        if AudioObjectGetPropertyDataSize(
            self.audioDeviceID,
            &address,
            0,
            nil,
            &propSize
        ) != 0 {
            return false
        }

        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity:Int(propSize))
        
        if AudioUtils.getData(
            AudioDeviceID: self.audioDeviceID,
            Address: address,
            DataSize: propSize,
            Data: bufferList
        ) != 0 {
            return false
        }

        let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
        
        for bufferNum in 0..<buffers.count {
            if buffers[bufferNum].mNumberChannels > 0 {
                return true
            }
        }

        return false
    }

    private func getUID() -> String? {
        let address: AudioObjectPropertyAddress = AudioUtils.createAudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID
        )

        var uid: CFString? = nil
        let propSize: UInt32 = MemoryLayout<CFString?>.u_size
        
        if AudioUtils.getData(
            AudioDeviceID: self.audioDeviceID,
            Address: address,
            DataSize: propSize,
            Data: &uid
        ) != 0 {
            return nil
        }

        return uid as String?
    }

    private func getName() -> String? {
        let address: AudioObjectPropertyAddress = AudioUtils.createAudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString
        )

        var name: CFString? = nil
        let propSize: UInt32 = MemoryLayout<CFString?>.u_size
        
        if AudioUtils.getData(
            AudioDeviceID: self.audioDeviceID,
            Address: address,
            DataSize: propSize,
            Data: &name
        ) != 0 {
            return nil
        }

        return name as String?
    }
}

extension MemoryLayout {
    public static var u_size: UInt32 {
        get {
            UInt32(self.size)
        }
    }
}

