//
//  ContentView.swift
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
        
    /// The value of the opacity of a card when it has been turned down and is matched; 0 == fully transparent; 1 == fully opaque; when cards are matched, make them transparent so they disappear from view
    static let downAndMatchedOpacity = 0.0
    
    /// The value of the opacity of a card when it is still turned down but was just matched; dim it to show this
    static let upAndMatchedOpacity = 0.1
    
    /// A Boolean, true if we are currently printing a lot of diagnostics about the card width calculations to the console
    static let debuggingCardWidth = false
    
    /// The String message to show if we pop up an alert dialog
    static let alertMessage = "Game is not over. Are you sure?"
    
    static let addImage = Image(systemName: "plus.circle")
    
    static let removeImage = Image(systemName: "minus.circle")
    
    static let resetImage = Image(systemName: "arrow.uturn.forward.circle")

    static let newGameImage = Image(systemName: "play.square")

}

/// A View composing the entire UI of the App
struct ContentView: View {
    
    // MARK: - States and ObservedObjects
    /// The EmojiMemoryGame viewModel that is managing the game model for this view; observed so we can update
    /// the view when it changes
    @ObservedObject var game: EmojiMemoryGame
    
    /// A Boolean State, true if when a user clicks on a button, we need to show an alert
    @State var needsAlert: Bool = false

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
        var punctuation: String
        if score > 0 && score == possibleScore {
            punctuation = "!"
        } else {
            punctuation = ""
        }
        return Text("Score: \(score) out of a possible \(possibleScore) - \(percent) percent" + punctuation)
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
    
    /// Creates and returns a UI element that, when selected, initiates a new game with a random theme;
    /// Pops up an alert to confirm that we want a new game if the current game is underway and not complete
    private var newGameInitiator: some View {
        return VStack {
            ViewConstants.newGameImage
            Text("New Game")
                .font(.caption)
        }
        .onTapGesture {
            needsAlert = game.isBegun() && !game.isOver()
            if !needsAlert {
                game.newRandomGame()
            }
        }
        .alert(
            ViewConstants.alertMessage,
            isPresented: $needsAlert)
            {
                Button(role: .destructive) {
                    game.newRandomGame()
                } label: {
                    Text("Yes")
                }
                Button(role: .cancel) { }// do nothing
                label: {
                    Text("No")
                }
            }
          .foregroundColor(.blue)
          .padding(.horizontal)
    }
    
    /// Creates and returns a UI element that, when selected, initiates a new game with the same theme as the current
    /// game. Pops up an alert to confirm that we want a new game if the current game is underway and not complete
    /// - Returns: the UI element for initiating a new game
    private var resetGameInitiator: some View {
        return VStack {
            ViewConstants.resetImage
            Text("Reset")
                .font(.caption)
        }
        .onTapGesture {
            needsAlert = game.isBegun() && !game.isOver()
            if !needsAlert {
                game.reset()
            }
        }
//        .alert(<#T##titleKey: LocalizedStringKey##LocalizedStringKey#>, isPresented: <#T##Binding<Bool>#>, actions: <#T##() -> View#>)
        .alert(
            ViewConstants.alertMessage,
            isPresented: $needsAlert,
            actions: buttonActionsFor(game.reset())
            )
//            {
//                Button(role: .destructive) {
//                    game.reset()
//                } label: {
//                    Text("Yes")
//                }
//                Button(role: .cancel) { }// do nothing
//                label: {
//                    Text("No")
//                }
//            }
          .foregroundColor(.blue)
          .padding(.horizontal)
    }
    
    /// A UI element for removing a card
    private var cardRemover: some View {
        Button {game.decreaseCards()} label: {ViewConstants.removeImage}
    }
    
    /// A UI element for adding a card
    private var cardAdder: some View {
        Button{game.increaseCards()} label: {ViewConstants.addImage}
    }

    private func buttonActionsFor(_ action: ()->Void) -> @ViewBuilder () -> Button<Text> {
        {
            Button(role: .destructive) {
                action()
            } label: {
                Text("Yes")
            }
            Button(role: .cancel) { }// do nothing
            label: {
                Text("No")
            }
        }
        
    }

    private func scrollView(withGeometry scrollViewGeometryProxy: GeometryProxy) -> some View {
        ScrollView {
            LazyVGrid(columns: [
                gridItemFor(size: scrollViewGeometryProxy.size)
            ]) {
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

    
    private func gridItemFor(size: CGSize) -> GridItem {
        let cardWidth = cardWidthFor(scrollViewSize: size)
        game.currentCornerRadius = cornerRadius(basedOn: cardWidth)
        return GridItem(.adaptive(
            minimum: cardWidth,
            maximum: cardWidth)
        )
    }



    func recalculateCurrentCornerRadius(_ scrollViewSize: CGSize) {
        let cardWidth = Double(cardWidthFor(scrollViewSize: scrollViewSize))
        game.currentCornerRadius = cornerRadius(basedOn: cardWidth)
        print("Recalculating corner radius to: \(game.currentCornerRadius)")
    }
    
    func cornerRadius(basedOn cardWidth: Double) -> Double {
        return cardWidth / 4.0
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
    func cardWidthFor(scrollViewSize: CGSize) -> CGFloat {
        
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
//                print (ViewConstants.defaultCornerRadius / currentCardWidth)
//                print("In cardWidthFor loop: \(cornerRadius(basedOn: answer))", terminator: "")
//                print(" Actual: \(game.currentCornerRadius)")
                return answer
            }
            columnNumber += 1
            debugPrinter.tooTall()
        }
        // fell out of bottom of the loop without returning a width...
        debugPrinter.constrainByHeight()
        let answer = borderViewHeight * ViewConstants.cardAspectRatio
//        print("In cardWidthFor fallout: \(cornerRadius(basedOn: answer))", terminator: "")
//        print(" Actual: \(game.currentCornerRadius)")
        return answer
    }
    
    struct DebuggingContent {
        let borderAllowance = ViewConstants.cardBorderWidth * 2

        var debugging = false
        var cardCount = 0
        var cardAspectRatio = 1.0

        var screenSize = CGSize(width: 0.0, height: 0.0)
        var numRowsWithoutBorders = 0.0
        var numColumnsWithoutBorders = 0.0
        var cardSizeWithoutBorders = CGSize(width: 0.0, height: 0.0)
        
        var borderedScreenSize = CGSize(width: 0.0, height: 0.0)
        var numColumnsWithBorders = 0.0
        var numRowsWithBorders = 0.0
        var cardSizeWithBoders = CGSize(width: 0.0, height: 0.0)
        
        let indentCount = 3
        
        var leadingSpaces = ""

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
 
        func fits() {
            if !debugging {return}
            print(leadingSpaces + "FITS!")
        }
        
        func tooTall() {
            if !debugging {return}
            print(leadingSpaces + "Too tall")

        }
        
        func constrainByHeight() {
            if !debugging {return}
            print("...constrain by height")
            print("...card size: \(borderedScreenSize.height * cardAspectRatio) x " +
                  "\(borderedScreenSize.height)")

        }
        
    }




}

/// The view of one single card, which can show an image when face up, and hides that image when face down
struct CardView: View {
    var card: MemoryGame<String>.Card
    var radius: Double
        
    var body: some View {
//        print("In CardView>>body; radius is \(radius)")
        return ZStack {
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let game = EmojiMemoryGame()
        
        ContentView(game: game)
            .preferredColorScheme(.dark)
            .previewInterfaceOrientation(.landscapeLeft)
        ContentView(game: game)
            .preferredColorScheme(.light)
            .previewInterfaceOrientation(.portrait)
    }
}
