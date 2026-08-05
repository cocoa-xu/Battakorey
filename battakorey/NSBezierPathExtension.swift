//
//  NSBezierPathExtension.swift
//  battakorey
//
//  Created by Cocoa on 09/07/2021.
//

import Foundation
import AppKit


extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)

            switch type {
            case .moveTo:
                path.move(to: points[0])

            case .lineTo:
                path.addLine(to: points[0])

            case .curveTo, .cubicCurveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])

            case .quadraticCurveTo:
                path.addQuadCurve(to: points[1], control: points[0])

            case .closePath:
                path.closeSubpath()

            @unknown default:
                break
            }
        }
        return path
    }
}
