//
//  BattakoreyMenu.swift
//  battakorey
//
//  Created by Cocoa on 08/07/2021.
//

import Foundation
import Cocoa

class BattakoreyMenu: NSMenu {
    var info: NSDictionary? {
        didSet {
            if self.items.count == 0 {
                for _ in 0...6 {
                    let i = NSMenuItem.init()
                    i.view = BattakoreyMenuItem.init(frame: NSMakeRect(0, 0, 200, 25))
                    self.addItem(i)
                }
                
                let i = NSMenuItem.separator()
                self.addItem(i)
                
                let quitItem = NSMenuItem.init()
                quitItem.title = "Quit"
                quitItem.target = self
                quitItem.action = #selector(quit)
                quitItem.keyEquivalent = "q"
                self.addItem(quitItem)
            }

            var view = self.items[0].view as! BattakoreyMenuItem
            view.update("Battery", String.init(format: "%d%%", self.info?["CurrentCapacity"] as! Int))
            
            view = self.items[1].view as! BattakoreyMenuItem
            view.update("Capacity", String.init(format: "%d mAH", self.info?["AppleRawCurrentCapacity"] as! Int))
            
            view = self.items[2].view as! BattakoreyMenuItem
            view.update("Max Capacity", String.init(format: "%d mAH", self.info?["AppleRawMaxCapacity"] as! Int))
            
            view = self.items[3].view as! BattakoreyMenuItem
            view.update("Cycles", String.init(format: "%d", self.info?["CycleCount"] as! Int))
        
            
            view = self.items[4].view as! BattakoreyMenuItem
            view.update("Temperature", String.init(format: "%.2f °C", (self.info?["Temperature"] as! Float) / 100))
            
            let charging = self.info?["IsCharging"] as! Bool
            view = self.items[5].view as! BattakoreyMenuItem
            view.update("Is charging", charging ? "YES" : "NO")
            
            var remainingMinutes = self.info?["TimeRemaining"] as! Float
            view = self.items[6].view as! BattakoreyMenuItem
            if remainingMinutes < 65535 {
                let remainingHours = Int(remainingMinutes / 60)
                remainingMinutes -= Float(remainingHours * 60)
                view.update(String.init(format: "Time to %@", charging ? "full" : "empty"), String.init(format: "%d h %.0f m", remainingHours, remainingMinutes))
            } else {
                view.update(String.init(format: "Time to %@", charging ? "full" : "empty"), "Calculating...")
            }
        }
    }
    
    @objc func quit() {
        NSApp.terminate(nil)
    }
}

class BattakoreyMenuItem: NSView {
    var titleLabel: NSTextField
    var detailLabel: NSTextField
    
    let rightAlignment: NSParagraphStyle = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        paragraphStyle.baseWritingDirection = .natural
        return paragraphStyle
    }()
    
    required init?(coder: NSCoder) {
        self.titleLabel = NSTextField.init()
        self.detailLabel = NSTextField.init()
        super.init(coder: coder)
    }
    
    override init(frame frameRect: NSRect) {
        let margin: CGFloat = 10
        self.titleLabel = NSTextField.init(frame: NSMakeRect(margin, 0, frameRect.width / 2 - margin, frameRect.height))
        self.detailLabel = NSTextField.init(frame: NSMakeRect(frameRect.width / 2, 0, frameRect.width / 2 - margin, frameRect.height))
        self.titleLabel.cell = BattakoreyTextFieldCell()
        self.titleLabel.isBezeled = false
        self.titleLabel.backgroundColor = NSColor.clear
        self.titleLabel.isEditable = false
        self.titleLabel.isSelectable = false
        
        self.detailLabel.cell = BattakoreyTextFieldCell()
        self.detailLabel.isBezeled = false
        self.detailLabel.backgroundColor = NSColor.clear
        self.detailLabel.isEditable = false
        self.detailLabel.isSelectable = false
        
        super.init(frame: frameRect)
        self.addSubview(self.titleLabel)
        self.addSubview(self.detailLabel)
    }
    
    func update(_ title: String, _ value: String) {
        var r = NSMutableAttributedString.init(string: title)
        r.addAttribute(.foregroundColor, value: NSColor.black, range: NSMakeRange(0, title.count))
        self.titleLabel.attributedStringValue = r
        
        r = NSMutableAttributedString.init(string: value)
        r.addAttribute(.foregroundColor, value: NSColor.gray, range: NSMakeRange(0, value.count))
        r.addAttribute(.paragraphStyle, value: rightAlignment, range: NSMakeRange(0, value.count))
        self.detailLabel.attributedStringValue = r
    }
}

class BattakoreyTextFieldCell: NSTextFieldCell {
    func adjustedFrame(toVerticallyCenterText rect: NSRect) -> NSRect {
        // super would normally draw text at the top of the cell
        var titleRect = super.titleRect(forBounds: rect)
        
        let minimumHeight = self.cellSize(forBounds: rect).height
        titleRect.origin.y += (titleRect.height - minimumHeight) / 2
        titleRect.size.height = minimumHeight

        return titleRect
    }

    override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
        super.edit(withFrame: adjustedFrame(toVerticallyCenterText: rect), in: controlView, editor: textObj, delegate: delegate, event: event)
    }

    override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
        super.select(withFrame: adjustedFrame(toVerticallyCenterText: rect), in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
    }

    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.drawInterior(withFrame: adjustedFrame(toVerticallyCenterText: cellFrame), in: controlView)
    }

    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.draw(withFrame: cellFrame, in: controlView)
    }
}
