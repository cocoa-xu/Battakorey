//
//  BattakoreyImage.swift
//  battakorey
//
//  Created by Cocoa on 08/07/2021.
//

import Foundation
import AppKit


/// Status for Battakorey
enum BattakoreyStatus {
    /// 70% - 100%
    case Happy
    /// 40% - 70%
    case Normal
    /// 20% - 40%
    case Hungry
    /// 0% - 20%
    case Starving
    /// unknown
    case Unknown
}

enum BattakoreyChargingStatus {
    case Charging
    case NotCharging
    case Unknown
}

class BattakoreyImage: NSView {
    var percentage: CGFloat = 100.0 {
        didSet {
            self.needsDisplay = true
        }
    }
    
    var isCharging: Bool = false {
        didSet {
            self.needsDisplay = true
        }
    }
    
    let takoShapePath: NSBezierPath = {
        let takoShapePath = NSBezierPath()
        takoShapePath.move(to: NSPoint(x: 15.72, y: 1.05))
        takoShapePath.curve(to: NSPoint(x: 14.25, y: 1.42), controlPoint1: NSPoint(x: 14.92, y: 1.19), controlPoint2: NSPoint(x: 14.62, y: 1.26))
        takoShapePath.curve(to: NSPoint(x: 13.74, y: 1.69), controlPoint1: NSPoint(x: 14.03, y: 1.52), controlPoint2: NSPoint(x: 13.8, y: 1.64))
        takoShapePath.curve(to: NSPoint(x: 13.31, y: 1.71), controlPoint1: NSPoint(x: 13.63, y: 1.78), controlPoint2: NSPoint(x: 13.61, y: 1.78))
        takoShapePath.curve(to: NSPoint(x: 9.99, y: 1.71), controlPoint1: NSPoint(x: 12.51, y: 1.53), controlPoint2: NSPoint(x: 10.87, y: 1.52))
        takoShapePath.curve(to: NSPoint(x: 9.43, y: 1.67), controlPoint1: NSPoint(x: 9.61, y: 1.79), controlPoint2: NSPoint(x: 9.61, y: 1.79))
        takoShapePath.curve(to: NSPoint(x: 7.65, y: 1.15), controlPoint1: NSPoint(x: 8.94, y: 1.34), controlPoint2: NSPoint(x: 8.59, y: 1.23))
        takoShapePath.curve(to: NSPoint(x: 5.78, y: 1.32), controlPoint1: NSPoint(x: 7.2, y: 1.1), controlPoint2: NSPoint(x: 6.91, y: 1.13))
        takoShapePath.curve(to: NSPoint(x: 4.37, y: 1.91), controlPoint1: NSPoint(x: 5.25, y: 1.41), controlPoint2: NSPoint(x: 4.55, y: 1.71))
        takoShapePath.curve(to: NSPoint(x: 3.53, y: 2.03), controlPoint1: NSPoint(x: 4.28, y: 2.02), controlPoint2: NSPoint(x: 4.25, y: 2.03))
        takoShapePath.curve(to: NSPoint(x: 1.16, y: 2.55), controlPoint1: NSPoint(x: 2.39, y: 2.03), controlPoint2: NSPoint(x: 1.46, y: 2.23))
        takoShapePath.curve(to: NSPoint(x: 1, y: 2.97), controlPoint1: NSPoint(x: 1.03, y: 2.69), controlPoint2: NSPoint(x: 1, y: 2.76))
        takoShapePath.curve(to: NSPoint(x: 1.71, y: 4.08), controlPoint1: NSPoint(x: 1, y: 3.32), controlPoint2: NSPoint(x: 1.1, y: 3.47))
        takoShapePath.curve(to: NSPoint(x: 2.38, y: 4.77), controlPoint1: NSPoint(x: 2.02, y: 4.37), controlPoint2: NSPoint(x: 2.31, y: 4.68))
        takoShapePath.curve(to: NSPoint(x: 2.76, y: 5.92), controlPoint1: NSPoint(x: 2.45, y: 4.86), controlPoint2: NSPoint(x: 2.6, y: 5.31))
        takoShapePath.curve(to: NSPoint(x: 3.16, y: 7.37), controlPoint1: NSPoint(x: 2.91, y: 6.47), controlPoint2: NSPoint(x: 3.09, y: 7.12))
        takoShapePath.curve(to: NSPoint(x: 3.36, y: 8.15), controlPoint1: NSPoint(x: 3.24, y: 7.61), controlPoint2: NSPoint(x: 3.32, y: 7.97))
        takoShapePath.curve(to: NSPoint(x: 4.39, y: 10.35), controlPoint1: NSPoint(x: 3.43, y: 8.55), controlPoint2: NSPoint(x: 3.87, y: 9.48))
        takoShapePath.curve(to: NSPoint(x: 5.34, y: 12.14), controlPoint1: NSPoint(x: 4.88, y: 11.16), controlPoint2: NSPoint(x: 5.22, y: 11.81))
        takoShapePath.curve(to: NSPoint(x: 5.25, y: 12.89), controlPoint1: NSPoint(x: 5.44, y: 12.42), controlPoint2: NSPoint(x: 5.44, y: 12.42))
        takoShapePath.curve(to: NSPoint(x: 4.85, y: 15.62), controlPoint1: NSPoint(x: 4.95, y: 13.62), controlPoint2: NSPoint(x: 4.76, y: 14.92))
        takoShapePath.curve(to: NSPoint(x: 5.03, y: 16.36), controlPoint1: NSPoint(x: 4.87, y: 15.83), controlPoint2: NSPoint(x: 4.95, y: 16.17))
        takoShapePath.curve(to: NSPoint(x: 6.42, y: 17.5), controlPoint1: NSPoint(x: 5.27, y: 17), controlPoint2: NSPoint(x: 5.59, y: 17.26))
        takoShapePath.curve(to: NSPoint(x: 7.32, y: 17.61), controlPoint1: NSPoint(x: 6.88, y: 17.63), controlPoint2: NSPoint(x: 7, y: 17.64))
        takoShapePath.curve(to: NSPoint(x: 8.16, y: 17.37), controlPoint1: NSPoint(x: 7.76, y: 17.58), controlPoint2: NSPoint(x: 7.98, y: 17.51))
        takoShapePath.curve(to: NSPoint(x: 8.42, y: 16.4), controlPoint1: NSPoint(x: 8.37, y: 17.2), controlPoint2: NSPoint(x: 8.42, y: 17.01))
        takoShapePath.curve(to: NSPoint(x: 8.78, y: 14.49), controlPoint1: NSPoint(x: 8.42, y: 15.85), controlPoint2: NSPoint(x: 8.52, y: 15.32))
        takoShapePath.curve(to: NSPoint(x: 9.06, y: 14.06), controlPoint1: NSPoint(x: 8.93, y: 14.01), controlPoint2: NSPoint(x: 8.91, y: 14.03))
        takoShapePath.curve(to: NSPoint(x: 9.58, y: 14.17), controlPoint1: NSPoint(x: 9.14, y: 14.08), controlPoint2: NSPoint(x: 9.37, y: 14.13))
        takoShapePath.curve(to: NSPoint(x: 10.19, y: 14.32), controlPoint1: NSPoint(x: 9.78, y: 14.21), controlPoint2: NSPoint(x: 10.06, y: 14.28))
        takoShapePath.curve(to: NSPoint(x: 12.49, y: 14.76), controlPoint1: NSPoint(x: 10.85, y: 14.51), controlPoint2: NSPoint(x: 11.7, y: 14.68))
        takoShapePath.curve(to: NSPoint(x: 16.93, y: 14.93), controlPoint1: NSPoint(x: 14.64, y: 14.99), controlPoint2: NSPoint(x: 15.89, y: 15.04))
        takoShapePath.curve(to: NSPoint(x: 18.18, y: 14.81), controlPoint1: NSPoint(x: 17.18, y: 14.91), controlPoint2: NSPoint(x: 17.74, y: 14.85))
        takoShapePath.curve(to: NSPoint(x: 23.14, y: 13.95), controlPoint1: NSPoint(x: 20.17, y: 14.63), controlPoint2: NSPoint(x: 22.09, y: 14.3))
        takoShapePath.curve(to: NSPoint(x: 23.69, y: 13.95), controlPoint1: NSPoint(x: 23.55, y: 13.81), controlPoint2: NSPoint(x: 23.55, y: 13.81))
        takoShapePath.curve(to: NSPoint(x: 23.94, y: 15.57), controlPoint1: NSPoint(x: 23.92, y: 14.21), controlPoint2: NSPoint(x: 23.96, y: 14.47))
        takoShapePath.curve(to: NSPoint(x: 24.01, y: 16.8), controlPoint1: NSPoint(x: 23.93, y: 16.38), controlPoint2: NSPoint(x: 23.94, y: 16.61))
        takoShapePath.curve(to: NSPoint(x: 25.02, y: 17.41), controlPoint1: NSPoint(x: 24.15, y: 17.19), controlPoint2: NSPoint(x: 24.43, y: 17.36))
        takoShapePath.curve(to: NSPoint(x: 26.14, y: 17.25), controlPoint1: NSPoint(x: 25.45, y: 17.44), controlPoint2: NSPoint(x: 25.8, y: 17.39))
        takoShapePath.curve(to: NSPoint(x: 26.42, y: 17.15), controlPoint1: NSPoint(x: 26.27, y: 17.19), controlPoint2: NSPoint(x: 26.4, y: 17.15))
        takoShapePath.curve(to: NSPoint(x: 27.04, y: 16.57), controlPoint1: NSPoint(x: 26.58, y: 17.15), controlPoint2: NSPoint(x: 26.87, y: 16.87))
        takoShapePath.curve(to: NSPoint(x: 27.43, y: 14.83), controlPoint1: NSPoint(x: 27.38, y: 15.96), controlPoint2: NSPoint(x: 27.43, y: 15.74))
        takoShapePath.curve(to: NSPoint(x: 27.25, y: 13.53), controlPoint1: NSPoint(x: 27.43, y: 14.04), controlPoint2: NSPoint(x: 27.42, y: 14))
        takoShapePath.curve(to: NSPoint(x: 26.88, y: 12.66), controlPoint1: NSPoint(x: 27.15, y: 13.26), controlPoint2: NSPoint(x: 26.98, y: 12.86))
        takoShapePath.curve(to: NSPoint(x: 26.84, y: 11.94), controlPoint1: NSPoint(x: 26.69, y: 12.28), controlPoint2: NSPoint(x: 26.69, y: 12.28))
        takoShapePath.curve(to: NSPoint(x: 27.16, y: 11.36), controlPoint1: NSPoint(x: 26.91, y: 11.76), controlPoint2: NSPoint(x: 27.06, y: 11.49))
        takoShapePath.curve(to: NSPoint(x: 27.39, y: 10.99), controlPoint1: NSPoint(x: 27.26, y: 11.21), controlPoint2: NSPoint(x: 27.37, y: 11.05))
        takoShapePath.curve(to: NSPoint(x: 27.62, y: 10.62), controlPoint1: NSPoint(x: 27.42, y: 10.92), controlPoint2: NSPoint(x: 27.52, y: 10.75))
        takoShapePath.curve(to: NSPoint(x: 28.17, y: 9.22), controlPoint1: NSPoint(x: 27.8, y: 10.38), controlPoint2: NSPoint(x: 27.91, y: 10.1))
        takoShapePath.curve(to: NSPoint(x: 28.52, y: 8.06), controlPoint1: NSPoint(x: 28.24, y: 8.96), controlPoint2: NSPoint(x: 28.4, y: 8.44))
        takoShapePath.curve(to: NSPoint(x: 28.81, y: 7.08), controlPoint1: NSPoint(x: 28.63, y: 7.68), controlPoint2: NSPoint(x: 28.76, y: 7.24))
        takoShapePath.curve(to: NSPoint(x: 29.02, y: 6.36), controlPoint1: NSPoint(x: 28.85, y: 6.91), controlPoint2: NSPoint(x: 28.95, y: 6.59))
        takoShapePath.curve(to: NSPoint(x: 29.28, y: 5.58), controlPoint1: NSPoint(x: 29.1, y: 6.13), controlPoint2: NSPoint(x: 29.22, y: 5.78))
        takoShapePath.curve(to: NSPoint(x: 30.18, y: 4.15), controlPoint1: NSPoint(x: 29.46, y: 4.95), controlPoint2: NSPoint(x: 29.66, y: 4.63))
        takoShapePath.curve(to: NSPoint(x: 30.89, y: 3.04), controlPoint1: NSPoint(x: 30.7, y: 3.65), controlPoint2: NSPoint(x: 30.8, y: 3.49))
        takoShapePath.curve(to: NSPoint(x: 30.73, y: 2.42), controlPoint1: NSPoint(x: 30.95, y: 2.73), controlPoint2: NSPoint(x: 30.95, y: 2.73))
        takoShapePath.curve(to: NSPoint(x: 30.25, y: 1.93), controlPoint1: NSPoint(x: 30.6, y: 2.23), controlPoint2: NSPoint(x: 30.41, y: 2.03))
        takoShapePath.curve(to: NSPoint(x: 29.32, y: 1.76), controlPoint1: NSPoint(x: 30, y: 1.76), controlPoint2: NSPoint(x: 30, y: 1.76))
        takoShapePath.curve(to: NSPoint(x: 28.24, y: 1.83), controlPoint1: NSPoint(x: 28.95, y: 1.76), controlPoint2: NSPoint(x: 28.47, y: 1.79))
        takoShapePath.curve(to: NSPoint(x: 27.62, y: 1.8), controlPoint1: NSPoint(x: 27.84, y: 1.89), controlPoint2: NSPoint(x: 27.82, y: 1.89))
        takoShapePath.curve(to: NSPoint(x: 25.22, y: 1.29), controlPoint1: NSPoint(x: 27.36, y: 1.65), controlPoint2: NSPoint(x: 25.61, y: 1.29))
        takoShapePath.curve(to: NSPoint(x: 23.62, y: 1.56), controlPoint1: NSPoint(x: 24.5, y: 1.29), controlPoint2: NSPoint(x: 24.02, y: 1.37))
        takoShapePath.curve(to: NSPoint(x: 23.1, y: 1.89), controlPoint1: NSPoint(x: 23.41, y: 1.66), controlPoint2: NSPoint(x: 23.17, y: 1.81))
        takoShapePath.curve(to: NSPoint(x: 22.49, y: 1.88), controlPoint1: NSPoint(x: 22.96, y: 2.04), controlPoint2: NSPoint(x: 22.96, y: 2.04))
        takoShapePath.curve(to: NSPoint(x: 20.45, y: 1.66), controlPoint1: NSPoint(x: 22.02, y: 1.73), controlPoint2: NSPoint(x: 22.04, y: 1.73))
        takoShapePath.curve(to: NSPoint(x: 19.39, y: 1.72), controlPoint1: NSPoint(x: 20.11, y: 1.64), controlPoint2: NSPoint(x: 19.77, y: 1.66))
        takoShapePath.curve(to: NSPoint(x: 18.79, y: 1.74), controlPoint1: NSPoint(x: 18.93, y: 1.8), controlPoint2: NSPoint(x: 18.83, y: 1.8))
        takoShapePath.curve(to: NSPoint(x: 17.43, y: 1.21), controlPoint1: NSPoint(x: 18.64, y: 1.58), controlPoint2: NSPoint(x: 18.2, y: 1.41))
        takoShapePath.curve(to: NSPoint(x: 15.72, y: 1.05), controlPoint1: NSPoint(x: 16.57, y: 0.98), controlPoint2: NSPoint(x: 16.27, y: 0.96))
        takoShapePath.close()
        takoShapePath.move(to: NSPoint(x: 12.01, y: 2.37))
        takoShapePath.curve(to: NSPoint(x: 12.93, y: 2.47), controlPoint1: NSPoint(x: 12.2, y: 2.4), controlPoint2: NSPoint(x: 12.61, y: 2.45))
        takoShapePath.curve(to: NSPoint(x: 14.27, y: 2.9), controlPoint1: NSPoint(x: 13.56, y: 2.52), controlPoint2: NSPoint(x: 13.79, y: 2.59))
        takoShapePath.curve(to: NSPoint(x: 16.58, y: 3.31), controlPoint1: NSPoint(x: 14.98, y: 3.36), controlPoint2: NSPoint(x: 15.65, y: 3.48))
        takoShapePath.curve(to: NSPoint(x: 17.33, y: 3.14), controlPoint1: NSPoint(x: 16.9, y: 3.25), controlPoint2: NSPoint(x: 17.24, y: 3.18))
        takoShapePath.curve(to: NSPoint(x: 19.65, y: 2.54), controlPoint1: NSPoint(x: 17.79, y: 2.96), controlPoint2: NSPoint(x: 19.2, y: 2.6))
        takoShapePath.curve(to: NSPoint(x: 21.68, y: 2.59), controlPoint1: NSPoint(x: 20.48, y: 2.44), controlPoint2: NSPoint(x: 21.15, y: 2.45))
        takoShapePath.curve(to: NSPoint(x: 23.26, y: 3.14), controlPoint1: NSPoint(x: 22.36, y: 2.77), controlPoint2: NSPoint(x: 22.72, y: 2.89))
        takoShapePath.curve(to: NSPoint(x: 25.21, y: 3.51), controlPoint1: NSPoint(x: 23.96, y: 3.46), controlPoint2: NSPoint(x: 24.24, y: 3.51))
        takoShapePath.curve(to: NSPoint(x: 26.57, y: 3.38), controlPoint1: NSPoint(x: 25.92, y: 3.51), controlPoint2: NSPoint(x: 26.13, y: 3.49))
        takoShapePath.curve(to: NSPoint(x: 27.38, y: 3.14), controlPoint1: NSPoint(x: 26.85, y: 3.32), controlPoint2: NSPoint(x: 27.22, y: 3.21))
        takoShapePath.curve(to: NSPoint(x: 28.39, y: 2.92), controlPoint1: NSPoint(x: 27.64, y: 3.03), controlPoint2: NSPoint(x: 28.09, y: 2.93))
        takoShapePath.curve(to: NSPoint(x: 29.03, y: 2.83), controlPoint1: NSPoint(x: 28.45, y: 2.92), controlPoint2: NSPoint(x: 28.74, y: 2.87))
        takoShapePath.curve(to: NSPoint(x: 29.79, y: 2.91), controlPoint1: NSPoint(x: 29.61, y: 2.73), controlPoint2: NSPoint(x: 29.77, y: 2.74))
        takoShapePath.curve(to: NSPoint(x: 29.54, y: 3.36), controlPoint1: NSPoint(x: 29.83, y: 3.12), controlPoint2: NSPoint(x: 29.75, y: 3.25))
        takoShapePath.curve(to: NSPoint(x: 28.82, y: 4.1), controlPoint1: NSPoint(x: 29.3, y: 3.47), controlPoint2: NSPoint(x: 28.99, y: 3.79))
        takoShapePath.curve(to: NSPoint(x: 28.47, y: 4.98), controlPoint1: NSPoint(x: 28.75, y: 4.22), controlPoint2: NSPoint(x: 28.59, y: 4.62))
        takoShapePath.curve(to: NSPoint(x: 28.01, y: 6.32), controlPoint1: NSPoint(x: 28.34, y: 5.35), controlPoint2: NSPoint(x: 28.14, y: 5.95))
        takoShapePath.curve(to: NSPoint(x: 27.53, y: 7.82), controlPoint1: NSPoint(x: 27.88, y: 6.69), controlPoint2: NSPoint(x: 27.66, y: 7.37))
        takoShapePath.curve(to: NSPoint(x: 26.19, y: 11.13), controlPoint1: NSPoint(x: 27.06, y: 9.43), controlPoint2: NSPoint(x: 26.97, y: 9.66))
        takoShapePath.curve(to: NSPoint(x: 25.76, y: 12.89), controlPoint1: NSPoint(x: 25.5, y: 12.44), controlPoint2: NSPoint(x: 25.48, y: 12.51))
        takoShapePath.curve(to: NSPoint(x: 26.41, y: 15.3), controlPoint1: NSPoint(x: 26.44, y: 13.83), controlPoint2: NSPoint(x: 26.6, y: 14.42))
        takoShapePath.curve(to: NSPoint(x: 25.64, y: 16.46), controlPoint1: NSPoint(x: 26.25, y: 16.05), controlPoint2: NSPoint(x: 26.07, y: 16.31))
        takoShapePath.curve(to: NSPoint(x: 24.97, y: 16.49), controlPoint1: NSPoint(x: 25.32, y: 16.57), controlPoint2: NSPoint(x: 25.11, y: 16.58))
        takoShapePath.curve(to: NSPoint(x: 24.95, y: 16.23), controlPoint1: NSPoint(x: 24.88, y: 16.43), controlPoint2: NSPoint(x: 24.88, y: 16.41))
        takoShapePath.curve(to: NSPoint(x: 25.02, y: 15.32), controlPoint1: NSPoint(x: 24.99, y: 16.1), controlPoint2: NSPoint(x: 25.02, y: 15.8))
        takoShapePath.curve(to: NSPoint(x: 24.88, y: 13.99), controlPoint1: NSPoint(x: 25.02, y: 14.74), controlPoint2: NSPoint(x: 24.99, y: 14.5))
        takoShapePath.curve(to: NSPoint(x: 24.49, y: 13.09), controlPoint1: NSPoint(x: 24.7, y: 13.23), controlPoint2: NSPoint(x: 24.7, y: 13.24))
        takoShapePath.curve(to: NSPoint(x: 23.56, y: 12.99), controlPoint1: NSPoint(x: 24.27, y: 12.94), controlPoint2: NSPoint(x: 23.89, y: 12.9))
        takoShapePath.curve(to: NSPoint(x: 21.82, y: 13.4), controlPoint1: NSPoint(x: 22.83, y: 13.18), controlPoint2: NSPoint(x: 22.49, y: 13.27))
        takoShapePath.curve(to: NSPoint(x: 20.61, y: 13.65), controlPoint1: NSPoint(x: 21.4, y: 13.49), controlPoint2: NSPoint(x: 20.86, y: 13.6))
        takoShapePath.curve(to: NSPoint(x: 15.35, y: 14.14), controlPoint1: NSPoint(x: 19.07, y: 13.98), controlPoint2: NSPoint(x: 17.36, y: 14.14))
        takoShapePath.curve(to: NSPoint(x: 9.37, y: 13.2), controlPoint1: NSPoint(x: 13.33, y: 14.14), controlPoint2: NSPoint(x: 10.73, y: 13.73))
        takoShapePath.curve(to: NSPoint(x: 8.35, y: 13.08), controlPoint1: NSPoint(x: 8.9, y: 13.01), controlPoint2: NSPoint(x: 8.53, y: 12.97))
        takoShapePath.curve(to: NSPoint(x: 7.73, y: 14.01), controlPoint1: NSPoint(x: 8.2, y: 13.17), controlPoint2: NSPoint(x: 7.88, y: 13.65))
        takoShapePath.curve(to: NSPoint(x: 7.26, y: 16.28), controlPoint1: NSPoint(x: 7.57, y: 14.37), controlPoint2: NSPoint(x: 7.25, y: 15.95))
        takoShapePath.curve(to: NSPoint(x: 7.22, y: 16.61), controlPoint1: NSPoint(x: 7.26, y: 16.43), controlPoint2: NSPoint(x: 7.25, y: 16.58))
        takoShapePath.curve(to: NSPoint(x: 6.43, y: 16.44), controlPoint1: NSPoint(x: 7.15, y: 16.67), controlPoint2: NSPoint(x: 6.69, y: 16.58))
        takoShapePath.curve(to: NSPoint(x: 5.98, y: 15.67), controlPoint1: NSPoint(x: 6.09, y: 16.27), controlPoint2: NSPoint(x: 6, y: 16.11))
        takoShapePath.curve(to: NSPoint(x: 6.38, y: 13.53), controlPoint1: NSPoint(x: 5.95, y: 15.23), controlPoint2: NSPoint(x: 6.09, y: 14.51))
        takoShapePath.curve(to: NSPoint(x: 6.38, y: 11.97), controlPoint1: NSPoint(x: 6.61, y: 12.77), controlPoint2: NSPoint(x: 6.6, y: 12.42))
        takoShapePath.curve(to: NSPoint(x: 6.21, y: 11.53), controlPoint1: NSPoint(x: 6.3, y: 11.82), controlPoint2: NSPoint(x: 6.23, y: 11.63))
        takoShapePath.curve(to: NSPoint(x: 6.01, y: 11.11), controlPoint1: NSPoint(x: 6.19, y: 11.43), controlPoint2: NSPoint(x: 6.1, y: 11.24))
        takoShapePath.curve(to: NSPoint(x: 5.17, y: 9.49), controlPoint1: NSPoint(x: 5.77, y: 10.75), controlPoint2: NSPoint(x: 5.42, y: 10.1))
        takoShapePath.curve(to: NSPoint(x: 3.91, y: 5.94), controlPoint1: NSPoint(x: 4.76, y: 8.51), controlPoint2: NSPoint(x: 4.06, y: 6.54))
        takoShapePath.curve(to: NSPoint(x: 2.37, y: 3.36), controlPoint1: NSPoint(x: 3.53, y: 4.41), controlPoint2: NSPoint(x: 3.26, y: 3.95))
        takoShapePath.curve(to: NSPoint(x: 2.08, y: 3.1), controlPoint1: NSPoint(x: 2.2, y: 3.24), controlPoint2: NSPoint(x: 2.07, y: 3.13))
        takoShapePath.curve(to: NSPoint(x: 3.73, y: 2.82), controlPoint1: NSPoint(x: 2.11, y: 3.02), controlPoint2: NSPoint(x: 2.96, y: 2.87))
        takoShapePath.curve(to: NSPoint(x: 4.42, y: 2.84), controlPoint1: NSPoint(x: 4.22, y: 2.78), controlPoint2: NSPoint(x: 4.36, y: 2.79))
        takoShapePath.curve(to: NSPoint(x: 5.41, y: 3.26), controlPoint1: NSPoint(x: 4.55, y: 2.94), controlPoint2: NSPoint(x: 5, y: 3.14))
        takoShapePath.curve(to: NSPoint(x: 6.91, y: 3.38), controlPoint1: NSPoint(x: 5.76, y: 3.37), controlPoint2: NSPoint(x: 5.87, y: 3.38))
        takoShapePath.curve(to: NSPoint(x: 8.56, y: 3.19), controlPoint1: NSPoint(x: 8.03, y: 3.38), controlPoint2: NSPoint(x: 8.03, y: 3.38))
        takoShapePath.curve(to: NSPoint(x: 9.74, y: 2.59), controlPoint1: NSPoint(x: 9.2, y: 2.97), controlPoint2: NSPoint(x: 9.63, y: 2.75))
        takoShapePath.curve(to: NSPoint(x: 10.62, y: 2.37), controlPoint1: NSPoint(x: 9.85, y: 2.44), controlPoint2: NSPoint(x: 9.96, y: 2.42))
        takoShapePath.curve(to: NSPoint(x: 12.01, y: 2.37), controlPoint1: NSPoint(x: 11.48, y: 2.32), controlPoint2: NSPoint(x: 11.63, y: 2.32))
        takoShapePath.close()
        return takoShapePath
    }()
    
    let takoSkinPath: NSBezierPath = {
        let takoSkinPath = NSBezierPath()
        takoSkinPath.move(to: NSPoint(x: 12.01, y: 2.37))
        takoSkinPath.curve(to: NSPoint(x: 12.93, y: 2.47), controlPoint1: NSPoint(x: 12.2, y: 2.4), controlPoint2: NSPoint(x: 12.61, y: 2.45))
        takoSkinPath.curve(to: NSPoint(x: 14.27, y: 2.9), controlPoint1: NSPoint(x: 13.56, y: 2.52), controlPoint2: NSPoint(x: 13.79, y: 2.59))
        takoSkinPath.curve(to: NSPoint(x: 16.58, y: 3.31), controlPoint1: NSPoint(x: 14.98, y: 3.36), controlPoint2: NSPoint(x: 15.65, y: 3.48))
        takoSkinPath.curve(to: NSPoint(x: 17.33, y: 3.14), controlPoint1: NSPoint(x: 16.9, y: 3.25), controlPoint2: NSPoint(x: 17.24, y: 3.18))
        takoSkinPath.curve(to: NSPoint(x: 19.65, y: 2.54), controlPoint1: NSPoint(x: 17.79, y: 2.96), controlPoint2: NSPoint(x: 19.2, y: 2.6))
        takoSkinPath.curve(to: NSPoint(x: 21.68, y: 2.59), controlPoint1: NSPoint(x: 20.48, y: 2.44), controlPoint2: NSPoint(x: 21.15, y: 2.45))
        takoSkinPath.curve(to: NSPoint(x: 23.26, y: 3.14), controlPoint1: NSPoint(x: 22.36, y: 2.77), controlPoint2: NSPoint(x: 22.72, y: 2.89))
        takoSkinPath.curve(to: NSPoint(x: 25.21, y: 3.51), controlPoint1: NSPoint(x: 23.96, y: 3.46), controlPoint2: NSPoint(x: 24.24, y: 3.51))
        takoSkinPath.curve(to: NSPoint(x: 26.57, y: 3.38), controlPoint1: NSPoint(x: 25.92, y: 3.51), controlPoint2: NSPoint(x: 26.13, y: 3.49))
        takoSkinPath.curve(to: NSPoint(x: 27.38, y: 3.14), controlPoint1: NSPoint(x: 26.85, y: 3.32), controlPoint2: NSPoint(x: 27.22, y: 3.21))
        takoSkinPath.curve(to: NSPoint(x: 28.39, y: 2.92), controlPoint1: NSPoint(x: 27.64, y: 3.03), controlPoint2: NSPoint(x: 28.09, y: 2.93))
        takoSkinPath.curve(to: NSPoint(x: 29.03, y: 2.83), controlPoint1: NSPoint(x: 28.45, y: 2.92), controlPoint2: NSPoint(x: 28.74, y: 2.87))
        takoSkinPath.curve(to: NSPoint(x: 29.79, y: 2.91), controlPoint1: NSPoint(x: 29.61, y: 2.73), controlPoint2: NSPoint(x: 29.77, y: 2.74))
        takoSkinPath.curve(to: NSPoint(x: 29.54, y: 3.36), controlPoint1: NSPoint(x: 29.83, y: 3.12), controlPoint2: NSPoint(x: 29.75, y: 3.25))
        takoSkinPath.curve(to: NSPoint(x: 28.82, y: 4.1), controlPoint1: NSPoint(x: 29.3, y: 3.47), controlPoint2: NSPoint(x: 28.99, y: 3.79))
        takoSkinPath.curve(to: NSPoint(x: 28.47, y: 4.98), controlPoint1: NSPoint(x: 28.75, y: 4.22), controlPoint2: NSPoint(x: 28.59, y: 4.62))
        takoSkinPath.curve(to: NSPoint(x: 28.01, y: 6.32), controlPoint1: NSPoint(x: 28.34, y: 5.35), controlPoint2: NSPoint(x: 28.14, y: 5.95))
        takoSkinPath.curve(to: NSPoint(x: 27.53, y: 7.82), controlPoint1: NSPoint(x: 27.88, y: 6.69), controlPoint2: NSPoint(x: 27.66, y: 7.37))
        takoSkinPath.curve(to: NSPoint(x: 26.19, y: 11.13), controlPoint1: NSPoint(x: 27.06, y: 9.43), controlPoint2: NSPoint(x: 26.97, y: 9.66))
        takoSkinPath.curve(to: NSPoint(x: 25.76, y: 12.89), controlPoint1: NSPoint(x: 25.5, y: 12.44), controlPoint2: NSPoint(x: 25.48, y: 12.51))
        takoSkinPath.curve(to: NSPoint(x: 26.41, y: 15.3), controlPoint1: NSPoint(x: 26.44, y: 13.83), controlPoint2: NSPoint(x: 26.6, y: 14.42))
        takoSkinPath.curve(to: NSPoint(x: 25.64, y: 16.46), controlPoint1: NSPoint(x: 26.25, y: 16.05), controlPoint2: NSPoint(x: 26.07, y: 16.31))
        takoSkinPath.curve(to: NSPoint(x: 24.97, y: 16.49), controlPoint1: NSPoint(x: 25.32, y: 16.57), controlPoint2: NSPoint(x: 25.11, y: 16.58))
        takoSkinPath.curve(to: NSPoint(x: 24.95, y: 16.23), controlPoint1: NSPoint(x: 24.88, y: 16.43), controlPoint2: NSPoint(x: 24.88, y: 16.41))
        takoSkinPath.curve(to: NSPoint(x: 25.02, y: 15.32), controlPoint1: NSPoint(x: 24.99, y: 16.1), controlPoint2: NSPoint(x: 25.02, y: 15.8))
        takoSkinPath.curve(to: NSPoint(x: 24.88, y: 13.99), controlPoint1: NSPoint(x: 25.02, y: 14.74), controlPoint2: NSPoint(x: 24.99, y: 14.5))
        takoSkinPath.curve(to: NSPoint(x: 24.49, y: 13.09), controlPoint1: NSPoint(x: 24.7, y: 13.23), controlPoint2: NSPoint(x: 24.7, y: 13.24))
        takoSkinPath.curve(to: NSPoint(x: 23.56, y: 12.99), controlPoint1: NSPoint(x: 24.27, y: 12.94), controlPoint2: NSPoint(x: 23.89, y: 12.9))
        takoSkinPath.curve(to: NSPoint(x: 21.82, y: 13.4), controlPoint1: NSPoint(x: 22.83, y: 13.18), controlPoint2: NSPoint(x: 22.49, y: 13.27))
        takoSkinPath.curve(to: NSPoint(x: 20.61, y: 13.65), controlPoint1: NSPoint(x: 21.4, y: 13.49), controlPoint2: NSPoint(x: 20.86, y: 13.6))
        takoSkinPath.curve(to: NSPoint(x: 15.35, y: 14.14), controlPoint1: NSPoint(x: 19.07, y: 13.98), controlPoint2: NSPoint(x: 17.36, y: 14.14))
        takoSkinPath.curve(to: NSPoint(x: 9.37, y: 13.2), controlPoint1: NSPoint(x: 13.33, y: 14.14), controlPoint2: NSPoint(x: 10.73, y: 13.73))
        takoSkinPath.curve(to: NSPoint(x: 8.35, y: 13.08), controlPoint1: NSPoint(x: 8.9, y: 13.01), controlPoint2: NSPoint(x: 8.53, y: 12.97))
        takoSkinPath.curve(to: NSPoint(x: 7.73, y: 14.01), controlPoint1: NSPoint(x: 8.2, y: 13.17), controlPoint2: NSPoint(x: 7.88, y: 13.65))
        takoSkinPath.curve(to: NSPoint(x: 7.26, y: 16.28), controlPoint1: NSPoint(x: 7.57, y: 14.37), controlPoint2: NSPoint(x: 7.25, y: 15.95))
        takoSkinPath.curve(to: NSPoint(x: 7.22, y: 16.61), controlPoint1: NSPoint(x: 7.26, y: 16.43), controlPoint2: NSPoint(x: 7.25, y: 16.58))
        takoSkinPath.curve(to: NSPoint(x: 6.43, y: 16.44), controlPoint1: NSPoint(x: 7.15, y: 16.67), controlPoint2: NSPoint(x: 6.69, y: 16.58))
        takoSkinPath.curve(to: NSPoint(x: 5.98, y: 15.67), controlPoint1: NSPoint(x: 6.09, y: 16.27), controlPoint2: NSPoint(x: 6, y: 16.11))
        takoSkinPath.curve(to: NSPoint(x: 6.38, y: 13.53), controlPoint1: NSPoint(x: 5.95, y: 15.23), controlPoint2: NSPoint(x: 6.09, y: 14.51))
        takoSkinPath.curve(to: NSPoint(x: 6.38, y: 11.97), controlPoint1: NSPoint(x: 6.61, y: 12.77), controlPoint2: NSPoint(x: 6.6, y: 12.42))
        takoSkinPath.curve(to: NSPoint(x: 6.21, y: 11.53), controlPoint1: NSPoint(x: 6.3, y: 11.82), controlPoint2: NSPoint(x: 6.23, y: 11.63))
        takoSkinPath.curve(to: NSPoint(x: 6.01, y: 11.11), controlPoint1: NSPoint(x: 6.19, y: 11.43), controlPoint2: NSPoint(x: 6.1, y: 11.24))
        takoSkinPath.curve(to: NSPoint(x: 5.17, y: 9.49), controlPoint1: NSPoint(x: 5.77, y: 10.75), controlPoint2: NSPoint(x: 5.42, y: 10.1))
        takoSkinPath.curve(to: NSPoint(x: 3.91, y: 5.94), controlPoint1: NSPoint(x: 4.76, y: 8.51), controlPoint2: NSPoint(x: 4.06, y: 6.54))
        takoSkinPath.curve(to: NSPoint(x: 2.37, y: 3.36), controlPoint1: NSPoint(x: 3.53, y: 4.41), controlPoint2: NSPoint(x: 3.26, y: 3.95))
        takoSkinPath.curve(to: NSPoint(x: 2.08, y: 3.1), controlPoint1: NSPoint(x: 2.2, y: 3.24), controlPoint2: NSPoint(x: 2.07, y: 3.13))
        takoSkinPath.curve(to: NSPoint(x: 3.73, y: 2.82), controlPoint1: NSPoint(x: 2.11, y: 3.02), controlPoint2: NSPoint(x: 2.96, y: 2.87))
        takoSkinPath.curve(to: NSPoint(x: 4.42, y: 2.84), controlPoint1: NSPoint(x: 4.22, y: 2.78), controlPoint2: NSPoint(x: 4.36, y: 2.79))
        takoSkinPath.curve(to: NSPoint(x: 5.41, y: 3.26), controlPoint1: NSPoint(x: 4.55, y: 2.94), controlPoint2: NSPoint(x: 5, y: 3.14))
        takoSkinPath.curve(to: NSPoint(x: 6.91, y: 3.38), controlPoint1: NSPoint(x: 5.76, y: 3.37), controlPoint2: NSPoint(x: 5.87, y: 3.38))
        takoSkinPath.curve(to: NSPoint(x: 8.56, y: 3.19), controlPoint1: NSPoint(x: 8.03, y: 3.38), controlPoint2: NSPoint(x: 8.03, y: 3.38))
        takoSkinPath.curve(to: NSPoint(x: 9.74, y: 2.59), controlPoint1: NSPoint(x: 9.2, y: 2.97), controlPoint2: NSPoint(x: 9.63, y: 2.75))
        takoSkinPath.curve(to: NSPoint(x: 10.62, y: 2.37), controlPoint1: NSPoint(x: 9.85, y: 2.44), controlPoint2: NSPoint(x: 9.96, y: 2.42))
        takoSkinPath.curve(to: NSPoint(x: 12.01, y: 2.37), controlPoint1: NSPoint(x: 11.48, y: 2.32), controlPoint2: NSPoint(x: 11.63, y: 2.32))
        takoSkinPath.close()
        return takoSkinPath;
    }()
    
    let takoHappyLeftEyePath: NSBezierPath = {
        let takoHappyLeftEyePath = NSBezierPath()
        takoHappyLeftEyePath.move(to: NSPoint(x: 8.55, y: 7.91))
        takoHappyLeftEyePath.curve(to: NSPoint(x: 8.72, y: 8.42), controlPoint1: NSPoint(x: 8.32, y: 8), controlPoint2: NSPoint(x: 8.4, y: 8.25))
        takoHappyLeftEyePath.curve(to: NSPoint(x: 9.55, y: 8.68), controlPoint1: NSPoint(x: 8.82, y: 8.47), controlPoint2: NSPoint(x: 9.19, y: 8.59))
        takoHappyLeftEyePath.curve(to: NSPoint(x: 10.81, y: 9.03), controlPoint1: NSPoint(x: 10.17, y: 8.84), controlPoint2: NSPoint(x: 10.51, y: 8.94))
        takoHappyLeftEyePath.curve(to: NSPoint(x: 10.47, y: 9.32), controlPoint1: NSPoint(x: 10.95, y: 9.07), controlPoint2: NSPoint(x: 10.95, y: 9.07))
        takoHappyLeftEyePath.curve(to: NSPoint(x: 9.92, y: 9.57), controlPoint1: NSPoint(x: 10.22, y: 9.46), controlPoint2: NSPoint(x: 9.97, y: 9.57))
        takoHappyLeftEyePath.curve(to: NSPoint(x: 9.78, y: 9.63), controlPoint1: NSPoint(x: 9.88, y: 9.57), controlPoint2: NSPoint(x: 9.82, y: 9.6))
        takoHappyLeftEyePath.curve(to: NSPoint(x: 9.55, y: 9.76), controlPoint1: NSPoint(x: 9.75, y: 9.66), controlPoint2: NSPoint(x: 9.64, y: 9.72))
        takoHappyLeftEyePath.curve(to: NSPoint(x: 9.04, y: 10.19), controlPoint1: NSPoint(x: 9.31, y: 9.86), controlPoint2: NSPoint(x: 9.08, y: 10.05))
        takoHappyLeftEyePath.curve(to: NSPoint(x: 9.22, y: 10.67), controlPoint1: NSPoint(x: 9, y: 10.34), controlPoint2: NSPoint(x: 9.1, y: 10.59))
        takoHappyLeftEyePath.curve(to: NSPoint(x: 11.5, y: 9.72), controlPoint1: NSPoint(x: 9.5, y: 10.82), controlPoint2: NSPoint(x: 9.73, y: 10.73))
        takoHappyLeftEyePath.curve(to: NSPoint(x: 12.17, y: 8.96), controlPoint1: NSPoint(x: 12.19, y: 9.33), controlPoint2: NSPoint(x: 12.27, y: 9.24))
        takoHappyLeftEyePath.curve(to: NSPoint(x: 11.92, y: 8.69), controlPoint1: NSPoint(x: 12.13, y: 8.84), controlPoint2: NSPoint(x: 12.07, y: 8.77))
        takoHappyLeftEyePath.curve(to: NSPoint(x: 9.74, y: 7.99), controlPoint1: NSPoint(x: 11.59, y: 8.51), controlPoint2: NSPoint(x: 10.77, y: 8.25))
        takoHappyLeftEyePath.curve(to: NSPoint(x: 8.55, y: 7.91), controlPoint1: NSPoint(x: 9.38, y: 7.9), controlPoint2: NSPoint(x: 8.71, y: 7.86))
        takoHappyLeftEyePath.close()
        return takoHappyLeftEyePath
    }()
    
    let takoHappyRightEyePath: NSBezierPath = {
        let takoHappyRightEyePath = NSBezierPath()
        takoHappyRightEyePath.move(to: NSPoint(x: 21.82, y: 8.03))
        takoHappyRightEyePath.curve(to: NSPoint(x: 20.15, y: 8.55), controlPoint1: NSPoint(x: 20.95, y: 8.21), controlPoint2: NSPoint(x: 20.69, y: 8.29))
        takoHappyRightEyePath.curve(to: NSPoint(x: 19.64, y: 9.02), controlPoint1: NSPoint(x: 19.79, y: 8.72), controlPoint2: NSPoint(x: 19.64, y: 8.86))
        takoHappyRightEyePath.curve(to: NSPoint(x: 20.5, y: 9.8), controlPoint1: NSPoint(x: 19.64, y: 9.33), controlPoint2: NSPoint(x: 19.89, y: 9.55))
        takoHappyRightEyePath.curve(to: NSPoint(x: 22.18, y: 10.22), controlPoint1: NSPoint(x: 20.82, y: 9.93), controlPoint2: NSPoint(x: 21.17, y: 10.02))
        takoHappyRightEyePath.curve(to: NSPoint(x: 23.31, y: 10.17), controlPoint1: NSPoint(x: 22.42, y: 10.27), controlPoint2: NSPoint(x: 23.18, y: 10.24))
        takoHappyRightEyePath.curve(to: NSPoint(x: 23.45, y: 10), controlPoint1: NSPoint(x: 23.37, y: 10.14), controlPoint2: NSPoint(x: 23.43, y: 10.06))
        takoHappyRightEyePath.curve(to: NSPoint(x: 22.42, y: 9.4), controlPoint1: NSPoint(x: 23.53, y: 9.7), controlPoint2: NSPoint(x: 23.13, y: 9.47))
        takoHappyRightEyePath.curve(to: NSPoint(x: 20.96, y: 9.14), controlPoint1: NSPoint(x: 22.1, y: 9.37), controlPoint2: NSPoint(x: 21.23, y: 9.21))
        takoHappyRightEyePath.curve(to: NSPoint(x: 20.89, y: 9.04), controlPoint1: NSPoint(x: 20.77, y: 9.08), controlPoint2: NSPoint(x: 20.77, y: 9.08))
        takoHappyRightEyePath.curve(to: NSPoint(x: 21.22, y: 8.94), controlPoint1: NSPoint(x: 20.95, y: 9.02), controlPoint2: NSPoint(x: 21.1, y: 8.97))
        takoHappyRightEyePath.curve(to: NSPoint(x: 21.73, y: 8.8), controlPoint1: NSPoint(x: 21.34, y: 8.91), controlPoint2: NSPoint(x: 21.57, y: 8.85))
        takoHappyRightEyePath.curve(to: NSPoint(x: 22.39, y: 8.64), controlPoint1: NSPoint(x: 21.88, y: 8.76), controlPoint2: NSPoint(x: 22.18, y: 8.69))
        takoHappyRightEyePath.curve(to: NSPoint(x: 23.3, y: 8.3), controlPoint1: NSPoint(x: 22.81, y: 8.55), controlPoint2: NSPoint(x: 23.17, y: 8.43))
        takoHappyRightEyePath.curve(to: NSPoint(x: 23.22, y: 7.9), controlPoint1: NSPoint(x: 23.41, y: 8.2), controlPoint2: NSPoint(x: 23.37, y: 7.98))
        takoHappyRightEyePath.curve(to: NSPoint(x: 21.82, y: 8.03), controlPoint1: NSPoint(x: 23.06, y: 7.8), controlPoint2: NSPoint(x: 22.75, y: 7.83))
        takoHappyRightEyePath.close()
        return takoHappyRightEyePath
    }()
    
    let takoHappyMouthPath: NSBezierPath = {
        let takoHappyMouthPath = NSBezierPath()
        takoHappyMouthPath.move(to: NSPoint(x: 14.91, y: 4.88))
        takoHappyMouthPath.curve(to: NSPoint(x: 14.46, y: 4.98), controlPoint1: NSPoint(x: 14.73, y: 4.9), controlPoint2: NSPoint(x: 14.53, y: 4.95))
        takoHappyMouthPath.curve(to: NSPoint(x: 14.25, y: 5.03), controlPoint1: NSPoint(x: 14.38, y: 5), controlPoint2: NSPoint(x: 14.29, y: 5.03))
        takoHappyMouthPath.curve(to: NSPoint(x: 13.62, y: 5.35), controlPoint1: NSPoint(x: 14.16, y: 5.03), controlPoint2: NSPoint(x: 13.81, y: 5.21))
        takoHappyMouthPath.curve(to: NSPoint(x: 12.88, y: 6.28), controlPoint1: NSPoint(x: 13.22, y: 5.65), controlPoint2: NSPoint(x: 13, y: 5.93))
        takoHappyMouthPath.curve(to: NSPoint(x: 12.64, y: 7.5), controlPoint1: NSPoint(x: 12.68, y: 6.83), controlPoint2: NSPoint(x: 12.64, y: 7.06))
        takoHappyMouthPath.curve(to: NSPoint(x: 13.65, y: 8.05), controlPoint1: NSPoint(x: 12.63, y: 8.09), controlPoint2: NSPoint(x: 12.59, y: 8.07))
        takoHappyMouthPath.curve(to: NSPoint(x: 15.6, y: 8.01), controlPoint1: NSPoint(x: 14.12, y: 8.04), controlPoint2: NSPoint(x: 15, y: 8.03))
        takoHappyMouthPath.curve(to: NSPoint(x: 17.82, y: 7.98), controlPoint1: NSPoint(x: 16.21, y: 8), controlPoint2: NSPoint(x: 17.2, y: 7.98))
        takoHappyMouthPath.curve(to: NSPoint(x: 19.07, y: 7.55), controlPoint1: NSPoint(x: 19.13, y: 7.97), controlPoint2: NSPoint(x: 19.07, y: 7.99))
        takoHappyMouthPath.curve(to: NSPoint(x: 17.35, y: 5.19), controlPoint1: NSPoint(x: 19.07, y: 6.54), controlPoint2: NSPoint(x: 18.36, y: 5.56))
        takoHappyMouthPath.curve(to: NSPoint(x: 15.77, y: 4.86), controlPoint1: NSPoint(x: 16.63, y: 4.93), controlPoint2: NSPoint(x: 16.37, y: 4.87))
        takoHappyMouthPath.curve(to: NSPoint(x: 14.91, y: 4.88), controlPoint1: NSPoint(x: 15.47, y: 4.85), controlPoint2: NSPoint(x: 15.08, y: 4.86))
        takoHappyMouthPath.close()
        takoHappyMouthPath.move(to: NSPoint(x: 16, y: 5.32))
        takoHappyMouthPath.curve(to: NSPoint(x: 17.54, y: 5.92), controlPoint1: NSPoint(x: 16.46, y: 5.38), controlPoint2: NSPoint(x: 17.23, y: 5.68))
        takoHappyMouthPath.curve(to: NSPoint(x: 18.3, y: 7.09), controlPoint1: NSPoint(x: 17.81, y: 6.13), controlPoint2: NSPoint(x: 18.3, y: 6.89))
        takoHappyMouthPath.curve(to: NSPoint(x: 18.2, y: 7.28), controlPoint1: NSPoint(x: 18.3, y: 7.23), controlPoint2: NSPoint(x: 18.28, y: 7.26))
        takoHappyMouthPath.curve(to: NSPoint(x: 17.81, y: 7.13), controlPoint1: NSPoint(x: 17.99, y: 7.32), controlPoint2: NSPoint(x: 17.93, y: 7.3))
        takoHappyMouthPath.curve(to: NSPoint(x: 16.68, y: 5.95), controlPoint1: NSPoint(x: 17.26, y: 6.36), controlPoint2: NSPoint(x: 16.99, y: 6.07))
        takoHappyMouthPath.curve(to: NSPoint(x: 16.24, y: 5.88), controlPoint1: NSPoint(x: 16.48, y: 5.86), controlPoint2: NSPoint(x: 16.41, y: 5.85))
        takoHappyMouthPath.curve(to: NSPoint(x: 15.96, y: 5.98), controlPoint1: NSPoint(x: 16.14, y: 5.89), controlPoint2: NSPoint(x: 16.01, y: 5.94))
        takoHappyMouthPath.curve(to: NSPoint(x: 15.36, y: 7.25), controlPoint1: NSPoint(x: 15.87, y: 6.05), controlPoint2: NSPoint(x: 15.43, y: 7))
        takoHappyMouthPath.curve(to: NSPoint(x: 15.03, y: 7.4), controlPoint1: NSPoint(x: 15.33, y: 7.37), controlPoint2: NSPoint(x: 15.32, y: 7.37))
        takoHappyMouthPath.curve(to: NSPoint(x: 14.07, y: 7.41), controlPoint1: NSPoint(x: 14.87, y: 7.41), controlPoint2: NSPoint(x: 14.44, y: 7.42))
        takoHappyMouthPath.curve(to: NSPoint(x: 13.38, y: 7.26), controlPoint1: NSPoint(x: 13.4, y: 7.4), controlPoint2: NSPoint(x: 13.4, y: 7.4))
        takoHappyMouthPath.curve(to: NSPoint(x: 13.73, y: 6.17), controlPoint1: NSPoint(x: 13.36, y: 7.1), controlPoint2: NSPoint(x: 13.57, y: 6.43))
        takoHappyMouthPath.curve(to: NSPoint(x: 14.02, y: 5.82), controlPoint1: NSPoint(x: 13.79, y: 6.06), controlPoint2: NSPoint(x: 13.92, y: 5.9))
        takoHappyMouthPath.curve(to: NSPoint(x: 15.14, y: 5.31), controlPoint1: NSPoint(x: 14.24, y: 5.65), controlPoint2: NSPoint(x: 14.84, y: 5.38))
        takoHappyMouthPath.curve(to: NSPoint(x: 16, y: 5.32), controlPoint1: NSPoint(x: 15.43, y: 5.25), controlPoint2: NSPoint(x: 15.53, y: 5.25))
        takoHappyMouthPath.close()
        takoHappyMouthPath.move(to: NSPoint(x: 16.89, y: 6.76))
        takoHappyMouthPath.curve(to: NSPoint(x: 17.23, y: 7.18), controlPoint1: NSPoint(x: 17.01, y: 6.92), controlPoint2: NSPoint(x: 17.16, y: 7.11))
        takoHappyMouthPath.curve(to: NSPoint(x: 16.64, y: 7.34), controlPoint1: NSPoint(x: 17.35, y: 7.32), controlPoint2: NSPoint(x: 17.35, y: 7.32))
        takoHappyMouthPath.curve(to: NSPoint(x: 15.92, y: 7.35), controlPoint1: NSPoint(x: 16.25, y: 7.35), controlPoint2: NSPoint(x: 15.92, y: 7.35))
        takoHappyMouthPath.curve(to: NSPoint(x: 16.35, y: 6.27), controlPoint1: NSPoint(x: 15.86, y: 7.33), controlPoint2: NSPoint(x: 16.24, y: 6.38))
        takoHappyMouthPath.curve(to: NSPoint(x: 16.54, y: 6.34), controlPoint1: NSPoint(x: 16.4, y: 6.22), controlPoint2: NSPoint(x: 16.43, y: 6.23))
        takoHappyMouthPath.curve(to: NSPoint(x: 16.89, y: 6.76), controlPoint1: NSPoint(x: 16.61, y: 6.41), controlPoint2: NSPoint(x: 16.77, y: 6.6))
        takoHappyMouthPath.close()
        return takoHappyMouthPath
    }()
    
    let takoHappyMouthInnerPath: NSBezierPath = {
        let takoHappyMouthInnerPath = NSBezierPath()
        takoHappyMouthInnerPath.move(to: NSPoint(x: 16, y: 5.32))
        takoHappyMouthInnerPath.curve(to: NSPoint(x: 17.54, y: 5.92), controlPoint1: NSPoint(x: 16.46, y: 5.38), controlPoint2: NSPoint(x: 17.23, y: 5.68))
        takoHappyMouthInnerPath.curve(to: NSPoint(x: 18.3, y: 7.09), controlPoint1: NSPoint(x: 17.81, y: 6.13), controlPoint2: NSPoint(x: 18.3, y: 6.89))
        takoHappyMouthInnerPath.curve(to: NSPoint(x: 18.2, y: 7.28), controlPoint1: NSPoint(x: 18.3, y: 7.23), controlPoint2: NSPoint(x: 18.28, y: 7.26))
        takoHappyMouthInnerPath.curve(to: NSPoint(x: 17.81, y: 7.13), controlPoint1: NSPoint(x: 17.99, y: 7.32), controlPoint2: NSPoint(x: 17.93, y: 7.3))
        takoHappyMouthInnerPath.curve(to: NSPoint(x: 16.68, y: 5.95), controlPoint1: NSPoint(x: 17.26, y: 6.36), controlPoint2: NSPoint(x: 16.99, y: 6.07))
        takoHappyMouthInnerPath.curve(to: NSPoint(x: 16.24, y: 5.88), controlPoint1: NSPoint(x: 16.48, y: 5.86), controlPoint2: NSPoint(x: 16.41, y: 5.85))
        takoHappyMouthInnerPath.curve(to: NSPoint(x: 15.96, y: 5.98), controlPoint1: NSPoint(x: 16.14, y: 5.89), controlPoint2: NSPoint(x: 16.01, y: 5.94))
        takoHappyMouthInnerPath.curve(to: NSPoint(x: 15.36, y: 7.25), controlPoint1: NSPoint(x: 15.87, y: 6.05), controlPoint2: NSPoint(x: 15.43, y: 7))
        takoHappyMouthInnerPath.curve(to: NSPoint(x: 15.03, y: 7.4), controlPoint1: NSPoint(x: 15.33, y: 7.37), controlPoint2: NSPoint(x: 15.32, y: 7.37))
        takoHappyMouthInnerPath.curve(to: NSPoint(x: 14.07, y: 7.41), controlPoint1: NSPoint(x: 14.87, y: 7.41), controlPoint2: NSPoint(x: 14.44, y: 7.42))
        takoHappyMouthInnerPath.curve(to: NSPoint(x: 13.38, y: 7.26), controlPoint1: NSPoint(x: 13.4, y: 7.4), controlPoint2: NSPoint(x: 13.4, y: 7.4))
        takoHappyMouthInnerPath.curve(to: NSPoint(x: 13.73, y: 6.17), controlPoint1: NSPoint(x: 13.36, y: 7.1), controlPoint2: NSPoint(x: 13.57, y: 6.43))
        takoHappyMouthInnerPath.curve(to: NSPoint(x: 14.02, y: 5.82), controlPoint1: NSPoint(x: 13.79, y: 6.06), controlPoint2: NSPoint(x: 13.92, y: 5.9))
        takoHappyMouthInnerPath.curve(to: NSPoint(x: 15.14, y: 5.31), controlPoint1: NSPoint(x: 14.24, y: 5.65), controlPoint2: NSPoint(x: 14.84, y: 5.38))
        takoHappyMouthInnerPath.curve(to: NSPoint(x: 16, y: 5.32), controlPoint1: NSPoint(x: 15.43, y: 5.25), controlPoint2: NSPoint(x: 15.53, y: 5.25))
        takoHappyMouthInnerPath.close()
        return takoHappyMouthInnerPath
    }()
    
    let takoHappyToothPath: NSBezierPath = {
        let takoHappyToothPath = NSBezierPath()
        takoHappyToothPath.move(to: NSPoint(x: 16.89, y: 6.76))
        takoHappyToothPath.curve(to: NSPoint(x: 17.23, y: 7.18), controlPoint1: NSPoint(x: 17.01, y: 6.92), controlPoint2: NSPoint(x: 17.16, y: 7.11))
        takoHappyToothPath.curve(to: NSPoint(x: 16.64, y: 7.34), controlPoint1: NSPoint(x: 17.35, y: 7.32), controlPoint2: NSPoint(x: 17.35, y: 7.32))
        takoHappyToothPath.curve(to: NSPoint(x: 15.92, y: 7.35), controlPoint1: NSPoint(x: 16.25, y: 7.35), controlPoint2: NSPoint(x: 15.92, y: 7.35))
        takoHappyToothPath.curve(to: NSPoint(x: 16.35, y: 6.27), controlPoint1: NSPoint(x: 15.86, y: 7.33), controlPoint2: NSPoint(x: 16.24, y: 6.38))
        takoHappyToothPath.curve(to: NSPoint(x: 16.54, y: 6.34), controlPoint1: NSPoint(x: 16.4, y: 6.22), controlPoint2: NSPoint(x: 16.43, y: 6.23))
        takoHappyToothPath.curve(to: NSPoint(x: 16.89, y: 6.76), controlPoint1: NSPoint(x: 16.61, y: 6.41), controlPoint2: NSPoint(x: 16.77, y: 6.6))
        takoHappyToothPath.close()
        return takoHappyToothPath
    }()
    
    let takoNormalLeftEyePath: NSBezierPath = {
        let takoNormalLeftEyePath = NSBezierPath()
        takoNormalLeftEyePath.move(to: NSPoint(x: 8.46, y: 7.97))
        takoNormalLeftEyePath.curve(to: NSPoint(x: 8.19, y: 8.23), controlPoint1: NSPoint(x: 8.31, y: 8.09), controlPoint2: NSPoint(x: 8.19, y: 8.2))
        takoNormalLeftEyePath.curve(to: NSPoint(x: 8.09, y: 8.26), controlPoint1: NSPoint(x: 8.19, y: 8.24), controlPoint2: NSPoint(x: 8.15, y: 8.26))
        takoNormalLeftEyePath.curve(to: NSPoint(x: 8.06, y: 8.72), controlPoint1: NSPoint(x: 7.89, y: 8.26), controlPoint2: NSPoint(x: 7.88, y: 8.43))
        takoNormalLeftEyePath.curve(to: NSPoint(x: 9.34, y: 9.39), controlPoint1: NSPoint(x: 8.13, y: 8.82), controlPoint2: NSPoint(x: 8.96, y: 9.26))
        takoNormalLeftEyePath.curve(to: NSPoint(x: 9.65, y: 9.53), controlPoint1: NSPoint(x: 9.48, y: 9.44), controlPoint2: NSPoint(x: 9.61, y: 9.5))
        takoNormalLeftEyePath.curve(to: NSPoint(x: 10.17, y: 9.77), controlPoint1: NSPoint(x: 9.68, y: 9.56), controlPoint2: NSPoint(x: 9.92, y: 9.67))
        takoNormalLeftEyePath.curve(to: NSPoint(x: 11.11, y: 10.16), controlPoint1: NSPoint(x: 10.44, y: 9.87), controlPoint2: NSPoint(x: 10.85, y: 10.05))
        takoNormalLeftEyePath.curve(to: NSPoint(x: 12.32, y: 10.45), controlPoint1: NSPoint(x: 11.7, y: 10.43), controlPoint2: NSPoint(x: 12.05, y: 10.51))
        takoNormalLeftEyePath.curve(to: NSPoint(x: 12.81, y: 10.13), controlPoint1: NSPoint(x: 12.52, y: 10.41), controlPoint2: NSPoint(x: 12.81, y: 10.22))
        takoNormalLeftEyePath.curve(to: NSPoint(x: 12.9, y: 10.02), controlPoint1: NSPoint(x: 12.81, y: 10.1), controlPoint2: NSPoint(x: 12.85, y: 10.05))
        takoNormalLeftEyePath.curve(to: NSPoint(x: 13.03, y: 9.84), controlPoint1: NSPoint(x: 12.95, y: 9.99), controlPoint2: NSPoint(x: 13.01, y: 9.9))
        takoNormalLeftEyePath.curve(to: NSPoint(x: 12.36, y: 9.22), controlPoint1: NSPoint(x: 13.07, y: 9.65), controlPoint2: NSPoint(x: 12.92, y: 9.51))
        takoNormalLeftEyePath.curve(to: NSPoint(x: 11.79, y: 8.91), controlPoint1: NSPoint(x: 12.1, y: 9.09), controlPoint2: NSPoint(x: 11.85, y: 8.95))
        takoNormalLeftEyePath.curve(to: NSPoint(x: 11.4, y: 8.72), controlPoint1: NSPoint(x: 11.74, y: 8.87), controlPoint2: NSPoint(x: 11.56, y: 8.79))
        takoNormalLeftEyePath.curve(to: NSPoint(x: 10.85, y: 8.49), controlPoint1: NSPoint(x: 11.24, y: 8.66), controlPoint2: NSPoint(x: 10.99, y: 8.56))
        takoNormalLeftEyePath.curve(to: NSPoint(x: 8.82, y: 7.76), controlPoint1: NSPoint(x: 10.36, y: 8.27), controlPoint2: NSPoint(x: 8.95, y: 7.75))
        takoNormalLeftEyePath.curve(to: NSPoint(x: 8.46, y: 7.97), controlPoint1: NSPoint(x: 8.77, y: 7.76), controlPoint2: NSPoint(x: 8.61, y: 7.85))
        takoNormalLeftEyePath.close()
        return takoNormalLeftEyePath
    }()
    
    let takoNormalRightEyePath: NSBezierPath = {
        let takoNormalRightEyePath = NSBezierPath()
        takoNormalRightEyePath.move(to: NSPoint(x: 22.87, y: 8.01))
        takoNormalRightEyePath.curve(to: NSPoint(x: 22.19, y: 8.21), controlPoint1: NSPoint(x: 22.8, y: 8.04), controlPoint2: NSPoint(x: 22.49, y: 8.13))
        takoNormalRightEyePath.curve(to: NSPoint(x: 20.88, y: 8.56), controlPoint1: NSPoint(x: 21.89, y: 8.29), controlPoint2: NSPoint(x: 21.29, y: 8.45))
        takoNormalRightEyePath.curve(to: NSPoint(x: 20.06, y: 8.78), controlPoint1: NSPoint(x: 20.45, y: 8.68), controlPoint2: NSPoint(x: 20.09, y: 8.78))
        takoNormalRightEyePath.curve(to: NSPoint(x: 19.71, y: 8.86), controlPoint1: NSPoint(x: 20.03, y: 8.78), controlPoint2: NSPoint(x: 19.87, y: 8.82))
        takoNormalRightEyePath.curve(to: NSPoint(x: 19.05, y: 9.03), controlPoint1: NSPoint(x: 19.54, y: 8.91), controlPoint2: NSPoint(x: 19.24, y: 8.98))
        takoNormalRightEyePath.curve(to: NSPoint(x: 18.64, y: 9.16), controlPoint1: NSPoint(x: 18.85, y: 9.08), controlPoint2: NSPoint(x: 18.67, y: 9.13))
        takoNormalRightEyePath.curve(to: NSPoint(x: 18.53, y: 9.21), controlPoint1: NSPoint(x: 18.61, y: 9.19), controlPoint2: NSPoint(x: 18.56, y: 9.21))
        takoNormalRightEyePath.curve(to: NSPoint(x: 18.47, y: 9.52), controlPoint1: NSPoint(x: 18.44, y: 9.21), controlPoint2: NSPoint(x: 18.4, y: 9.46))
        takoNormalRightEyePath.curve(to: NSPoint(x: 18.51, y: 9.67), controlPoint1: NSPoint(x: 18.5, y: 9.55), controlPoint2: NSPoint(x: 18.52, y: 9.62))
        takoNormalRightEyePath.curve(to: NSPoint(x: 18.57, y: 9.82), controlPoint1: NSPoint(x: 18.5, y: 9.73), controlPoint2: NSPoint(x: 18.53, y: 9.79))
        takoNormalRightEyePath.curve(to: NSPoint(x: 18.65, y: 9.96), controlPoint1: NSPoint(x: 18.61, y: 9.84), controlPoint2: NSPoint(x: 18.65, y: 9.9))
        takoNormalRightEyePath.curve(to: NSPoint(x: 19.25, y: 10.18), controlPoint1: NSPoint(x: 18.65, y: 10.18), controlPoint2: NSPoint(x: 18.88, y: 10.26))
        takoNormalRightEyePath.curve(to: NSPoint(x: 19.78, y: 10.11), controlPoint1: NSPoint(x: 19.33, y: 10.16), controlPoint2: NSPoint(x: 19.57, y: 10.13))
        takoNormalRightEyePath.curve(to: NSPoint(x: 22.65, y: 9.38), controlPoint1: NSPoint(x: 20.29, y: 10.06), controlPoint2: NSPoint(x: 22.18, y: 9.57))
        takoNormalRightEyePath.curve(to: NSPoint(x: 23.19, y: 9.21), controlPoint1: NSPoint(x: 22.76, y: 9.32), controlPoint2: NSPoint(x: 23.01, y: 9.25))
        takoNormalRightEyePath.curve(to: NSPoint(x: 23.56, y: 9.11), controlPoint1: NSPoint(x: 23.38, y: 9.17), controlPoint2: NSPoint(x: 23.54, y: 9.12))
        takoNormalRightEyePath.curve(to: NSPoint(x: 23.82, y: 8.94), controlPoint1: NSPoint(x: 23.57, y: 9.09), controlPoint2: NSPoint(x: 23.69, y: 9.02))
        takoNormalRightEyePath.curve(to: NSPoint(x: 23.95, y: 8.58), controlPoint1: NSPoint(x: 24.07, y: 8.79), controlPoint2: NSPoint(x: 24.11, y: 8.69))
        takoNormalRightEyePath.curve(to: NSPoint(x: 23.85, y: 8.47), controlPoint1: NSPoint(x: 23.89, y: 8.54), controlPoint2: NSPoint(x: 23.85, y: 8.5))
        takoNormalRightEyePath.curve(to: NSPoint(x: 23.55, y: 8.26), controlPoint1: NSPoint(x: 23.85, y: 8.42), controlPoint2: NSPoint(x: 23.7, y: 8.31))
        takoNormalRightEyePath.curve(to: NSPoint(x: 23.39, y: 8.11), controlPoint1: NSPoint(x: 23.49, y: 8.24), controlPoint2: NSPoint(x: 23.42, y: 8.17))
        takoNormalRightEyePath.curve(to: NSPoint(x: 23.29, y: 7.98), controlPoint1: NSPoint(x: 23.36, y: 8.05), controlPoint2: NSPoint(x: 23.32, y: 7.99))
        takoNormalRightEyePath.curve(to: NSPoint(x: 22.87, y: 8.01), controlPoint1: NSPoint(x: 23.21, y: 7.94), controlPoint2: NSPoint(x: 23.01, y: 7.95))
        takoNormalRightEyePath.close()
        return takoNormalRightEyePath
    }()
    
    let takoNormalMouthPath: NSBezierPath = {
        let takoNormalMouthPath = NSBezierPath()
        takoNormalMouthPath.move(to: NSPoint(x: 14.05, y: 5.41))
        takoNormalMouthPath.curve(to: NSPoint(x: 13.2, y: 5.65), controlPoint1: NSPoint(x: 13.71, y: 5.46), controlPoint2: NSPoint(x: 13.35, y: 5.56))
        takoNormalMouthPath.curve(to: NSPoint(x: 12.75, y: 6.94), controlPoint1: NSPoint(x: 12.79, y: 5.9), controlPoint2: NSPoint(x: 12.6, y: 6.45))
        takoNormalMouthPath.curve(to: NSPoint(x: 13.1, y: 7.49), controlPoint1: NSPoint(x: 12.84, y: 7.22), controlPoint2: NSPoint(x: 13, y: 7.46))
        takoNormalMouthPath.curve(to: NSPoint(x: 13.68, y: 7.33), controlPoint1: NSPoint(x: 13.23, y: 7.53), controlPoint2: NSPoint(x: 13.53, y: 7.44))
        takoNormalMouthPath.curve(to: NSPoint(x: 13.85, y: 6.92), controlPoint1: NSPoint(x: 13.8, y: 7.24), controlPoint2: NSPoint(x: 13.82, y: 7.18))
        takoNormalMouthPath.curve(to: NSPoint(x: 14.45, y: 6.34), controlPoint1: NSPoint(x: 13.91, y: 6.47), controlPoint2: NSPoint(x: 13.97, y: 6.41))
        takoNormalMouthPath.curve(to: NSPoint(x: 15.75, y: 6.45), controlPoint1: NSPoint(x: 14.83, y: 6.28), controlPoint2: NSPoint(x: 15.33, y: 6.32))
        takoNormalMouthPath.curve(to: NSPoint(x: 16.52, y: 6.42), controlPoint1: NSPoint(x: 16.16, y: 6.57), controlPoint2: NSPoint(x: 16.28, y: 6.56))
        takoNormalMouthPath.curve(to: NSPoint(x: 17.07, y: 6.27), controlPoint1: NSPoint(x: 16.69, y: 6.31), controlPoint2: NSPoint(x: 16.77, y: 6.29))
        takoNormalMouthPath.curve(to: NSPoint(x: 17.66, y: 6.32), controlPoint1: NSPoint(x: 17.37, y: 6.25), controlPoint2: NSPoint(x: 17.47, y: 6.26))
        takoNormalMouthPath.curve(to: NSPoint(x: 17.82, y: 6.77), controlPoint1: NSPoint(x: 17.92, y: 6.4), controlPoint2: NSPoint(x: 17.94, y: 6.46))
        takoNormalMouthPath.curve(to: NSPoint(x: 18.31, y: 7.28), controlPoint1: NSPoint(x: 17.69, y: 7.06), controlPoint2: NSPoint(x: 17.84, y: 7.22))
        takoNormalMouthPath.curve(to: NSPoint(x: 18.66, y: 7.2), controlPoint1: NSPoint(x: 18.47, y: 7.29), controlPoint2: NSPoint(x: 18.53, y: 7.28))
        takoNormalMouthPath.curve(to: NSPoint(x: 18.37, y: 5.76), controlPoint1: NSPoint(x: 19.23, y: 6.85), controlPoint2: NSPoint(x: 19.09, y: 6.2))
        takoNormalMouthPath.curve(to: NSPoint(x: 17.18, y: 5.4), controlPoint1: NSPoint(x: 17.91, y: 5.48), controlPoint2: NSPoint(x: 17.7, y: 5.41))
        takoNormalMouthPath.curve(to: NSPoint(x: 16.1, y: 5.56), controlPoint1: NSPoint(x: 16.72, y: 5.38), controlPoint2: NSPoint(x: 16.36, y: 5.44))
        takoNormalMouthPath.curve(to: NSPoint(x: 15.68, y: 5.52), controlPoint1: NSPoint(x: 16.01, y: 5.61), controlPoint2: NSPoint(x: 15.96, y: 5.6))
        takoNormalMouthPath.curve(to: NSPoint(x: 14.77, y: 5.41), controlPoint1: NSPoint(x: 15.41, y: 5.44), controlPoint2: NSPoint(x: 15.27, y: 5.42))
        takoNormalMouthPath.curve(to: NSPoint(x: 14.05, y: 5.41), controlPoint1: NSPoint(x: 14.44, y: 5.4), controlPoint2: NSPoint(x: 14.12, y: 5.4))
        takoNormalMouthPath.close()
        return takoNormalMouthPath
    }()
    
    let takoHungryLeftEyePath: NSBezierPath = {
        let takoHungryLeftEyePath = NSBezierPath()
        takoHungryLeftEyePath.move(to: NSPoint(x: 8.4, y: 7.96))
        takoHungryLeftEyePath.curve(to: NSPoint(x: 8.32, y: 8.12), controlPoint1: NSPoint(x: 8.36, y: 8.02), controlPoint2: NSPoint(x: 8.32, y: 8.1))
        takoHungryLeftEyePath.curve(to: NSPoint(x: 8.23, y: 8.22), controlPoint1: NSPoint(x: 8.32, y: 8.14), controlPoint2: NSPoint(x: 8.28, y: 8.19))
        takoHungryLeftEyePath.curve(to: NSPoint(x: 8.25, y: 8.69), controlPoint1: NSPoint(x: 8.05, y: 8.35), controlPoint2: NSPoint(x: 8.06, y: 8.47))
        takoHungryLeftEyePath.curve(to: NSPoint(x: 8.47, y: 8.99), controlPoint1: NSPoint(x: 8.34, y: 8.8), controlPoint2: NSPoint(x: 8.44, y: 8.93))
        takoHungryLeftEyePath.curve(to: NSPoint(x: 8.57, y: 9.1), controlPoint1: NSPoint(x: 8.5, y: 9.06), controlPoint2: NSPoint(x: 8.54, y: 9.1))
        takoHungryLeftEyePath.curve(to: NSPoint(x: 8.75, y: 9.22), controlPoint1: NSPoint(x: 8.59, y: 9.1), controlPoint2: NSPoint(x: 8.67, y: 9.16))
        takoHungryLeftEyePath.curve(to: NSPoint(x: 9.34, y: 9.44), controlPoint1: NSPoint(x: 8.85, y: 9.3), controlPoint2: NSPoint(x: 9.03, y: 9.36))
        takoHungryLeftEyePath.curve(to: NSPoint(x: 9.89, y: 9.6), controlPoint1: NSPoint(x: 9.59, y: 9.5), controlPoint2: NSPoint(x: 9.83, y: 9.57))
        takoHungryLeftEyePath.curve(to: NSPoint(x: 10.27, y: 9.7), controlPoint1: NSPoint(x: 9.94, y: 9.63), controlPoint2: NSPoint(x: 10.11, y: 9.67))
        takoHungryLeftEyePath.curve(to: NSPoint(x: 10.62, y: 9.79), controlPoint1: NSPoint(x: 10.43, y: 9.73), controlPoint2: NSPoint(x: 10.59, y: 9.77))
        takoHungryLeftEyePath.curve(to: NSPoint(x: 11.53, y: 10), controlPoint1: NSPoint(x: 10.69, y: 9.83), controlPoint2: NSPoint(x: 11.05, y: 9.92))
        takoHungryLeftEyePath.curve(to: NSPoint(x: 12.35, y: 10.16), controlPoint1: NSPoint(x: 11.74, y: 10.04), controlPoint2: NSPoint(x: 12.11, y: 10.11))
        takoHungryLeftEyePath.curve(to: NSPoint(x: 13.26, y: 10.06), controlPoint1: NSPoint(x: 13.15, y: 10.33), controlPoint2: NSPoint(x: 13.33, y: 10.31))
        takoHungryLeftEyePath.curve(to: NSPoint(x: 13.28, y: 9.94), controlPoint1: NSPoint(x: 13.24, y: 9.98), controlPoint2: NSPoint(x: 13.25, y: 9.94))
        takoHungryLeftEyePath.curve(to: NSPoint(x: 13.6, y: 9.44), controlPoint1: NSPoint(x: 13.34, y: 9.94), controlPoint2: NSPoint(x: 13.58, y: 9.56))
        takoHungryLeftEyePath.curve(to: NSPoint(x: 13.64, y: 9.28), controlPoint1: NSPoint(x: 13.61, y: 9.4), controlPoint2: NSPoint(x: 13.63, y: 9.33))
        takoHungryLeftEyePath.curve(to: NSPoint(x: 9.96, y: 8.15), controlPoint1: NSPoint(x: 13.73, y: 9.07), controlPoint2: NSPoint(x: 13.47, y: 8.99))
        takoHungryLeftEyePath.curve(to: NSPoint(x: 8.4, y: 7.96), controlPoint1: NSPoint(x: 8.44, y: 7.79), controlPoint2: NSPoint(x: 8.5, y: 7.79))
        takoHungryLeftEyePath.close()
        return takoHungryLeftEyePath
    }()
    
    let takoHungryRightEyePath: NSBezierPath = {
        let takoHungryRightEyePath = NSBezierPath()
        takoHungryRightEyePath.move(to: NSPoint(x: 23.02, y: 7.75))
        takoHungryRightEyePath.curve(to: NSPoint(x: 22.46, y: 7.92), controlPoint1: NSPoint(x: 22.9, y: 7.8), controlPoint2: NSPoint(x: 22.65, y: 7.87))
        takoHungryRightEyePath.curve(to: NSPoint(x: 21.76, y: 8.13), controlPoint1: NSPoint(x: 22.28, y: 7.96), controlPoint2: NSPoint(x: 21.96, y: 8.06))
        takoHungryRightEyePath.curve(to: NSPoint(x: 20.98, y: 8.35), controlPoint1: NSPoint(x: 21.56, y: 8.2), controlPoint2: NSPoint(x: 21.21, y: 8.3))
        takoHungryRightEyePath.curve(to: NSPoint(x: 20.08, y: 8.57), controlPoint1: NSPoint(x: 20.74, y: 8.39), controlPoint2: NSPoint(x: 20.34, y: 8.49))
        takoHungryRightEyePath.curve(to: NSPoint(x: 18.53, y: 9.18), controlPoint1: NSPoint(x: 19.55, y: 8.74), controlPoint2: NSPoint(x: 18.53, y: 9.13))
        takoHungryRightEyePath.curve(to: NSPoint(x: 18.51, y: 9.36), controlPoint1: NSPoint(x: 18.53, y: 9.19), controlPoint2: NSPoint(x: 18.52, y: 9.27))
        takoHungryRightEyePath.curve(to: NSPoint(x: 19, y: 10.12), controlPoint1: NSPoint(x: 18.48, y: 9.59), controlPoint2: NSPoint(x: 18.75, y: 10.02))
        takoHungryRightEyePath.curve(to: NSPoint(x: 20.54, y: 10), controlPoint1: NSPoint(x: 19.33, y: 10.26), controlPoint2: NSPoint(x: 20.19, y: 10.19))
        takoHungryRightEyePath.curve(to: NSPoint(x: 20.96, y: 9.82), controlPoint1: NSPoint(x: 20.63, y: 9.94), controlPoint2: NSPoint(x: 20.82, y: 9.86))
        takoHungryRightEyePath.curve(to: NSPoint(x: 21.56, y: 9.59), controlPoint1: NSPoint(x: 21.09, y: 9.77), controlPoint2: NSPoint(x: 21.36, y: 9.67))
        takoHungryRightEyePath.curve(to: NSPoint(x: 22.1, y: 9.4), controlPoint1: NSPoint(x: 21.77, y: 9.5), controlPoint2: NSPoint(x: 22.01, y: 9.42))
        takoHungryRightEyePath.curve(to: NSPoint(x: 22.46, y: 9.28), controlPoint1: NSPoint(x: 22.19, y: 9.39), controlPoint2: NSPoint(x: 22.35, y: 9.33))
        takoHungryRightEyePath.curve(to: NSPoint(x: 23.05, y: 9.11), controlPoint1: NSPoint(x: 22.57, y: 9.23), controlPoint2: NSPoint(x: 22.83, y: 9.15))
        takoHungryRightEyePath.curve(to: NSPoint(x: 23.49, y: 9.01), controlPoint1: NSPoint(x: 23.26, y: 9.06), controlPoint2: NSPoint(x: 23.46, y: 9.02))
        takoHungryRightEyePath.curve(to: NSPoint(x: 23.56, y: 8.84), controlPoint1: NSPoint(x: 23.51, y: 9), controlPoint2: NSPoint(x: 23.54, y: 8.92))
        takoHungryRightEyePath.curve(to: NSPoint(x: 23.7, y: 8.32), controlPoint1: NSPoint(x: 23.62, y: 8.49), controlPoint2: NSPoint(x: 23.64, y: 8.37))
        takoHungryRightEyePath.curve(to: NSPoint(x: 23.59, y: 7.98), controlPoint1: NSPoint(x: 23.75, y: 8.27), controlPoint2: NSPoint(x: 23.74, y: 8.23))
        takoHungryRightEyePath.curve(to: NSPoint(x: 23.54, y: 7.83), controlPoint1: NSPoint(x: 23.56, y: 7.94), controlPoint2: NSPoint(x: 23.54, y: 7.88))
        takoHungryRightEyePath.curve(to: NSPoint(x: 23.29, y: 7.67), controlPoint1: NSPoint(x: 23.54, y: 7.76), controlPoint2: NSPoint(x: 23.41, y: 7.67))
        takoHungryRightEyePath.curve(to: NSPoint(x: 23.02, y: 7.75), controlPoint1: NSPoint(x: 23.26, y: 7.67), controlPoint2: NSPoint(x: 23.13, y: 7.71))
        takoHungryRightEyePath.close()
        return takoHungryRightEyePath
    }()
    
    let takoHungryMouthPath: NSBezierPath = {
        let takoHungryMouthPath = NSBezierPath()
        takoHungryMouthPath.move(to: NSPoint(x: 16.67, y: 4.02))
        takoHungryMouthPath.curve(to: NSPoint(x: 16.41, y: 4.06), controlPoint1: NSPoint(x: 16.63, y: 4.02), controlPoint2: NSPoint(x: 16.51, y: 4.04))
        takoHungryMouthPath.curve(to: NSPoint(x: 15.75, y: 4.53), controlPoint1: NSPoint(x: 16.18, y: 4.09), controlPoint2: NSPoint(x: 15.87, y: 4.31))
        takoHungryMouthPath.curve(to: NSPoint(x: 15.71, y: 5.24), controlPoint1: NSPoint(x: 15.64, y: 4.71), controlPoint2: NSPoint(x: 15.63, y: 5.01))
        takoHungryMouthPath.curve(to: NSPoint(x: 15.74, y: 5.41), controlPoint1: NSPoint(x: 15.74, y: 5.33), controlPoint2: NSPoint(x: 15.75, y: 5.4))
        takoHungryMouthPath.curve(to: NSPoint(x: 15.22, y: 5.37), controlPoint1: NSPoint(x: 15.73, y: 5.42), controlPoint2: NSPoint(x: 15.49, y: 5.4))
        takoHungryMouthPath.curve(to: NSPoint(x: 13.36, y: 5.31), controlPoint1: NSPoint(x: 14.86, y: 5.32), controlPoint2: NSPoint(x: 14.34, y: 5.31))
        takoHungryMouthPath.curve(to: NSPoint(x: 11.73, y: 5.39), controlPoint1: NSPoint(x: 12.11, y: 5.31), controlPoint2: NSPoint(x: 11.97, y: 5.32))
        takoHungryMouthPath.curve(to: NSPoint(x: 11.05, y: 6.31), controlPoint1: NSPoint(x: 11.23, y: 5.54), controlPoint2: NSPoint(x: 10.96, y: 5.92))
        takoHungryMouthPath.curve(to: NSPoint(x: 12.3, y: 7.36), controlPoint1: NSPoint(x: 11.14, y: 6.66), controlPoint2: NSPoint(x: 11.82, y: 7.23))
        takoHungryMouthPath.curve(to: NSPoint(x: 12.88, y: 7.54), controlPoint1: NSPoint(x: 12.44, y: 7.4), controlPoint2: NSPoint(x: 12.7, y: 7.48))
        takoHungryMouthPath.curve(to: NSPoint(x: 15.76, y: 7.8), controlPoint1: NSPoint(x: 13.45, y: 7.72), controlPoint2: NSPoint(x: 14.7, y: 7.84))
        takoHungryMouthPath.curve(to: NSPoint(x: 17.94, y: 7.62), controlPoint1: NSPoint(x: 16.45, y: 7.77), controlPoint2: NSPoint(x: 17.5, y: 7.69))
        takoHungryMouthPath.curve(to: NSPoint(x: 19.61, y: 6.92), controlPoint1: NSPoint(x: 18.65, y: 7.51), controlPoint2: NSPoint(x: 19.25, y: 7.26))
        takoHungryMouthPath.curve(to: NSPoint(x: 19.99, y: 6.18), controlPoint1: NSPoint(x: 19.96, y: 6.59), controlPoint2: NSPoint(x: 20.06, y: 6.39))
        takoHungryMouthPath.curve(to: NSPoint(x: 18.61, y: 5.59), controlPoint1: NSPoint(x: 19.87, y: 5.82), controlPoint2: NSPoint(x: 19.45, y: 5.64))
        takoHungryMouthPath.curve(to: NSPoint(x: 18, y: 5.55), controlPoint1: NSPoint(x: 18.29, y: 5.57), controlPoint2: NSPoint(x: 18.02, y: 5.55))
        takoHungryMouthPath.curve(to: NSPoint(x: 17.99, y: 5.52), controlPoint1: NSPoint(x: 17.98, y: 5.55), controlPoint2: NSPoint(x: 17.97, y: 5.53))
        takoHungryMouthPath.curve(to: NSPoint(x: 17.82, y: 4.72), controlPoint1: NSPoint(x: 18.03, y: 5.46), controlPoint2: NSPoint(x: 17.92, y: 4.94))
        takoHungryMouthPath.curve(to: NSPoint(x: 17.42, y: 4.12), controlPoint1: NSPoint(x: 17.68, y: 4.41), controlPoint2: NSPoint(x: 17.59, y: 4.27))
        takoHungryMouthPath.curve(to: NSPoint(x: 17.01, y: 4), controlPoint1: NSPoint(x: 17.29, y: 4.01), controlPoint2: NSPoint(x: 17.25, y: 4))
        takoHungryMouthPath.curve(to: NSPoint(x: 16.67, y: 4.02), controlPoint1: NSPoint(x: 16.86, y: 4), controlPoint2: NSPoint(x: 16.7, y: 4.01))
        takoHungryMouthPath.close()
        takoHungryMouthPath.move(to: NSPoint(x: 16.85, y: 4.39))
        takoHungryMouthPath.curve(to: NSPoint(x: 17.32, y: 4.72), controlPoint1: NSPoint(x: 17.04, y: 4.44), controlPoint2: NSPoint(x: 17.22, y: 4.57))
        takoHungryMouthPath.curve(to: NSPoint(x: 17.43, y: 5.73), controlPoint1: NSPoint(x: 17.42, y: 4.88), controlPoint2: NSPoint(x: 17.48, y: 5.51))
        takoHungryMouthPath.curve(to: NSPoint(x: 17.74, y: 6.06), controlPoint1: NSPoint(x: 17.37, y: 5.96), controlPoint2: NSPoint(x: 17.43, y: 6.02))
        takoHungryMouthPath.curve(to: NSPoint(x: 17.64, y: 6.23), controlPoint1: NSPoint(x: 17.98, y: 6.08), controlPoint2: NSPoint(x: 17.98, y: 6.08))
        takoHungryMouthPath.curve(to: NSPoint(x: 17.02, y: 6.38), controlPoint1: NSPoint(x: 17.36, y: 6.36), controlPoint2: NSPoint(x: 17.26, y: 6.38))
        takoHungryMouthPath.curve(to: NSPoint(x: 16.02, y: 6.1), controlPoint1: NSPoint(x: 16.57, y: 6.38), controlPoint2: NSPoint(x: 16.24, y: 6.29))
        takoHungryMouthPath.curve(to: NSPoint(x: 15.97, y: 5.95), controlPoint1: NSPoint(x: 15.82, y: 5.95), controlPoint2: NSPoint(x: 15.82, y: 5.95))
        takoHungryMouthPath.curve(to: NSPoint(x: 16.42, y: 5.79), controlPoint1: NSPoint(x: 16.2, y: 5.95), controlPoint2: NSPoint(x: 16.42, y: 5.87))
        takoHungryMouthPath.curve(to: NSPoint(x: 16.31, y: 5.46), controlPoint1: NSPoint(x: 16.42, y: 5.75), controlPoint2: NSPoint(x: 16.37, y: 5.6))
        takoHungryMouthPath.curve(to: NSPoint(x: 16.28, y: 4.6), controlPoint1: NSPoint(x: 16.16, y: 5.12), controlPoint2: NSPoint(x: 16.15, y: 4.85))
        takoHungryMouthPath.curve(to: NSPoint(x: 16.85, y: 4.39), controlPoint1: NSPoint(x: 16.41, y: 4.36), controlPoint2: NSPoint(x: 16.53, y: 4.31))
        takoHungryMouthPath.close()
        takoHungryMouthPath.move(to: NSPoint(x: 12.13, y: 5.78))
        takoHungryMouthPath.curve(to: NSPoint(x: 14.11, y: 5.88), controlPoint1: NSPoint(x: 12.27, y: 5.84), controlPoint2: NSPoint(x: 12.84, y: 5.87))
        takoHungryMouthPath.curve(to: NSPoint(x: 15.41, y: 5.99), controlPoint1: NSPoint(x: 15.34, y: 5.89), controlPoint2: NSPoint(x: 15.34, y: 5.89))
        takoHungryMouthPath.curve(to: NSPoint(x: 17.2, y: 6.62), controlPoint1: NSPoint(x: 15.78, y: 6.46), controlPoint2: NSPoint(x: 16.47, y: 6.7))
        takoHungryMouthPath.curve(to: NSPoint(x: 18.28, y: 6.19), controlPoint1: NSPoint(x: 17.58, y: 6.58), controlPoint2: NSPoint(x: 18, y: 6.41))
        takoHungryMouthPath.curve(to: NSPoint(x: 18.77, y: 6.06), controlPoint1: NSPoint(x: 18.42, y: 6.07), controlPoint2: NSPoint(x: 18.45, y: 6.06))
        takoHungryMouthPath.curve(to: NSPoint(x: 19.24, y: 6.15), controlPoint1: NSPoint(x: 19.04, y: 6.06), controlPoint2: NSPoint(x: 19.14, y: 6.08))
        takoHungryMouthPath.curve(to: NSPoint(x: 19.36, y: 6.28), controlPoint1: NSPoint(x: 19.31, y: 6.19), controlPoint2: NSPoint(x: 19.36, y: 6.26))
        takoHungryMouthPath.curve(to: NSPoint(x: 18.6, y: 6.87), controlPoint1: NSPoint(x: 19.36, y: 6.37), controlPoint2: NSPoint(x: 18.8, y: 6.8))
        takoHungryMouthPath.curve(to: NSPoint(x: 17.37, y: 7.21), controlPoint1: NSPoint(x: 18.08, y: 7.05), controlPoint2: NSPoint(x: 17.62, y: 7.17))
        takoHungryMouthPath.curve(to: NSPoint(x: 14.24, y: 7.22), controlPoint1: NSPoint(x: 17.01, y: 7.27), controlPoint2: NSPoint(x: 14.69, y: 7.27))
        takoHungryMouthPath.curve(to: NSPoint(x: 11.74, y: 6.35), controlPoint1: NSPoint(x: 13.44, y: 7.12), controlPoint2: NSPoint(x: 12.05, y: 6.64))
        takoHungryMouthPath.curve(to: NSPoint(x: 11.59, y: 6.05), controlPoint1: NSPoint(x: 11.58, y: 6.2), controlPoint2: NSPoint(x: 11.56, y: 6.16))
        takoHungryMouthPath.curve(to: NSPoint(x: 11.82, y: 5.8), controlPoint1: NSPoint(x: 11.63, y: 5.88), controlPoint2: NSPoint(x: 11.64, y: 5.87))
        takoHungryMouthPath.curve(to: NSPoint(x: 12.13, y: 5.78), controlPoint1: NSPoint(x: 12, y: 5.74), controlPoint2: NSPoint(x: 12.03, y: 5.74))
        takoHungryMouthPath.close()
        return takoHungryMouthPath
    }()
    
    let takoHungryMouthInnerPath: NSBezierPath = {
        let takoHungryMouthInnerPath = NSBezierPath()
        takoHungryMouthInnerPath.move(to: NSPoint(x: 12.13, y: 5.78))
        takoHungryMouthInnerPath.curve(to: NSPoint(x: 14.11, y: 5.88), controlPoint1: NSPoint(x: 12.27, y: 5.84), controlPoint2: NSPoint(x: 12.84, y: 5.87))
        takoHungryMouthInnerPath.curve(to: NSPoint(x: 15.41, y: 5.99), controlPoint1: NSPoint(x: 15.34, y: 5.89), controlPoint2: NSPoint(x: 15.34, y: 5.89))
        takoHungryMouthInnerPath.curve(to: NSPoint(x: 17.2, y: 6.62), controlPoint1: NSPoint(x: 15.78, y: 6.46), controlPoint2: NSPoint(x: 16.47, y: 6.7))
        takoHungryMouthInnerPath.curve(to: NSPoint(x: 18.28, y: 6.19), controlPoint1: NSPoint(x: 17.58, y: 6.58), controlPoint2: NSPoint(x: 18, y: 6.41))
        takoHungryMouthInnerPath.curve(to: NSPoint(x: 18.77, y: 6.06), controlPoint1: NSPoint(x: 18.42, y: 6.07), controlPoint2: NSPoint(x: 18.45, y: 6.06))
        takoHungryMouthInnerPath.curve(to: NSPoint(x: 19.24, y: 6.15), controlPoint1: NSPoint(x: 19.04, y: 6.06), controlPoint2: NSPoint(x: 19.14, y: 6.08))
        takoHungryMouthInnerPath.curve(to: NSPoint(x: 19.36, y: 6.28), controlPoint1: NSPoint(x: 19.31, y: 6.19), controlPoint2: NSPoint(x: 19.36, y: 6.26))
        takoHungryMouthInnerPath.curve(to: NSPoint(x: 18.6, y: 6.87), controlPoint1: NSPoint(x: 19.36, y: 6.37), controlPoint2: NSPoint(x: 18.8, y: 6.8))
        takoHungryMouthInnerPath.curve(to: NSPoint(x: 17.37, y: 7.21), controlPoint1: NSPoint(x: 18.08, y: 7.05), controlPoint2: NSPoint(x: 17.62, y: 7.17))
        takoHungryMouthInnerPath.curve(to: NSPoint(x: 14.24, y: 7.22), controlPoint1: NSPoint(x: 17.01, y: 7.27), controlPoint2: NSPoint(x: 14.69, y: 7.27))
        takoHungryMouthInnerPath.curve(to: NSPoint(x: 11.74, y: 6.35), controlPoint1: NSPoint(x: 13.44, y: 7.12), controlPoint2: NSPoint(x: 12.05, y: 6.64))
        takoHungryMouthInnerPath.curve(to: NSPoint(x: 11.59, y: 6.05), controlPoint1: NSPoint(x: 11.58, y: 6.2), controlPoint2: NSPoint(x: 11.56, y: 6.16))
        takoHungryMouthInnerPath.curve(to: NSPoint(x: 11.82, y: 5.8), controlPoint1: NSPoint(x: 11.63, y: 5.88), controlPoint2: NSPoint(x: 11.64, y: 5.87))
        takoHungryMouthInnerPath.curve(to: NSPoint(x: 12.13, y: 5.78), controlPoint1: NSPoint(x: 12, y: 5.74), controlPoint2: NSPoint(x: 12.03, y: 5.74))
        takoHungryMouthInnerPath.close()
        return takoHungryMouthInnerPath
    }()
    
    let takoHungrySalivaPath: NSBezierPath = {
        let takoHungrySalivaPath = NSBezierPath()
        takoHungrySalivaPath.move(to: NSPoint(x: 16.85, y: 4.39))
        takoHungrySalivaPath.curve(to: NSPoint(x: 17.32, y: 4.72), controlPoint1: NSPoint(x: 17.04, y: 4.44), controlPoint2: NSPoint(x: 17.22, y: 4.57))
        takoHungrySalivaPath.curve(to: NSPoint(x: 17.43, y: 5.73), controlPoint1: NSPoint(x: 17.42, y: 4.88), controlPoint2: NSPoint(x: 17.48, y: 5.51))
        takoHungrySalivaPath.curve(to: NSPoint(x: 17.74, y: 6.06), controlPoint1: NSPoint(x: 17.37, y: 5.96), controlPoint2: NSPoint(x: 17.43, y: 6.02))
        takoHungrySalivaPath.curve(to: NSPoint(x: 17.64, y: 6.23), controlPoint1: NSPoint(x: 17.98, y: 6.08), controlPoint2: NSPoint(x: 17.98, y: 6.08))
        takoHungrySalivaPath.curve(to: NSPoint(x: 17.02, y: 6.38), controlPoint1: NSPoint(x: 17.36, y: 6.36), controlPoint2: NSPoint(x: 17.26, y: 6.38))
        takoHungrySalivaPath.curve(to: NSPoint(x: 16.02, y: 6.1), controlPoint1: NSPoint(x: 16.57, y: 6.38), controlPoint2: NSPoint(x: 16.24, y: 6.29))
        takoHungrySalivaPath.curve(to: NSPoint(x: 15.97, y: 5.95), controlPoint1: NSPoint(x: 15.82, y: 5.95), controlPoint2: NSPoint(x: 15.82, y: 5.95))
        takoHungrySalivaPath.curve(to: NSPoint(x: 16.42, y: 5.79), controlPoint1: NSPoint(x: 16.2, y: 5.95), controlPoint2: NSPoint(x: 16.42, y: 5.87))
        takoHungrySalivaPath.curve(to: NSPoint(x: 16.31, y: 5.46), controlPoint1: NSPoint(x: 16.42, y: 5.75), controlPoint2: NSPoint(x: 16.37, y: 5.6))
        takoHungrySalivaPath.curve(to: NSPoint(x: 16.28, y: 4.6), controlPoint1: NSPoint(x: 16.16, y: 5.12), controlPoint2: NSPoint(x: 16.15, y: 4.85))
        takoHungrySalivaPath.curve(to: NSPoint(x: 16.85, y: 4.39), controlPoint1: NSPoint(x: 16.41, y: 4.36), controlPoint2: NSPoint(x: 16.53, y: 4.31))
        takoHungrySalivaPath.close()
        return takoHungrySalivaPath
    }()
   
    let takoStravingRingPath: NSBezierPath = {
        let takoStravingRingPath = NSBezierPath()
        takoStravingRingPath.move(to: NSPoint(x: 17.89, y: 15.22))
        takoStravingRingPath.curve(to: NSPoint(x: 16.5, y: 15.26), controlPoint1: NSPoint(x: 17.88, y: 15.23), controlPoint2: NSPoint(x: 17.25, y: 15.25))
        takoStravingRingPath.curve(to: NSPoint(x: 11.52, y: 15.43), controlPoint1: NSPoint(x: 14.54, y: 15.31), controlPoint2: NSPoint(x: 12.05, y: 15.39))
        takoStravingRingPath.curve(to: NSPoint(x: 10.84, y: 15.7), controlPoint1: NSPoint(x: 11.08, y: 15.47), controlPoint2: NSPoint(x: 11.07, y: 15.47))
        takoStravingRingPath.curve(to: NSPoint(x: 10.53, y: 16.23), controlPoint1: NSPoint(x: 10.63, y: 15.9), controlPoint2: NSPoint(x: 10.58, y: 15.98))
        takoStravingRingPath.curve(to: NSPoint(x: 10.59, y: 17.36), controlPoint1: NSPoint(x: 10.47, y: 16.56), controlPoint2: NSPoint(x: 10.5, y: 17.17))
        takoStravingRingPath.curve(to: NSPoint(x: 11.28, y: 18.16), controlPoint1: NSPoint(x: 10.75, y: 17.66), controlPoint2: NSPoint(x: 11.06, y: 18.03))
        takoStravingRingPath.curve(to: NSPoint(x: 13.32, y: 18.66), controlPoint1: NSPoint(x: 11.6, y: 18.35), controlPoint2: NSPoint(x: 12.72, y: 18.53))
        takoStravingRingPath.curve(to: NSPoint(x: 17.17, y: 18.83), controlPoint1: NSPoint(x: 13.63, y: 18.72), controlPoint2: NSPoint(x: 16.29, y: 18.91))
        takoStravingRingPath.curve(to: NSPoint(x: 20.65, y: 18.11), controlPoint1: NSPoint(x: 18.75, y: 18.68), controlPoint2: NSPoint(x: 20.08, y: 18.41))
        takoStravingRingPath.curve(to: NSPoint(x: 21.24, y: 17.72), controlPoint1: NSPoint(x: 20.78, y: 18.04), controlPoint2: NSPoint(x: 21.05, y: 17.87))
        takoStravingRingPath.curve(to: NSPoint(x: 21.74, y: 16.32), controlPoint1: NSPoint(x: 21.79, y: 17.31), controlPoint2: NSPoint(x: 21.89, y: 17.04))
        takoStravingRingPath.curve(to: NSPoint(x: 20.9, y: 15.23), controlPoint1: NSPoint(x: 21.61, y: 15.71), controlPoint2: NSPoint(x: 21.31, y: 15.31))
        takoStravingRingPath.curve(to: NSPoint(x: 17.89, y: 15.22), controlPoint1: NSPoint(x: 20.71, y: 15.2), controlPoint2: NSPoint(x: 17.92, y: 15.19))
        takoStravingRingPath.close()
        takoStravingRingPath.move(to: NSPoint(x: 20.48, y: 16.19))
        takoStravingRingPath.curve(to: NSPoint(x: 20.61, y: 16.96), controlPoint1: NSPoint(x: 20.71, y: 16.43), controlPoint2: NSPoint(x: 20.76, y: 16.71))
        takoStravingRingPath.curve(to: NSPoint(x: 19, y: 17.53), controlPoint1: NSPoint(x: 20.42, y: 17.28), controlPoint2: NSPoint(x: 19.65, y: 17.45))
        takoStravingRingPath.curve(to: NSPoint(x: 18.33, y: 17.65), controlPoint1: NSPoint(x: 18.85, y: 17.55), controlPoint2: NSPoint(x: 18.55, y: 17.61))
        takoStravingRingPath.curve(to: NSPoint(x: 14.9, y: 17.65), controlPoint1: NSPoint(x: 17.86, y: 17.74), controlPoint2: NSPoint(x: 15.95, y: 17.66))
        takoStravingRingPath.curve(to: NSPoint(x: 11.76, y: 17.29), controlPoint1: NSPoint(x: 13.43, y: 17.65), controlPoint2: NSPoint(x: 12.11, y: 17.7))
        takoStravingRingPath.curve(to: NSPoint(x: 11.7, y: 16.44), controlPoint1: NSPoint(x: 11.6, y: 17.1), controlPoint2: NSPoint(x: 11.57, y: 16.63))
        takoStravingRingPath.curve(to: NSPoint(x: 15.11, y: 16.22), controlPoint1: NSPoint(x: 11.91, y: 16.13), controlPoint2: NSPoint(x: 11.6, y: 16.24))
        takoStravingRingPath.curve(to: NSPoint(x: 18.55, y: 16.14), controlPoint1: NSPoint(x: 16.97, y: 16.2), controlPoint2: NSPoint(x: 18.42, y: 16.17))
        takoStravingRingPath.curve(to: NSPoint(x: 19.54, y: 16.1), controlPoint1: NSPoint(x: 18.68, y: 16.11), controlPoint2: NSPoint(x: 19.12, y: 16.09))
        takoStravingRingPath.curve(to: NSPoint(x: 20.48, y: 16.19), controlPoint1: NSPoint(x: 20.3, y: 16.11), controlPoint2: NSPoint(x: 20.3, y: 16.01))
        takoStravingRingPath.close()
        return takoStravingRingPath
    }()
    
    let takoShapePathLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = 0
        layer.strokeColor = NSColor.clear.cgColor
        layer.fillColor = NSColor.black.cgColor
        return layer
    }()
    
    let takoLeftEyePathLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = 0
        layer.strokeColor = NSColor.clear.cgColor
        layer.fillColor = NSColor.black.cgColor
        return layer
    }()
    
    let takoRightEyePathLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = 0
        layer.strokeColor = NSColor.clear.cgColor
        layer.fillColor = NSColor.black.cgColor
        return layer
    }()
    
    let takoMouthPathLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = 0
        layer.strokeColor = NSColor.clear.cgColor
        layer.fillColor = NSColor.black.cgColor
        return layer
    }()
    
    let takoMouthInnerPathLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = 0
        layer.strokeColor = NSColor.clear.cgColor
        layer.fillColor = NSColor.init(named: "TakoMouthInner")?.cgColor
        return layer
    }()
    
    let takoToothPathLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = 0
        layer.strokeColor = NSColor.clear.cgColor
        layer.fillColor = NSColor.white.cgColor
        return layer
    }()
    
    let takoRingPathLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = 0
        layer.strokeColor = NSColor.clear.cgColor
        layer.fillColor = NSColor.init(named: "TakoRing")?.cgColor
        return layer
    }()
    
    let takoSkinPathLeftLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = 0
        layer.strokeColor = NSColor.clear.cgColor
        layer.fillColor = NSColor.init(named: "TakoSkin")?.cgColor
        return layer
    }()
    
    let takoSkinPathRightLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = 0
        layer.strokeColor = NSColor.clear.cgColor
        layer.fillColor = NSColor.clear.cgColor
        return layer
    }()
    
    let leftSideMaskLayer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = NSColor.black.cgColor
        return layer
    }()
    
    let rightSideMaskLayer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = NSColor.black.cgColor
        return layer
    }()
    
    let tentacleView: TentacleImage?
    
    // original vector image is drawn on a 34.0-by-20.0 canvas
    static let baseWidth: CGFloat  = 34.0
    static let baseHeight: CGFloat = 20.0
    var scaleXMultiplier: CGFloat = 1.0
    var scaleYMultiplier: CGFloat = 1.0
    // proportionally scale by default
    var scaleProportional: Bool = true
    // default is to fit in the view
    var proportionalFill: Bool = false
    // status
    var status: BattakoreyStatus = .Happy
    var prevStatus: BattakoreyStatus = .Unknown
    var prevCharging: BattakoreyChargingStatus = .Unknown
    
    func addLayers() {
        self.wantsLayer = true
        self.layer?.addSublayer(takoShapePathLayer)
        self.layer!.addSublayer(takoSkinPathLeftLayer)
        self.layer!.addSublayer(takoSkinPathRightLayer)
        self.layer!.addSublayer(takoLeftEyePathLayer)
        self.layer!.addSublayer(takoRightEyePathLayer)
        self.layer!.addSublayer(takoMouthPathLayer)
        self.layer!.addSublayer(takoMouthInnerPathLayer)
        self.layer!.addSublayer(takoToothPathLayer)
        self.layer!.addSublayer(takoRingPathLayer)
        
        takoSkinPathLeftLayer.mask = leftSideMaskLayer
        takoSkinPathRightLayer.mask = rightSideMaskLayer
    }
    
    func updateScaleMultiplier(_ width: CGFloat, _ height: CGFloat) {
        self.scaleXMultiplier = width  / BattakoreyImage.baseWidth;
        self.scaleYMultiplier = height / BattakoreyImage.baseHeight;
        if self.scaleProportional {
            let newMultiplier: CGFloat
            if self.proportionalFill {
                newMultiplier = max(self.scaleXMultiplier, self.scaleYMultiplier)
            } else {
                newMultiplier = min(self.scaleXMultiplier, self.scaleYMultiplier)
            }
            self.scaleXMultiplier = newMultiplier
            self.scaleYMultiplier = newMultiplier
        }
        
        let transform = NSAffineTransform.init()
        transform.scaleX(by: self.scaleXMultiplier, yBy: self.scaleYMultiplier)
        
        takoShapePathLayer.path = transform.transform(takoShapePath).cgPath
        takoSkinPathLeftLayer.path = transform.transform(takoSkinPath).cgPath
        takoSkinPathRightLayer.path = transform.transform(takoSkinPath).cgPath
    }
    
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        self.tentacleView?.setFrameSize(NSMakeSize(
            TentacleImage.baseWidth/BattakoreyImage.baseWidth*newSize.width,
            TentacleImage.baseHeight/BattakoreyImage.baseHeight*newSize.height))
        updateScaleMultiplier(newSize.width, newSize.height)
    }
    
    override init(frame frameRect: NSRect) {
        tentacleView = TentacleImage.init(frame: NSMakeRect(0, 0, TentacleImage.baseWidth/BattakoreyImage.baseWidth*frameRect.width, TentacleImage.baseHeight/BattakoreyImage.baseHeight*frameRect.height))
        super.init(frame: frameRect)
        updateScaleMultiplier(frameRect.width, frameRect.height)
        addLayers()
        tentacleView!.isHidden = true
        self.addSubview(tentacleView!)
    }
    
    required init?(coder: NSCoder) {
        tentacleView = TentacleImage.init(frame: NSMakeRect(0, 0, TentacleImage.baseWidth, TentacleImage.baseHeight))
        super.init(coder: coder)
        addLayers()
        tentacleView?.isHidden = true
        self.addSubview(tentacleView!)
    }
    
    func updateImage(_ percentage: CGFloat) {
        self.percentage = percentage
        self.needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        var leftMaskFrame = self.bounds
        let scale = self.percentage / 100.0
        leftMaskFrame.size.width *= scale
        
        var rightMaskFrame = self.bounds
        rightMaskFrame.origin.x = leftMaskFrame.size.width * scale
        
        let transform = NSAffineTransform.init()
        transform.scaleX(by: scaleXMultiplier, yBy: scaleYMultiplier)
        
        var redraw = false
        if isCharging {
            let xTranslation = NSAffineTransform.init()
            xTranslation.translateX(by: 3, yBy: 0)
            transform.append(xTranslation as AffineTransform)
            
            if prevCharging != .Charging {
                redraw = true
                prevCharging = .Charging
                tentacleView?.isHidden = false
            }
        } else {
            if prevCharging != .NotCharging {
                redraw = true
                prevCharging = .NotCharging
                tentacleView?.isHidden = true
            }
        }
        
        if redraw {
            takoShapePathLayer.path = transform.transform(takoShapePath).cgPath
            takoSkinPathLeftLayer.path = transform.transform(takoSkinPath).cgPath
            takoSkinPathRightLayer.path = transform.transform(takoSkinPath).cgPath
        }
        
        if percentage >= 70 {
            status = .Happy
            if prevStatus != status || redraw {
                takoLeftEyePathLayer.path = transform.transform(takoHappyLeftEyePath).cgPath
                takoRightEyePathLayer.path = transform.transform(takoHappyRightEyePath).cgPath
                takoMouthPathLayer.path = transform.transform(takoHappyMouthPath).cgPath
                takoMouthInnerPathLayer.path = transform.transform(takoHappyMouthInnerPath).cgPath
                takoToothPathLayer.path = transform.transform(takoHappyToothPath).cgPath
                prevStatus = status
            }
        } else if percentage >= 40 {
            status = .Normal
            if prevStatus != status || redraw {
                takoLeftEyePathLayer.path = transform.transform(takoNormalLeftEyePath).cgPath
                takoRightEyePathLayer.path = transform.transform(takoNormalRightEyePath).cgPath
                takoMouthPathLayer.path = transform.transform(takoNormalMouthPath).cgPath
                takoMouthInnerPathLayer.path = nil
                takoToothPathLayer.path = nil
                prevStatus = status
            }
        } else {
            status = .Hungry
            if percentage < 20 {
                status = .Starving
            }
            
            if prevStatus != status || redraw {
                takoLeftEyePathLayer.path = transform.transform(takoHungryLeftEyePath).cgPath
                takoRightEyePathLayer.path = transform.transform(takoHungryRightEyePath).cgPath
                takoMouthPathLayer.path = transform.transform(takoHungryMouthPath).cgPath
                takoMouthInnerPathLayer.path = transform.transform(takoHungryMouthInnerPath).cgPath
                takoToothPathLayer.path = transform.transform(takoHungrySalivaPath).cgPath
                prevStatus = status
            }
        }
        
        if status != .Starving {
            takoRingPathLayer.path = nil
        } else {
            takoRingPathLayer.path = transform.transform(takoStravingRingPath).cgPath
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        leftSideMaskLayer.frame = leftMaskFrame
        rightSideMaskLayer.frame = rightMaskFrame
        CATransaction.commit()
    }
}
