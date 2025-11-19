//
//  Cardify.swift
//  Memorize
//
//  Created by Sigrid Mortensen on 11/2/22.
//

import SwiftUI

struct Cardify: AnimatableModifier {
    var radius: CGFloat
    var rotation: Double // in degrees
    
    var animatableData: Double {
        get {rotation}
        set {rotation = newValue}
    }
    
    init(isFaceUp: Bool, radius: CGFloat) {
        rotation = isFaceUp ? 0 : 180
        self.radius = radius
    }
    
    func body(content: Content) -> some View {
        ZStack {
            let shape = RoundedRectangle(cornerRadius: radius)
            if rotation < 90 {
                shape.fill(.white)
                shape.strokeBorder(lineWidth: CardifyConstants.cardBorderWidth)
            } else {
                shape.fill()
            }
            content
                .opacity(rotation < 90 ? 1 : 0)
        }
        .rotation3DEffect(Angle.degrees(rotation), axis: (x: 0, y: 1, z: 0))
    }
    
    struct CardifyConstants {
        static let cardBorderWidth = 3.0
    }
}

extension View {
    func cardify(isFaceUp: Bool, radius: CGFloat) -> some View {
        self.modifier(Cardify(isFaceUp: isFaceUp, radius: radius))
    }
}
