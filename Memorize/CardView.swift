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
    
    @State private var animatedBonusRemaining: Double = 0
    
    /// The model for which this CardView is the View
    let card: EmojiMemoryGame.Card
    
    /// The radius of the circle that defines the rounded corner of the card; can be changed when the card changes size
    var radius: Double
    
    /// A ZStack that consists of a rounded rectangle and some text, typically a single-character emoji. It will be displayed
    /// differently depending on the state of the card (whether face up or face down, matched or unmatched).
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Group {
                    if card.isConsumingBonusTime {
                        Pie(
                            startAngle: Angle(degrees: ViewConstants.startAngle + ViewConstants.angleCorrection),
                            endAngle: Angle(degrees: (1 - animatedBonusRemaining) * 360 + ViewConstants.angleCorrection)
                        )
                        .onAppear {
                            animatedBonusRemaining = card.bonusRemaining
                            withAnimation(.linear(duration: card.bonusTimeRemaining)) {
                                animatedBonusRemaining = 0
                            }
                        }
                    }
                    else {
                        Pie(
                            startAngle: Angle(degrees: ViewConstants.startAngle + ViewConstants.angleCorrection),
                            endAngle: Angle(degrees: (1 - card.bonusRemaining) * 360 + ViewConstants.angleCorrection)
                        )
                    }
                }
                .padding(ViewConstants.piePadding)
                .opacity(ViewConstants.pieOpacity)
                Text(card.content)
                    .rotationEffect(Angle.degrees((card.state() == .faceUpAndMatched) ? 360 : 0))
                    .animation(Animation.linear(duration:1).repeatCount(3, autoreverses: false), value: card.state() == .faceUpAndMatched)
                    .font(Font.system(size: ViewConstants.emojiSize))
                    .scaleEffect(textScaleFor(geometry.size))
            }
            .cardify(isFaceUp: card.isFaceUp, radius: radius)
        }
    }
    
    
    /// Encapsulates the calculation of the emoji text size based on the given size for the CardView
    /// - Parameter size: the size offered to this card
    /// - Returns: a CGFloat that is the text size for this card
    private func textScaleFor(_ size: CGSize) -> CGFloat {
        min(size.width, size.height) / (ViewConstants.emojiSize / ViewConstants.emojiScale)
    }
    
    /// Builds and returns a View for a faceUp card, which may be different, depending on whether the card
    /// is matched or not, varying in opacity, but otherwise showing the emoji content of the card
    /// - Parameters:
    ///   - card: the EmojiMemoryGame.Card that we are displaying in this CardView
    ///   - size: the CGSize offered to this card for its size
    /// - Returns: a View that is a composite of other Views: a RoundedRect and the text showing the emoji
    @ViewBuilder
    private func cardContent(for card: EmojiMemoryGame.Card, inSize size: CGSize) -> some View {

    }
                    
} // end CardView struct
