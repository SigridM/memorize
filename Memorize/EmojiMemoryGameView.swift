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
    static let upAndUnmatchedOpacity = 1.0
    
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
            scrollViewGeometryReader
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
    
    /// A UI element that holds the cards; wrapped in a GeometryReader so the size of the scrollView can be
    /// sent to the View to calculate the ideal card width for each card to fit into the view without requiring
    /// vertical scrolling.
    private var scrollViewGeometryReader: some View {
        GeometryReader { scrollViewGeometryProxy in
            scrollView(withGeometry: scrollViewGeometryProxy)
        }
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
    
    /// Creates and returns a ScrollView. Because the sizes of each CardView inside the ScrollView depend on the ScrollView's size,
    /// we pass in the GeometryProxy that gives us access to the ScrollView's size.
    /// - Parameter scrollViewGeometryProxy: the GeometryProxy that gives us access to the ScrollView's size
    /// - Returns: a ScrollView containing a LazyVGrid which contains all the CardViews
    private func scrollView(withGeometry scrollViewGeometryProxy: GeometryProxy) -> some View {
        ScrollView {
            LazyVGrid(
                columns: [gridItemFor(scrollViewSize: scrollViewGeometryProxy.size)]
            ) {
                ForEach(game.cards) { card in
                    CardView(card: card, radius: game.currentCornerRadius)
                        .aspectRatio(ViewConstants.cardAspectRatio, contentMode: .fit)
                        .onTapGesture {
                            game.choose(card)
                        }
                        .foregroundColor(game.cardColor())
                }
            }
        }
    }

    
    /// Creates and returns a GridItem whose size is based on the size of the ScrollView in which it lives. Since this is called every
    /// time the View is rebuilt, it gets called when cards are added or removed, so the card width and the radius for the corners
    /// of the cards gets updated whenever this is called.
    /// - Parameter size: the CGSize of the ScrollView that holds the GridItem
    /// - Returns: a GridItem sized to the correct size
    private func gridItemFor(scrollViewSize: CGSize) -> GridItem {
        let cardWidth = cardWidthFor(scrollViewSize: scrollViewSize)
        game.currentCornerRadius = cornerRadius(basedOn: cardWidth)
        return GridItem(
            .adaptive(
                minimum: cardWidth,
                maximum: cardWidth
            )
        )
    }
    
    /// Calculates and returns a corner radius appropriate to the size of the cards. This is used instead of a constant corner
    /// radius, because as the cards get smaller, if the corner radius was the same, the cards would start to look more like
    /// ovals than like cards
    /// - Parameter cardWidth: a Double: the width of a single card
    /// - Returns: a Double: the radius of the circle rounding the corner of a CardView
    private func cornerRadius(basedOn cardWidth: Double) -> Double {
        return cardWidth / ViewConstants.cornerRadiusFactor
    }
    
    /// Return the exact width of a card that puts all cards on the table without requiring vertical scrolling.
    ///
    /// We will be looping through the number of cards to see how they fit, but to be smart about it, we won't
    /// start at 1. There is a minium number of columns that should fit according to these forumulae:
    ///
    ///  let a = aspect ratio of the cards
    ///
    ///  let f = the factor by which to apply the card ratio (effectively, the card height)
    ///
    ///  let c = number of columns
    ///
    ///  let r = number of rows
    ///
    ///  let w = view width
    ///
    ///  let h = view height
    ///
    ///  let t = total number of cards
    ///
    ///  There are three unknowns, and three equations. The unknowns are the card height, the number of rows and the number
    ///  of columns. (f, r and c). The card width is also unknown, but can be derived by multiplying the aspect ratio times the
    ///  card height.
    ///
    ///  The three equations are:
    ///
    ///  afc = w  (multiply the aspect ratio by the card height and number of columns to exactly fit within the view width)
    ///
    ///  cr = t (the number of columns times the number of rows - which may be fractional - is the total number of cards)
    ///
    ///  and
    ///
    ///  fr ≤ h (the height of the cards times the number of rows must be less than the view height to prevent scrolling)
    ///
    ///  ** Technically, the equation should read "f ceil(r) ≤ h" but since by definition r ≤ ceil(r), the inequality still
    ///  holds when we solve for r (rearranging to ceil(r) ≤ h/f).**
    ///
    ///  Rearranging and substituting to solve for c, the final equation is:
    ///
    ///  c ≥ √(wt/(ah))
    ///
    ///  and because wt/(ah) will rarely be a perfect square, c will be a fraction. Since c needs to be an integer large enough to
    ///  fit all the cards in a row, not just a fraction of a card, we can take the ceiling of c to start our loop.
    ///
    ///  c = ceil(√(wt/(ah)))
    ///
    ///  But w isn't really the width of the view, practially speaking. Because the GridItem adds the border width to both sides
    ///  of the card, the width is effectively smaller than w by the number of columns times twice the border width. (And the
    ///  height is effectively smaller than h by the number of rows times twice the border width.)
    ///
    ///  Hence, the actual formula is:
    ///
    ///  let b = the border allowance (twice one border)
    ///
    ///  let c = ceil(√(wt/(ah))
    ///
    ///  r = ceil(t/c)
    ///
    ///  c' = ceil(√((w - cb) * t / (a * (h -rb))))
    ///
    ///  And we start our loop at c'.
    ///
    ///  For the last check, the view may be wide enough and short enough, with few enough cards, that we can't
    ///  divide the width by the number of cards to maximize the card width without having the height of the cards extend
    ///  past the  bottom of the view. In that case, we will fall out of the bottom of the loop, and then we just use the
    ///  view height for the card height, and apply the aspect ratio to get the card width.
    /// - Parameter size: the CGSize containing the width and height of the view area
    /// - Returns: a CGFloat that is the exact width that will allow all cards to fit within the view without requiring
    ///   vertical scrolling
    private func cardWidthFor(scrollViewSize: CGSize) -> CGFloat {
        
        if game.currentPairs() == 0 {return 0}
            
        let borderAllowance = ViewConstants.cardBorderWidth * 2
        let viewWidth = scrollViewSize.width
        let viewHeight = scrollViewSize.height
        let totalCards = CGFloat(game.cards.count)
        let columnsWithoutBorders = ceil(sqrt(viewWidth * totalCards /
                                              (ViewConstants.cardAspectRatio * viewHeight)
                                              )
                                         )
        let numRows = ceil(totalCards / columnsWithoutBorders)
        let borderViewWidth = viewWidth - (columnsWithoutBorders * borderAllowance)
        let borderViewHeight = viewHeight - (numRows * borderAllowance)
        
        let columnsWithBorders = ceil(sqrt(borderViewWidth * totalCards /
                                           (ViewConstants.cardAspectRatio * borderViewHeight)
                                           )
                                      )
        
        var debugPrinter = DebuggingContent(
            debugging: ViewConstants.debuggingCardWidth,
            cardCount: game.cards.count,
            cardAspectRatio: ViewConstants.cardAspectRatio,
            screenSize: scrollViewSize,
            numRowsWithoutBorders: numRows,
            numColumnsWithoutBorders: columnsWithoutBorders,
            cardSizeWithoutBorders: CGSize(
                width: viewWidth / columnsWithoutBorders,
                height: viewWidth / columnsWithoutBorders / ViewConstants.cardAspectRatio),
            borderedScreenSize: CGSize(
                width: borderViewWidth,
                height: borderViewHeight),
            numColumnsWithBorders: columnsWithBorders,
            numRowsWithBorders: ceil(totalCards / columnsWithBorders),
            cardSizeWithBoders: CGSize(
                width: borderViewWidth / columnsWithBorders,
                height: borderViewWidth / columnsWithBorders / ViewConstants.cardAspectRatio)
        )
        debugPrinter.printSetupInformation()
        
        var columnNumber = Int(columnsWithBorders)

        while columnNumber <= (game.cards.count ) {
            let floatColumnNumber = CGFloat(columnNumber)
            let actualViewWidth = viewWidth - (borderAllowance * floatColumnNumber)
            let columnWidth = actualViewWidth / floatColumnNumber
            
            // because columnWidth is already taking the borderAllowance into consideration,
            // and rowHeight is based on the columnWidth, don't include borderAllowance again
            let rowHeight = columnWidth / ViewConstants.cardAspectRatio
            let numRows = ceil(totalCards / floatColumnNumber)
            
            debugPrinter.printLoopInformationFor(
                columnNumber: columnNumber,
                numRows: numRows,
                cardWidth: columnWidth,
                cardHeight: rowHeight)

            if (rowHeight * numRows <= viewHeight) { // fits
                debugPrinter.fits()
                // I have to admit that I don't quite understand why I have to subtract
                // borderAllowance again here, since columnWidth was based on a reduced
                // viewWidth, and (columnWidth + borderAllowance) * floatColumnNumber is equal
                // to the viewWidth, but it doesn't work without it, and I've already spent too
                // much time on it!!
                // And... it seems like I don't have to subtract the borderAllowance, just
                // half of that: the cardBorderWidth. Go figure.
                let answer = columnWidth - ViewConstants.cardBorderWidth
                return answer
            }
            columnNumber += 1
            debugPrinter.tooTall()
        }
        // fell out of bottom of the loop without returning a width...
        debugPrinter.constrainByHeight()
        let answer = borderViewHeight * ViewConstants.cardAspectRatio
        return answer
    }
    
    // MARK: - Nested Structs
    
    /// For debugging the calculation of the corner radius, stores and prints to the console -- in a formatted way -- information about
    /// all the factors going into calculating the size of the cards.
    private struct DebuggingContent {
        /// The total border size that a border adds to a card: twice the width of the border
        let borderAllowance = ViewConstants.cardBorderWidth * 2
        /// When printing inside the loop, how far to make one indent.
        let indentCount = 3
        
        /// A Boolean: whether or not to print, based on whether we are currently debugging
        var debugging = false
        
        /// The total number of cards
        var cardCount = 0
        /// The relative width of a card to its height
        var cardAspectRatio = 1.0
        
        /// The dimensions of the scroll area
        var screenSize = CGSize(width: 0.0, height: 0.0)
        /// How many rows would fit if there were no borders on the cards
        var numRowsWithoutBorders = 0.0
        /// How many columns would fit if there were no borders on the cards
        var numColumnsWithoutBorders = 0.0
        /// What the size of the cards would be if there were no borders
        var cardSizeWithoutBorders = CGSize(width: 0.0, height: 0.0)
        
        /// What the size of the screen would be if we subtracted the borderAllowance for all the columns and rows
        var borderedScreenSize = CGSize(width: 0.0, height: 0.0)
        /// How many columns will fit, given that there are card borders
        var numColumnsWithBorders = 0.0
        /// How many rows will fit, given that there are card borders
        var numRowsWithBorders = 0.0
        /// What the card size should be, given that there are card borders
        var cardSizeWithBoders = CGSize(width: 0.0, height: 0.0)
        
        /// How many leading spaces to print for this iteration through the loop; nesting gets deeper the more times through the loop.
        var leadingSpaces = ""
        
        /// Prints to the console the initial information regarding the inputs to the card size, and the initial card size
        /// calculations
        func printSetupInformation() {
            
            if !debugging {return}
            print(" ")
            print("Screen size: \(screenSize.width) x \(screenSize.height)")
            print("Total cards: \(cardCount)")
            print("Num rows without borders: \(numRowsWithoutBorders)")

            print("Num columns: \(numColumnsWithoutBorders) became: \(numColumnsWithBorders)")
            let cardWidth = cardSizeWithoutBorders.width
            let cardHeight = cardSizeWithoutBorders.height
            print("Card Size without borders: \(cardWidth) x \(cardHeight)")
            print("...forcing screen size to be " +
                  "\((cardWidth + borderAllowance) * numColumnsWithoutBorders) x " +
                  "\((cardHeight + borderAllowance) * numRowsWithoutBorders)")

            print("Bordered screen size: \(borderedScreenSize.width) x " +
                  "\(borderedScreenSize.height)")
            
            let newCardWidth = borderedScreenSize.width / numColumnsWithBorders
            let newCardHeight = newCardWidth / cardAspectRatio
            let newNumRows = ceil(Double(cardCount) / numColumnsWithBorders)
            print("Allows card size to be: \(newCardWidth) x \(newCardHeight)")
            print("...and screen size to be \((newCardWidth + borderAllowance) * numColumnsWithBorders) x " +
                  "\((newCardHeight + borderAllowance) * newNumRows)")
        }
        
        /// Inside the loop that refines the card size, prints out the recalculations of the size of both the cards and the grid
        /// - Parameters:
        ///   - columnNumber: an Int: the number of columns for the given card width
        ///   - numRows: a Double (since we haven't yet taken the ceiling of this number) for the number of rows at this card size
        ///   - cardWidth: a Double of the currently calculated card width
        ///   - cardHeight: a Double of the currently calculated card height
        mutating func printLoopInformationFor(columnNumber: Int,
                                     numRows: Double,
                                     cardWidth: Double,
                                     cardHeight: Double) {
            
            if !debugging {return}

            let spaceCount = (columnNumber - Int(numColumnsWithBorders) + 1 ) * indentCount
            leadingSpaces = String(repeating: " ", count: spaceCount)
            let floatColumnNumber = Double(columnNumber)
            let floatCardCount = Double(cardCount)
            let floatNumRows = floatCardCount / floatColumnNumber
                            
            print(leadingSpaces + "New numRows as float = \(floatNumRows) ceiling = \(numRows)")
            print(leadingSpaces + "columnNumber: \(floatColumnNumber)")
            print(leadingSpaces + "Card Size: \(cardWidth) x \(cardHeight)")
            print(leadingSpaces + "Screen size can be: " +
                  "\((cardWidth + borderAllowance) * floatColumnNumber) x " +
                  "\((cardHeight ) * numRows)")
        }
        
        /// The card size fits within the screen dimensions; print as much to the console.
        func fits() {
            if !debugging {return}
            print(leadingSpaces + "FITS!")
        }
        
        /// The card size is too tall to fit all the cards without vertical scrolling; print as much to the console
        func tooTall() {
            if !debugging {return}
            print(leadingSpaces + "Too tall")

        }
        
        /// There are too few cards, and the screen is too short, to constrain by width, so we are constraining by height
        /// instead; print that plus some other information to the console
        func constrainByHeight() {
            if !debugging {return}
            print("...constrain by height")
            print("...card size: \(borderedScreenSize.height * cardAspectRatio) x " +
                  "\(borderedScreenSize.height)")

        }
    } // end DebuggingContent struct

    
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
