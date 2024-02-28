//
//  AudioUtils.swift
//  AUMIDI
//
//  Created by habi on 2/28/24.
//

import Foundation
import CoreAudio

class AudioUtils {
    public static func getOutputDevices() -> [AudioDevice] {
        var list = [AudioDevice]()
        let devices = getAllDevices()
        
        for device in devices {
            if device.hasOutput
                && !isAggregateDevice(AudioDeviceID: device.audioDeviceID) {
                list.append(device)
            }
        }
        
        return list
    }
    
    public static func getDefaultOutputDevice() -> AudioDevice {
        var defaultOutputDeviceID = kAudioDeviceUnknown
        var defaultOutputDeviceIDSize = UInt32(MemoryLayout.size(ofValue: defaultOutputDeviceID))
        
        var getDefaultOutputDevicePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &getDefaultOutputDevicePropertyAddress,
            0,
            nil,
            &defaultOutputDeviceIDSize,
            &defaultOutputDeviceID
        )
         
        return AudioDevice(deviceID: defaultOutputDeviceID)
    }
    
    public static func getAllDevices() -> [AudioDevice] {
        var list = [AudioDevice]()
        
        var propsize: UInt32 = 0

        var address: AudioObjectPropertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDevices),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain)
        )
        
        let addressSize: UInt32 = UInt32(MemoryLayout<AudioObjectPropertyAddress>.size)

        if AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            addressSize,
            nil,
            &propsize
        ) != 0 {
            return list
        }

        let audioDeviceCount = Int(propsize / UInt32(MemoryLayout<AudioDeviceID>.size))
        var audioDeviceIDs = [AudioDeviceID]()
        
        for _ in 0..<audioDeviceCount {
            audioDeviceIDs.append(AudioDeviceID())
        }

        if AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propsize,
            &audioDeviceIDs
        ) != 0 {
            return list
        }

        for i in 0..<audioDeviceCount {
            list.append(AudioDevice(deviceID: audioDeviceIDs[i]))
        }
        
        return list
    }
    
    private static let deviceStateChangeQueue = DispatchQueue(label: "com.iamhabi.AUMIDI.AudioObjectChangeListenerBlock")
    
    public static func createAudioObjectPropertyAddress(
        mSelector: AudioObjectPropertySelector,
        mScope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
        mElement: AudioObjectPropertyElement = kAudioObjectPropertyElementMain
    ) -> AudioObjectPropertyAddress {
        return AudioObjectPropertyAddress(
            mSelector: mSelector,
            mScope: mScope,
            mElement: mElement
        )
    }
    
    public static func getData(
        AudioDeviceID audioDeviceID: AudioDeviceID,
        Address propAddress: AudioObjectPropertyAddress,
        DataSize ioDataSize: UInt32,
        Data outData: UnsafeMutableRawPointer
    ) -> OSStatus {
        var address = propAddress
        var dataSize = ioDataSize
        
        return AudioObjectGetPropertyData(
            audioDeviceID,
            &address,
            0,
            nil,
            &dataSize,
            outData
        )
    }
    
    public static func setListener(
        mSelector: AudioObjectPropertySelector,
        DispatchQueue inDispatchQueue: dispatch_queue_t = deviceStateChangeQueue,
        listener: @escaping () -> Void
    ) {
        var address = createAudioObjectPropertyAddress(mSelector: mSelector)
        
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            inDispatchQueue,
            { (_: UInt32, _: UnsafePointer<AudioObjectPropertyAddress>) in
                listener()
            }
        )
    }
    
    public static func isAggregateDevice(AudioDeviceID audioDeviceID: AudioDeviceID) -> Bool {
        let address = createAudioObjectPropertyAddress(mSelector: kAudioDevicePropertyTransportType)
        
        var deviceType: AudioDevicePropertyID = 0
        
        let propSize: UInt32 = UInt32(MemoryLayout<AudioDevicePropertyID>.size)
        
        if getData(
            AudioDeviceID: audioDeviceID,
            Address: address,
            DataSize: propSize,
            Data: &deviceType
        ) != 0 {
            return false
        }
        
        return deviceType == kAudioDeviceTransportTypeAggregate
    }
}
