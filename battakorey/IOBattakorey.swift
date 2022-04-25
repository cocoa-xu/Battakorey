//
//  IOBattakorey.swift
//  battakorey
//
//  Created by Cocoa on 08/07/2021.
//

import Foundation
import IOKit
import CoreFoundation


func BattakoeryInfo() -> Unmanaged<CFMutableDictionary>? {
    var prop: Unmanaged<CFMutableDictionary>? = nil
    var smartBattakoreyPort: mach_port_t = 0
    var masterPort: mach_port_t = 0

    guard (IOMasterPort(kIOMasterPortDefault, &masterPort) == KERN_SUCCESS) else { return nil }
    let matchingDict = IOServiceMatching("AppleSmartBattery")
    smartBattakoreyPort = IOServiceGetMatchingService(kIOMasterPortDefault, matchingDict)
    guard smartBattakoreyPort != 0 else { return nil }
    IORegistryEntryCreateCFProperties(smartBattakoreyPort, &prop, kCFAllocatorDefault, 0)
    return prop
}
