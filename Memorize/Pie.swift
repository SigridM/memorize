//
//  Pie.swift
//  Memorize
//
//  Created by Sigrid Mortensen on 11/1/22.
//

import SwiftUI

struct Pie: Shape {

    var startAngle: Angle
    var endAngle: Angle
    var clockwise = false
    
    var animatableData: AnimatablePair<Double, Double> {
        get {
            AnimatablePair(startAngle.radians, endAngle.radians)
        }
        set {
            startAngle = Angle.radians(newValue.first)
            endAngle = Angle.radians(newValue.second)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(
            x: rect.midX,
            y: rect.midY
        )
        let start = CGPoint(
            x: center.x + CGFloat(cos(startAngle.radians)) * radius,
            y: center.y + CGFloat(sin(startAngle.radians)) * radius
            )
        var path = Path()
        path.move(to: center)
        path.addLine(to: start)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: !clockwise
        )
        path.addLine(to: center)
        return path
    }

}
