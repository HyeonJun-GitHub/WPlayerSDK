//
//  CASound.m
//  Wally
//
//  Created by 김현준 on 07/01/2019.
//  Copyright © 2019 wally. All rights reserved.
//

#import "CASound.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation CASound
#if CASoundControl

void SetUpAudioDevice(void) {
    
    //    [self setAudioSystem:[PriAudioSystem new]];
    //
    //    [[self audioSystem] setupDevicesNotification];
    //    [[self audioSystem] setupDefaultChangeNotification];
    
    //    NSString *soundOutDevice = CAudioDevice();
    NSString *deviceName = @"";
    //    if ([soundOutDevice isEqual:@"internal speakers"]) {
    //        deviceName = @"Built-in Output";
    //    }
    //
    //    if ([soundOutDevice isEqual:@"headphones"]) {
    deviceName = @"Built-in Output";
    //    }
    
    AudioOutput(deviceName);
}

BOOL AudioOutput(NSString *targetDevice) {
#if !TARGET_OS_IPHONE
    AudioObjectPropertyAddress  propertyAddress;
    AudioObjectID               *deviceIDs;
    UInt32                      propertySize;
    NSInteger                   numDevices;
    
    propertyAddress.mSelector = kAudioHardwarePropertyDevices;
    propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propertyAddress.mElement = kAudioObjectPropertyElementMaster;
    
    // enumerate all current/valid devices
    if (AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propertySize) == noErr) {
        numDevices = propertySize / sizeof(AudioDeviceID);
        deviceIDs = (AudioDeviceID *)calloc(numDevices, sizeof(AudioDeviceID));
        
        if (AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propertySize, deviceIDs) == noErr) {
            AudioObjectPropertyAddress      deviceAddress;
            char                            deviceName[64];
            char                            manufacturerName[64];
            
            for (NSInteger idx=0; idx<numDevices; idx++) {
                propertySize = sizeof(deviceName);
                deviceAddress.mSelector = kAudioDevicePropertyDeviceName;
                deviceAddress.mScope = kAudioObjectPropertyScopeGlobal;
                deviceAddress.mElement = kAudioObjectPropertyElementMaster;
                
                if (AudioObjectGetPropertyData(deviceIDs[idx], &deviceAddress, 0, NULL, &propertySize, deviceName) == noErr) {
                    propertySize = sizeof(manufacturerName);
                    deviceAddress.mSelector = kAudioDevicePropertyDeviceManufacturer;
                    deviceAddress.mScope = kAudioObjectPropertyScopeGlobal;
                    deviceAddress.mElement = kAudioObjectPropertyElementMaster;
                    if (AudioObjectGetPropertyData(deviceIDs[idx], &deviceAddress, 0, NULL, &propertySize, manufacturerName) == noErr) {
                        CFStringRef     uidString;
                        
                        propertySize = sizeof(uidString);
                        deviceAddress.mSelector = kAudioDevicePropertyDeviceUID;
                        deviceAddress.mScope = kAudioObjectPropertyScopeGlobal;
                        deviceAddress.mElement = kAudioObjectPropertyElementMaster;
                        if (AudioObjectGetPropertyData(deviceIDs[idx], &deviceAddress, 0, NULL, &propertySize, &uidString) == noErr) {
                            CFRelease(uidString);
                        }
                        NSString *name = [NSString stringWithCString:deviceName encoding:NSUTF8StringEncoding];
                        if ([name rangeOfString:targetDevice].location != NSNotFound) {
                            propertyAddress.mSelector = kAudioHardwarePropertyDefaultOutputDevice;
                            propertyAddress.mScope = kAudioDevicePropertyScopeOutput;
                            propertyAddress.mElement = kAudioObjectPropertyElementMaster;
                            
                            return AudioObjectSetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, sizeof(AudioDeviceID), &deviceIDs[idx]) == noErr;
                        }
                    }
                }
            }
        }
        
        free(deviceIDs);
    }
    #endif
    return false;
}

NSString *CAudioDevice(void) {
#if !TARGET_OS_IPHONE
    AudioDeviceID deviceID;
    UInt32 size = sizeof(deviceID);
    OSStatus err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultSystemOutputDevice, &size, &deviceID);
    NSCAssert((err == noErr), @"AudioHardwareGetProperty Failed kAudioHardwarePropertyDefaultSystemOutputDevice");
    
    UInt32 dataSource;
    size = sizeof(dataSource);
    err = AudioDeviceGetProperty(deviceID, 0, 0, kAudioDevicePropertyDataSource, &size, &dataSource);
    NSCAssert((err == noErr), @"AudioDeviceGetProperty Failed kAudioDevicePropertyDataSource");
    
    //'ispk' => 스피커
    //'hdpn' => 해드폰
    if(dataSource == 'ispk') {
        return @"internal speakers";
    } if(dataSource == 'hdpn') {
        return @"headphones";
    } else {
        return @"Unknow";
    }
#else
    return @"";
#endif
}
#endif

@end
