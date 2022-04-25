//
//  AppDelegate.swift
//  battakorey
//
//  Created by Cocoa on 06/07/2021.
//

import Cocoa


@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var battakoery: BattakoreyImage
    var updateTimer: Timer?
    var menu: BattakoreyMenu
    
    required override init() {
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: BattakoreyImage.baseWidth)
        self.battakoery = BattakoreyImage.init(frame: NSMakeRect(0, 0, BattakoreyImage.baseWidth, BattakoreyImage.baseHeight))
        self.menu = BattakoreyMenu.init()
        self.statusBarItem.menu = self.menu
        if let button = self.statusBarItem.button {
            button.addSubview(self.battakoery)
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] timer in
            let info = BattakoeryInfo()
            if info != nil {
                guard let ret = info?.takeRetainedValue() as NSDictionary? else { return }
                let current = ret["CurrentCapacity"] as! CGFloat
                let isCharing = ret["IsCharging"] as! Bool
                if self.battakoery.percentage != current {
                    self.battakoery.percentage = current
                }
                if self.battakoery.isCharging != isCharing {
                    self.battakoery.isCharging = isCharing
                }
                self.menu.info = ret
            }
        }
        self.updateTimer?.fire()
    }
}
