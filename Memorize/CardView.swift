//
//  CardView.swift
//  Memorize
//
//  Created by Sigrid Mortensen on 9/15/22.
//

import SwiftUI


/// The view of one single card, which can show an image when face up, and hides that image but shows the back of the card
/// when face down. If the card is matched, it will appear slightly shaded if face up, and will disappear entirely if face down.
struct CardView: View {
    
    /// The model for which this CardView is the View
    let card: EmojiMemoryGame.Card
    
    /// The radius of the circle that defines the rounded corner of the card; can be changed when the card changes size
    var radius: Double
    
    /// A ZStack that consists of a rounded rectangle and some text, typically a single-character emoji. It will be displayed
    /// differently depending on the state of the card (whether face up or face down, matched or unmatched).
    var body: some View {
        ZStack {
            let shape = RoundedRectangle(cornerRadius: radius)
            switch card.state() {
            case .faceDownAndMatched:
                shape.opacity(ViewConstants.downAndMatchedOpacity)
            case .faceDownAndUnmatched:
                shape.fill()
            case .faceUpAndUnmatched:
                shape.fill(.white )
                shape.strokeBorder(lineWidth: ViewConstants.cardBorderWidth)
                Text(card.content)
                    .font(.largeTitle)
            case .faceUpAndMatched:
                shape.fill(.white )
                shape.strokeBorder(lineWidth: ViewConstants.cardBorderWidth)
                Text(card.content)
                    .font(.largeTitle)
                shape.opacity(ViewConstants.upAndMatchedOpacity)
            }
        }
    }
} // end CardView struct
