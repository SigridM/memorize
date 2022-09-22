//
//  EmojiMemoryGameView.swift
//  Memorize
//
//  Created by Sigrid Mortensen on 8/12/22.
//  Copyright © 2022 Sigrid E. Mortensen. All rights reserved
//

import SwiftUI
import AVFoundation

/// Encapsulates all of the constants used in the view into one struct
struct ViewConstants {
    
    /// How wide the width of the border around each card should be
    static let cardBorderWidth = 3.0
    
    /// The shape of the cards, width relative to height
    static let cardAspectRatio = 2.0/3.0
        
    /// The value of the opacity of a card when it has been turned down and is matched; 0 == fully transparent; 1 == fully opaque;
    /// when cards are matched, make them transparent so they disappear from view
    static let downAndMatchedOpacity = 0.0
    
    /// The value of the opacity of a card when it has been turned up and is unmatched; 0 == fully transparent; 1 == fully opaque;
    /// when cards are up and unmatched, make them fully opaque.
    static let upAndUnmatchedOpacity = 0.0
    
    /// The value of the opacity of a card when it is turned up but was just matched; dim it distinguish between it and an unmatched
    /// card
    static let upAndMatchedOpacity = 0.1
    
    /// A Boolean, true if we are currently printing a lot of diagnostics about the card width calculations to the console
    static let debuggingCardWidth = false
    
    /// The String that is the common part of the alert message
    static let alertMessageBase = "Game is not over. Are you sure you want "
    /// The String message to show if we need to pop up an alert dialog on reset
    static let resetAlertMessage = alertMessageBase + "to reset?"
    /// The String message to show if we need to pop up an alert dialog on new game
    static let newGameAlertMessage = alertMessageBase + "a new game?"
    /// The String message to show if we need to pop up an alert dialog when decreasing the cards
    static let removeCardsAlertMessage = alertMessageBase + "a new game with fewer cards?"
    /// The String message to show if we need to pop up an alert dialog when decreasing the cards
    static let addCardsAlertMessage = alertMessageBase + "a new game with more cards?"
    
    /// The following four images are the system images for the given buttons
    static let addImage = Image(systemName: "plus.circle")
    static let removeImage = Image(systemName: "minus.circle")
    static let resetImage = Image(systemName: "arrow.uturn.forward.circle")
    static let newGameImage = Image(systemName: "play.square")
    
    /// A Double, the denominator for the fraction of the width of a single card that should serve as the radius
    /// of the circle creating the rounded corner of a card
    static let cornerRadiusFactor = 4.0
    
    /// A Double that relates the size of the text emoji to the size of a card
    static let emojiScale = 0.8
} // end ViewConstants

/// A View composing the entire UI of the App
struct EmojiMemoryGameView: View {
    
    // MARK: - States and ObservedObjects
    /// The EmojiMemoryGame viewModel that is managing the game model for this view; observed so we can update
    /// the view when it changes
    @ObservedObject var game: EmojiMemoryGame
    
    /// A Boolean State, true if, when the user clicks on a  the reset button, we need to show an alert
    @State private var needsResetAlert: Bool = false
    /// A Boolean State, true if, when the user clicks on a  the new game button, we need to show an alert
    @State private var needsNewGameAlert: Bool = false
    /// A Boolean State, true if, when the user clicks on a  the remove cards button, we need to show an alert
    @State private var needsCardRemovingAlert: Bool = false
    /// A Boolean State, true if, when the user clicks on a  the add cards button, we need to show an alert
    @State private var needsCardAddingAlert: Bool = false
    
    // MARK: - body
    /// A View of the entire layout of the UI, including the title, the theme, the score, all of the cards (sized so they fit
    /// without requiring scrolling, if possible, and buttons for reseting the game with the current theme, choosing randomly
    /// among a number of themes, and another set of buttons for adding and removing cards.
    var body: some View {
        
        VStack {
            Text("Memorize!")
            themeNameDisplay
            scoreDisplay
            aspectVGrid
            Spacer()
            HStack {
                resetGameInitiator
                Spacer()
                newGameInitiator
            }
            Spacer()
            HStack {
                cardRemover
                Spacer()
                cardAdder
            }
            .padding(.horizontal)
            .font(.largeTitle)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Private computed properties; top-level elements of the display
    
    /// A UI element for displaying the name of the current theme
    private var themeNameDisplay: some View {
        Text(game.themeName())
            .foregroundColor(game.cardColor())
    }
    
    /// A UI element for displaying the current score in the game
    private var scoreDisplay: some View {
        let score = game.score()
        let possibleScore = game.bestPossibleScore()
        let percent = (Double(score)/Double(possibleScore)*100).rounded()
        var punctuation: String = ""
        if score > 0 && score == possibleScore {
            punctuation = "!"
        }
        return Text("Score: \(score) out of a possible \(possibleScore) - \(percent) percent"
                    + punctuation)
            .foregroundColor(game.cardColor())
    }

    private var aspectVGrid: some View {
        AspectVGrid(items: game.cards,
                    aspectRatio: ViewConstants.cardAspectRatio,
                    content: { card, width in
            CardView(card: card, radius: cornerRadius(basedOn: width))
                .onTapGesture {
                    game.choose(card)
                }
                .foregroundColor(game.cardColor())
        })
    }
    
    /// A UI element that, when selected, initiates a new game with a random theme;
    /// Pops up an alert to confirm that we want a new game if the current game is underway and not complete
    private var newGameInitiator: some View {
        let features = GameChangingFeature(
            image: ViewConstants.newGameImage,
            buttonText: "New Game",
            needsAlert: _needsNewGameAlert,
            continueAction: game.newRandomGame,
            alertMessage: ViewConstants.newGameAlertMessage,
            game: game
        )
        return features.gameChanger()
    }
    
    /// A UI element that, when selected, initiates a new game with the same theme as the current
    /// game. Pops up an alert to confirm that we want a new game if the current game is underway and not complete
    private var resetGameInitiator: some View {
        let features = GameChangingFeature(
            image: ViewConstants.resetImage,
            buttonText: "Reset",
            needsAlert: _needsResetAlert,
            continueAction: game.reset,
            alertMessage: ViewConstants.resetAlertMessage,
            game: game
        )
        return features.gameChanger()
    }

    /// A UI element for removing a pair of cards
    private var cardRemover: some View {
        let features = GameChangingFeature(
            image: ViewConstants.removeImage,
            buttonText: nil,
            needsAlert: _needsCardRemovingAlert,
            continueAction: game.decreaseCards,
            alertMessage: ViewConstants.removeCardsAlertMessage,
            game: game
        )
        return features.gameChanger()
    }
    
    /// A UI element for adding a pair of cards
    private var cardAdder: some View {
        let features = GameChangingFeature(
            image: ViewConstants.addImage,
            buttonText: nil,
            needsAlert: _needsCardAddingAlert,
            continueAction: game.increaseCards,
            alertMessage: ViewConstants.addCardsAlertMessage,
            game: game
        )
        return features.gameChanger()
    }
    
    // MARK: - Private instance methods
    
    /// Calculates and returns a corner radius appropriate to the size of the cards. This is used instead of a constant corner
    /// radius, because as the cards get smaller, if the corner radius was the same, the cards would start to look more like
    /// ovals than like cards
    /// - Parameter cardWidth: a Double: the width of a single card
    /// - Returns: a Double: the radius of the circle rounding the corner of a CardView
    private func cornerRadius(basedOn cardWidth: Double) -> Double {
        return cardWidth / ViewConstants.cornerRadiusFactor
    }
    
    // MARK: - Nested Structs

    /// A structure for storing information about a given button on the view that includes an image and possibly a bit of text,
    /// and when tapped, may initiate an alert before changing in some way a current game already underway such that progress
    /// would be lost.
    /// With that information stored, this struct can produce a View that shows that information and responds appropriately when
    /// tapped, with the correctly worded alert, if needed, and the correct action if the alert is not needed or is dismissed.
    private struct GameChangingFeature {
        
        /// the image to show in the view
        let image: Image
        
        /// the text to show in the view, if any
        let buttonText: String?
        
        /// a Boolean State which can be unwrapped to find out whether an alert is needed, or its projectedValue Binding can be
        /// used to trigger that alert
        let needsAlert: State<Bool>
        
        /// the function that takes no arguments and returns nothing but is called either if no alert is needed, or if the user
        /// dismisses the alert by indicating that they want to go ahead anyway.
        let continueAction: ()->()
        
        /// The text of the alert message, if one is needed
        let alertMessage: String
        
        /// The game that is being played and who can determine whether we need an alert
        let game: EmojiMemoryGame

        /// Creates and returns a View that will change the current game according to all of the specified features. In a non-alert
        /// situation, it will call its continueAction when tapped. If an alert is needed, it will put up the alert with the appropriate text,
        /// and respond appropriately to that alert.
        /// - Returns: either a VStack or an Image, depending on whether there is button text, along with the embellishments
        /// of tap gesture response, and an alert, if and when appropriate
        func gameChanger() -> some View {
            baseView()
                .onTapGesture {
                    needsAlert.wrappedValue = game.isBegun() && !game.isOver()
                    if !needsAlert.wrappedValue {
                        continueAction()
                    }
                }
                .alert(
                    alertMessage,
                    isPresented: needsAlert.projectedValue,
                    actions: {alertActionsFor(continueAction)}
                )
                .foregroundColor(.blue)
                .padding(.horizontal)
        }
        
        /// Creates and returns either a combination of image and text (if there is buttonText) or just an image (if there is no
        /// buttonText) which will be further embellished with tapGesture and alert actions
        /// - Returns: either a VStack or an Image, depending on whether there is button text.
        private func baseView() -> some View {
            if let buttonText = buttonText {
                return AnyView(VStack {
                    image
                    Text(buttonText)
                        .font(.caption)
                })
            } else {
                return AnyView(image)
            }
        }
        
        /// Builds a View that will be used for the Yes and No buttons in the alert, should one be needed on this feature.
        /// - Parameter yesAction: an escaping closure that takes no arguments and returns no value and will be called
        /// if the user indicates that, yes, they want to go ahead anyway, despite the alert.
        /// - Returns: a View built from the component Yes and No buttons by the ViewBuilder
        @ViewBuilder private func alertActionsFor(_ yesAction: @escaping ()-> Void) -> some View {
            Button(role: .destructive) {
                yesAction()
            } label: {
                Text("Yes")
            }
            Button(role: .cancel) { }// do nothing
            label: {
                Text("No")
            }
        }
    } // end GameChangingFeature struct
} // end EmojiMemoryGameView





/// Allows previews to be shown in the development environment in various color schemes and orientations
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let game = EmojiMemoryGame()
        
        EmojiMemoryGameView(game: game)
            .preferredColorScheme(.dark)
            .previewInterfaceOrientation(.landscapeLeft)
        EmojiMemoryGameView(game: game)
            .preferredColorScheme(.light)
            .previewInterfaceOrientation(.portrait)
    }
}
