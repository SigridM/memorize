//
//  EmojiMemoryGame.swift
//  Memorize
//
//  Created by Sigrid Mortensen on 9/1/22.
//

import SwiftUI
import CoreMedia

/// ViewModel - acts as the gatekeeper between the view and the model
class EmojiMemoryGame: ObservableObject {
    
    // MARK: - Constants
    
    /// A structure encapsulating the Constants for the EmojiMemoryGame
    struct Constants {
        
        /// If no other theme is chosen, default to the first one
        static let defaultThemeIndex = 0
        
        /// Until another corner radius is set based on the size of the cards, use this radius
        static let initialCornerRadiius = 20.0
    }
    // MARK: - Class Variables
    
    /// The means by which we keep track of which (Singleton) theme is currently showing in the view
    private static var currentThemeIndex = Constants.defaultThemeIndex
    
    /// The Singleton collection of Themes among which to choose when playing the game
    private static var themes = initializeDefaultThemes()
    
    /// The theme of the game which is currently showing in the View
    private static var currentTheme: Theme {
        return themes[currentThemeIndex]
    }

    // MARK: - Class Methods
    
    /// This way of doing things, with ThemeName as an enum, doesn't satisfy the requirement of
    /// this assigment to allow a Theme to be created in a single line of code, so I'm going to
    /// remove it and replace it with one where the name of the theme is just a string.
    /// Depricated
//    private static func initializeThemes() -> [Theme]{
//       var answer = [Theme]()
//       for eachName in ThemeName.allCases {
//           answer.append(Theme.themeForName(eachName))
//       }
//       return answer
//   }
    
    // MARK: - Class methods for managing Themes (adding, initializing, modifying, and selecting among them)
    
    /// Initializes a collection of default themes from which to build games
    /// - Returns: an Array of Themes
    private static func initializeDefaultThemes() -> [Theme]{
        var answer = [Theme]()
        let defaultNames = ["Sports", "Occupations", "Halloween", "Food", "Travel", "Valentine"]
        for eachName in defaultNames {
            answer.append(Theme.themeFor(name: eachName))
        }
        return answer
   }
    
    /// Adds one more Theme to the collection of Themes
    /// - Parameter theme: the Theme to add
    private static func add(theme: Theme) {
        themes.append(theme)
    }
    
    /// Answers a theme chosen at random among the collection of themes
    /// - Returns: a Theme chosen at random
    private static func randomTheme() -> Theme {
        return themes[randomThemeIndex()]
    }
    
    /// Answers a random index into the array of themes
    /// - Returns: an Int which is a random index into the array of themes
    private static func randomThemeIndex() -> Int {
        return Int.random(in: (0..<themes.count))
    }

    /// Cretes and adds a new Theme to the collection of Themes, provided that a theme of that name is not already
    /// in the collection; otherwise does nothing.
    /// - Parameters:
    ///   - themeName: a String that uniquely identifies the Theme
    ///   - themeEmojis: an Array of one-character Strings to show in the cards for this theme, typically emojis
    ///   - color: a String describing the color for the text and backs of cards for this Theme
    static func addTheme(named themeName: String, withEmojis themeEmojis: [String], color: String) {
        if themes.anySatisfy({$0.name == themeName}) {
            return // a theme of that name already exists
        }
        add(theme: Theme(emojis: themeEmojis, name: themeName, color: color))
    }

    /// Increases by one the number of pairs of cards showing in the current theme, as long as the number does not
    /// exceed the maximum number of emojis in the theme
    /// - Returns: a Boolean, true if increasing the pairs was possible
    static func increaseCurrentThemePairs() -> Bool {
        return themes[currentThemeIndex].increaseEmojis()
    }

    /// Decreases by one the number of pairs of cards showing in the current theme, as long as the number does not
    /// drop below the minimum number of emojis in the theme
    /// - Returns: a Boolean, true if decreasing the pairs was possible
    static func decreaseCurrentThemePairs() -> Bool {
        return themes[currentThemeIndex].decreaseEmojis()
    }
    
    // MARK: - Class methods for creating Memory Game models
    /// Creates and answers a new MemoryGame by randomly selecting among the available Themes.
    /// - Returns: a MemoryGame with CardContents of type String (the emojis in the Theme)
    static func randomMemoryGame() -> MemoryGame<String> {
        self.createMemoryGame(for: self.randomTheme())

    }
    /// Creates and answers a MemoryGame for a particular theme, if it exists in our collection of Themes; otherwise, it
    /// creates and answers a MemoryGame for the current theme.
    /// - Parameter theme: the Theme (name, color, and collection of emojis) that represent this game
    /// - Returns: a MemoryGame with CardContents of type String (the emojis in the Theme)
    static func createMemoryGame(for theme: Theme) -> MemoryGame<String> {
        if let themeIndex = themes.firstIndex(where: {$0 == theme}) {
            currentThemeIndex = themeIndex
        }
        return createMemoryGame(at: currentThemeIndex)
    }
    
    /// Finds the theme in our collection of Themes that resides at the given index, and creates a new MemoryGame
    /// repreesnting that theme.
    /// - Parameter index: an Integer index into the Array of Themes
    /// - Returns: a MemoryGame with CardContents of type String (the emojis in the Theme at the index)
    private static func createMemoryGame(at index: Int) -> MemoryGame<String> {
        currentThemeIndex = index
        let shuffledEmojis = themes[currentThemeIndex].emojis.shuffled()
        return MemoryGame<String>(numberOfPairsOfCards: currentTheme.numEmojisToShow) { pairIndex in
            shuffledEmojis[pairIndex]
        }
    }

    // MARK: - Instance variables
    
    /// The domain model representing and managing the logic of the game. The MemoryGame is responsible for reacting
    /// when a card is chosen and/or matched, and maintaining the score.
    /// We use the @Published propertyWrapper to inform the View to update when anything in the MemoryGame changes.
    @Published private var model: MemoryGame<String> = randomMemoryGame()
    
    /// To make the cards look card-like, the rounding of the corners should be proportional to the size of the cards; when
    /// cards are added or removed, or the theme changes (showing potentially more or fewer cards), this value will change.
    /// Defaults to the initialCornerRadius in our Constants
    var currentCornerRadius = Constants.initialCornerRadiius
    
    /// The collection of Cards held and managed by the MemoryGame model. Exposed here so they can be displayed in the View.
    var cards: Array<MemoryGame<String>.Card> {
        return model.cards
    }
    
    // MARK: - Instance methods, Queries
    
    /// Answers how many pairs of cards are currently held in the model
    /// - Returns: an Int for the number of pairs of cards to be displayed
    func currentPairs() -> Int {
        model.numberOfPairsOfCards()
    }
    
    /// Turns the color represented by a String in the current Theme into a SwiftUI Color useable by the View
    /// - Returns: a Color matching, as closely as possible, the name of the color in the current theme
    func cardColor() -> Color {
        switch EmojiMemoryGame.currentTheme.color {
        case "Green": return .green
        case "Orange" : return .orange
        case "Yellow" : return .yellow
        case "Mint": return .mint
        case "Brown": return .brown
        case "Pink": return .red.opacity(0.65)
        case "Red": return .red
        default : return .gray
        }
    }
    
    /// Answers a String representing the name of the currently showing Theme
    /// - Returns: a String, the name of the currently showing Theme
    func themeName() -> String {
        return EmojiMemoryGame.currentTheme.name
    }
    
    /// Answers a Boolean telling whether the game is finished; i.e., all of the cards are matched
    /// - Returns: a Boolean, true if all the cards are matched
    func isOver() -> Bool {
        return model.allMatched()
    }
    
    /// Answers a Boolean, true if no cards are matched or face up, or if any cards have been mismatched in previous moves
    /// - Returns: a Boolean indicating whether the user has begun playing the game
    func isBegun() -> Bool {
        return model.anyFaceUp() || model.anyMatched() || model.anySeen()
    }
    
    /// Answers the current score of the game, maintained by the MemoryGame model
    /// - Returns: an Integer for the current score of the game
    func score() -> Int {
        return model.score
    }
    
    /// Answers what the best score for this game would be if the user matched all the cards correctly, without any mistakes.
    /// - Returns: an Integer of the best score for the game, given the number of cards and the points awarded for each match
    func bestPossibleScore() -> Int {
        return model.bestPossibleScore()
    }
    
    // MARK: - Instance methods, Intent(s)
    
    /// Initiates the logic for one play of the game, when a user chooses a card
    /// - Parameter card: one of the Cards currently showing in the game
    func choose(_ card: MemoryGame<String>.Card) {
        model.choose(card)
    }
    
    /// Creates a new game with the same theme as the current theme
    func reset() {
        self.changeTo(themeNumbered: EmojiMemoryGame.currentThemeIndex)
    }
    
    /// Creates a new game with a random theme
    func newRandomGame() {
        self.changeTo(themeNumbered: EmojiMemoryGame.randomThemeIndex())
    }
    
    /// Increases by two cards (one pair), the number of cards in the current theme, if possible, and if so, also initiates a new game.
    /// Optimized to not change the game if we are already at the maximum number of cards
    func increaseCards() {
        if EmojiMemoryGame.increaseCurrentThemePairs() {
            model = EmojiMemoryGame.createMemoryGame(at: EmojiMemoryGame.currentThemeIndex)
        }
    }
    
    /// Decreases by two cards (one pair), the number of cards in the current theme, if possible, and if so, also intiates a new game.
    /// Optimized to not change the game if we are already at the minimum number of cards
    func decreaseCards() {
        if EmojiMemoryGame.decreaseCurrentThemePairs() {
            model = EmojiMemoryGame.createMemoryGame(at: EmojiMemoryGame.currentThemeIndex)
        }
    }

    // MARK: - Private Instance methods
    
    /// Private - get a new model representing the theme stored at the parameter index into the themes array
    /// - Parameter index: an Int that is the index into the themes array
    private func changeTo(themeNumbered index: Int) {
        model = EmojiMemoryGame.createMemoryGame(at: index)
    }
    

}

/// *Depricated
/// The characteristics of a given theme, including its name, an image that represents the entire theme,
/// and the emojis contained in that theme. This was once in the ViewModel because it contained SwiftUI-specific
/// references, like Color and Image; now in the model.
//struct Theme {
//    let emojis: [String]
//    let name: ThemeName
//    let image: Image
//    let color: Color
//
//    init(emojis: [String], name: ThemeName, image: Image, color: Color) {
//        self.emojis = emojis
//        self.name = name
//        self.image = image
//        self.color = color
//    }
//    /// Factory method to create and return a Theme for a given ThemeName
//    /// - Parameter themeName: the ThemeName enum on which to base the theme
//    /// - Returns: a Theme with its emojis, name, and image bundled together
//    static func themeForName(_ themeName: ThemeName) -> Theme {
//        let travelEmojis = ["🚗", "🚲", "🚤", "🚎", "🚌", "🚜", "🚓", "🚑", "🚛", "🛴", "🦼",
//                            "🚠", "✈️", "🚀", "🚁", "🛶", "🛸", "🛫", "🚒", "🛵", "🚃", "🚄",
//                            "🚂", "⛵️", "🛷", "🦽", "🎢", "🎠"]
//        let valentineEmojis = ["🥰", "😍", "😘", "💋", "🍫", "🥂", "🎡", "💒", "❤️", "💖",
//                               "💕", "💞", "💓", "💘"]
//        let sportsEmojis = ["⚽️", "🏀", "🏈", "⚾️", "🥎", "🎾", "🏐", "🥏", "🏓", "🏸", "🏑",
//                            "🏏", "⛳️", "⛸", "⛷", "🏊", "🚴"]
//        let halloweenEmojis = ["😈", "🤡", "👻", "💀", "👽", "🤖", "🎃", "🕷", "🍩", "🍫",
//                               "🍎", "🍬"]
//        let foodEmojis = ["🍏", "🍐", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🫐", "🍈", "🍒",
//                          "🍑", "🥭", "🍍", "🥥", "🥝", "🍅", "🍆", "🥑", "🥦", "🥬", "🥒",
//                          "🌶", "🫑", "🌽", "🥕", "🫒", "🧄", "🧅", "🥔", "🍠", "🥐", "🥯",
//                          "🍞", "🥖", "🥨", "🧀", "🥚", "🧈", "🥞", "🧇", "🥓", "🥩", "🍗",
//                          "🍖", "🌭", "🍔", "🍟", "🍕", "🥪", "🥙", "🌮"]
//        let occupationEmojis = ["👮🏼‍♀️", "👩🏾‍⚕️", "👩🏼‍🌾", "👩🏻‍🏫", "👩🏼‍💻", "👩🏼‍🔬", "👩🏽‍🎨", "👩🏼‍🚒", "👩🏻‍🚀", "👩🏼‍⚖️",
//                                "👩🏽‍🍼", "💇🏽‍♂️", "🤺", "⛷", "🚴🏼‍♀️", "🤹🏾‍♀️", "🏌🏾‍♀️"]
//
//
//        switch themeName {
//        case .travel:
//            return Theme(emojis: travelEmojis,
//                         name: themeName,
//                         image: Image(systemName: "car"),
//                         color: .green)
//        case .valentine:
//            return Theme(emojis: valentineEmojis,
//                         name: themeName,
//                         image: Image(systemName: "heart"),
//                         color: .pink.opacity(0.65))
//        case .sports:
//            return Theme(emojis: sportsEmojis,
//                         name: themeName,
//                         image: Image(systemName: "sportscourt"),
//                         color: .red)
//        case .halloween:
//            return Theme(emojis: halloweenEmojis,
//                         name: themeName,
//                         image: Image(systemName: "moon"),
//                         color: .orange)
//        case .food:
//            return Theme(emojis: foodEmojis,
//                         name: themeName,
//                         image: Image(systemName: "fork.knife"),
//                         color: .mint)
//        case .occupations:
//            return Theme(emojis: occupationEmojis,
//                         name: themeName,
//                         image: Image(systemName: "figure.walk"),
//                         color: .brown)
//        }
//    }
//
//    func maxEmojis() -> Int {
//        return emojis.count
//    }
//}
