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
        GeometryReader { geometry in
            ZStack {
                let shape = RoundedRectangle(cornerRadius: radius)
                switch card.state() {
                case .faceDownAndMatched:
                    shape.opacity(ViewConstants.downAndMatchedOpacity)
                case .faceDownAndUnmatched:
                    shape.fill()
                case .faceUpAndUnmatched, .faceUpAndMatched:
                    faceUpCard(for: card, inSize: geometry.size)
                }
            }
        }
    }
    
    
    /// Encapsulates the calculation of the emoji text size based on the given size for the CardView
    /// - Parameter size: the size offered to this card
    /// - Returns: a CGFloat that is the text size for this card
    private func textSizeFor(_ size: CGSize) -> CGFloat {
        min(size.width, size.height) * ViewConstants.emojiScale
    }
    
    /// Builds and returns a View for a faceUp card, which may be different, depending on whether the card
    /// is matched or not, varying in opacity, but otherwise showing the emoji content of the card
    /// - Parameters:
    ///   - card: the EmojiMemoryGame.Card that we are displaying in this CardView
    ///   - size: the CGSize offered to this card for its size
    /// - Returns: a View that is a composite of other Views: a RoundedRect and the text showing the emoji
    @ViewBuilder
    private func faceUpCard(for card: EmojiMemoryGame.Card, inSize size: CGSize) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius)
        shape.fill(.white)
        shape.strokeBorder(lineWidth: ViewConstants.cardBorderWidth)
        Text(card.content).font(.system(size: textSizeFor(size)))
        if card.state() == CardState.faceUpAndMatched {
            shape.opacity(ViewConstants.upAndMatchedOpacity)
        } else {
            shape.opacity(ViewConstants.upAndUnmatchedOpacity)
        }
    }
                    
} // end CardView struct
