//
//  MemoryGame.swift
//  Memorize
//
//  Created by Sigrid Mortensen on 9/1/22.
//

import Foundation

/// Defines a MemoryGame with any card content as long as it can be determined whether two cards are equal.
struct MemoryGame<CardContent> where CardContent: Equatable {  // Generic over any type; we are calling whatever the type is "CardContent"
    
    // MARK: - Constant declarations
    /// Collect all of the constants for the game in one structure (could also have been an enum). Because MemoryGame is
    /// generic, however, the constants must be computed, not stored ("Static stored properties not supported in generic types")
    /// and therefore must also be vars, not lets.
    struct Constants {
        static var matchIncrement: Int {2}
    }
    
    // MARK: - instance variable declarations
    /// The container that holds the cards
    private(set) var cards: Array<Card> // the cards array can only be set privately by the
                                        // MemoryGame, but can be read by any type in the project
    
    /// The means of deterimining which, if any, card is face up. On any attempt at matching, we can only attempt to match the
    /// new card being chosen with the face up card.
    private var indexOfTheFaceUpCard: Int? {
        set {
            cards.indices.forEach {
                if $0 == newValue {
                    cards[$0].goFaceUp()
                } else {
                    turnFaceDown(at: $0)  // May impact the score
                }
            }
        }
        get {cards.indices.filter({cards[$0].isFaceUp}).oneAndOnly}
    }
    
    /// Maintain the score for the game, readable anywhere in the project, but settable only by the game
    private(set) var score = 0

    // MARK: - instance methods
    /// Build the game's collection of cards, given the number of pairs of cards. Give each card a unique ID as it is added to
    /// the collection.
    /// - Parameters:
    ///   - numberOfPairsOfCards: an Integer for the desired number of pairs
    ///   - createCardContent: a closure that will generate some sort of card content for the given card pair
    init(numberOfPairsOfCards: Int, createCardContent: (Int) -> CardContent) {
        cards = []
        // add numberOfPairsOfCards X 2 cards to cards array
        for pairIndex in 0..<numberOfPairsOfCards {
            let content = createCardContent(pairIndex)
            cards.append(Card(content: content, id: pairIndex*2))
            cards.append(Card(content: content, id: pairIndex*2+1))
        }
        cards.shuffle()
    }
    /// The given card has been chosen in the interface. Check to see if there is already a card face up (chosen on the last pick),
    /// and if so, check to see if it matches this card. If they match, increment the score. Whether or not they match, there should
    /// no longer be a face up card.
    ///
    /// If there is not already a card face up, or if there are two face up cards, make this card the one face up card, but be sure
    /// to turn down any cards previously face up, which may decrement the score if any of those cards didn't match and had
    /// previously been seen (see #turnAllFaceDown()).
    ///
    /// Make sure not to choose a card that is already face up or was previously matched.
    /// - Parameter card: the card that was chosen in the interface
    ///
    // MARK: - Intent(s)
    mutating func choose(_ card: Card) {
        if let chosenIndex = cards.firstIndex(where: {$0.id == card.id}),
            !cards[chosenIndex].isFaceUp,
            !cards[chosenIndex].isMatched
        {
            if let alreadyUpIndex = indexOfTheFaceUpCard { // there is one face up
                if cards[chosenIndex].matches(cards[alreadyUpIndex]) { // and it matches this one
                    cards[chosenIndex].becomeMatched()
                    cards[alreadyUpIndex].becomeMatched()
                    score += Constants.matchIncrement
                }
                cards[chosenIndex].goFaceUp()
            } else {
                indexOfTheFaceUpCard = chosenIndex
            }
        }
    }
    // MARK: - Queries
    /// Answers a Boolean, whether all of the cards are matched (meaning the game is over).
    /// - Returns: Boolean true if all of the cards have been matched, otherwise false
    func allMatched() -> Bool {
        return cards.allSatisfy { $0.isMatched }
    }
    
    /// Answers a Boolean, whether no cards have yet been matched (meaning the game is
    /// still in its infancy).
    /// - Returns: Boolean true if all of the cards remain unmatched.
    func noneMatched() -> Bool {
        return cards.noneSatisfy({$0.isMatched})
    }
    
    /// Answers a Boolean, whether all of the cards are face down, none face up.
    /// - Returns: Boolean true if all of the cards are face down
    func noneFaceUp() -> Bool {
        return cards.noneSatisfy({$0.isFaceUp})
    }
    
    /// Answers a Boolean, whether any of the cards have been previously seen; note that this is only valid
    /// once the cards are turned back down at least once without a match
    /// - Returns: Boolean true if any of the cards have been previously seen and flipped back down
    func anySeen() -> Bool {
        return cards.anySatisfy({$0.previouslySeen})
    }
    
    /// Answers a Boolean, whether two or more of the cards have been matched already
    /// - Returns: Boolean true if any pair has been matched.
    func anyMatched() -> Bool {
        return cards.anySatisfy({$0.isMatched})
    }
    
    /// Answers a Boolean, whether any one of the cards is face up.
    /// - Returns: Boolean true if at least one card is face up
    func anyFaceUp() -> Bool {
        return cards.anySatisfy({$0.isFaceUp})
    }
    
    /// Answers how many pairs of cards are in the game
    /// - Returns: An Integer for the number of pairs of cards, or half the total number of cards
    func numberOfPairsOfCards() -> Int {
        return cards.count / 2
    }
    
    /// Answers what the best score for this game would be if the player matched everything with no mistakes
    /// - Returns: An Integer for the best possible score, given the set up of this game and the number of
    /// pairs of cards.
    func bestPossibleScore() -> Int {
        return Constants.matchIncrement * numberOfPairsOfCards()
    }
    
    // MARK: - Private instance methods
    /// Turn all of the cards face down; optimized to do nothing if all are already face down. As a side effect,
    /// modify the score to penalize the player if any of the cards report that they were previously seen as they go face down.
    private mutating func turnAllFaceDown() {
        if noneFaceUp() {return}
        for index in cards.indices {
            turnFaceDown(at: index)
        }
    }
    
    /// Turn the card at the given index face down. As a side effect, modify the score to penalize the player if any of the cards
    /// report that they were previously seen as they go face down.
    private mutating func turnFaceDown(at index: Int) {
        score -= cards[index].goFaceDown().intValue
    }
    
    // MARK: - Nested Struct(s)
    /// A Card is an entity that encapsulates:
    ///     - some generic content;
    ///     - a unique ID to distinguish it from all other cards, even one with the identical content;
    ///     - the knowledge of whether it is face up or not;
    ///     - the knowledge of whether or not it has been matched;
    ///     - the knowledge of whether or not it has been previously viewed
    ///
    /// A card must conform to the Indentifiable protocol so it can be unique among the collection of cards
    /// in a game. It conforms to this protocol by including a variable called "id."
    struct Card : Identifiable {
        
        // MARK: - Instance variables
        private(set) var isFaceUp = false
        private(set) var isMatched = false
        private(set) var previouslySeen = false
        let content: CardContent
        let id: Int
        
        // MARK: - Instance methods
        /// Flip the card over, turning it face up if it is face down, or vice versa
        mutating func flip() {
            isFaceUp.toggle()
        }
        
        /// Establish that this card has matched another card
        mutating func becomeMatched() {
            isMatched = true
        }
        
        /// Turn the receiver face up
        mutating func goFaceUp() {
            isFaceUp = true
        }
        /// Turn this card face down, but only if it's face up. If it is face up, also record that it has
        /// been seen. Answer a Boolean: whether or not turning down this card should incur a
        /// penalty. If the card was face down, no penalty. If it had been seen already before this turn,
        /// and is not part of a match, it should incur a penalty.
        /// - Returns: a Boolean: true if this card had been seen before this turn and is not part
        /// of a match
        mutating func goFaceDown() -> Bool {

            if !isFaceUp { return false}
            
            let wasPreviouslySeen = previouslySeen
            previouslySeen = true
            isFaceUp = false
            return wasPreviouslySeen && !isMatched
        }
        
        /// Answers a Boolean, true if this card's content matches another card's content
        /// - Parameter card: another Card in the game
        /// - Returns: a Boolean, ture if this card's content is equal to the given card's content
        func matches(_ card: Card) -> Bool {
            self.content == card.content
        }
        
        /// Answers what the current state of this card is for display purposes: whether face up or face down,
        /// and whether or not it has been matched by another card
        /// - Returns: a CardState enum that uniquely defines the state of this card
        func state() -> CardState {
            if isMatched {
                if isFaceUp {
                    return .faceUpAndMatched
                }
                return .faceDownAndMatched
            }
            if isFaceUp {
                return .faceUpAndUnmatched
            }
            return .faceDownAndUnmatched
        }
    } // end of Card struct
} // end of MemoryGame struct

/// The characteristics of a given theme, including its name, its color, and the emojis contained in that theme. Also includes the
/// number of pairs of cards to show as part of this theme, which must not exceed the number of emojis in the theme. The latter can
/// be changed by the user.
struct Theme: Equatable {
    
    // MARK: - Type (aka "Class") methods

    /// Factory method to create and return a Theme based on a given String name. The cases here cover the "factory installed"
    /// themes, but others can be added to the game by creating a new Theme with the init.
    /// - Parameter themeName: the ThemeName enum on which to base the theme
    /// - Returns: a Theme with its emojis, name, and image bundled together
    static func themeFor(name: String) -> Theme {
        let travelEmojis = ["🚗", "🚲", "🚤", "🚎", "🚌", "🚜", "🚓", "🚑", "🚛", "🛴", "🦼",
                            "🚠", "✈️", "🚀", "🚁", "🛶", "🛸", "🛫", "🚒", "🛵", "🚃", "🚄",
                            "🚂", "⛵️", "🛷", "🦽", "🎢", "🎠"]
        let valentineEmojis = ["🥰", "😍", "😘", "💋", "🍫", "🥂", "🎡", "💒", "❤️", "💖",
                               "💕", "💞", "💓", "💘"]
        let sportsEmojis = ["⚽️", "🏀", "🏈", "⚾️", "🥎", "🎾", "🏐", "🥏", "🏓", "🏸", "🏑",
                            "🏏", "⛳️", "⛸", "⛷", "🏊", "🚴"]
        let halloweenEmojis = ["😈", "🤡", "👻", "💀", "👽", "🤖", "🎃", "🕷", "🍩", "🍫",
                               "🍎", "🍬"]
        let foodEmojis = ["🍏", "🍐", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🫐", "🍈", "🍒",
                          "🍑", "🥭", "🍍", "🥥", "🥝", "🍅", "🍆", "🥑", "🥦", "🥬", "🥒",
                          "🌶", "🫑", "🌽", "🥕", "🫒", "🧄", "🧅", "🥔", "🍠", "🥐", "🥯",
                          "🍞", "🥖", "🥨", "🧀", "🥚", "🧈", "🥞", "🧇", "🥓", "🥩", "🍗",
                          "🍖", "🌭", "🍔", "🍟", "🍕", "🥪", "🥙", "🌮"]
        let occupationEmojis = ["👮🏼‍♀️", "👩🏾‍⚕️", "👩🏼‍🌾", "👩🏻‍🏫", "👩🏼‍💻", "👩🏼‍🔬", "👩🏽‍🎨", "👩🏼‍🚒", "👩🏻‍🚀", "👩🏼‍⚖️",
                                "👩🏽‍🍼", "💇🏽‍♂️", "🤺", "⛷", "🚴🏼‍♀️", "🤹🏾‍♀️", "🏌🏾‍♀️"]


        switch name {
        case "Travel":
            return Theme(emojis: travelEmojis,
                         name: name,
                         color: "Green")
        case "Valentine":
            return Theme(emojis: valentineEmojis,
                         name: name,
                         color: "Pink")
        case "Sports":
            return Theme(emojis: sportsEmojis,
                         name: name,
                         color: "Red")
        case "Halloween":
            return Theme(emojis: halloweenEmojis,
                         name: name,
                         color: "Orange")
        case "Food":
            return Theme(emojis: foodEmojis,
                         name: name,
                         color: "Mint")
        case "Occupations":
            return Theme(emojis: occupationEmojis,
                         name: name,
                         color: "Brown")
        default:
            return Theme(emojis: [String](),
                         name: name,
                         color: "White"
            )
        }
    }

    // MARK: - Instance Constants, Variables & Init(s)
    /// A struct encapsulating the constants for a Theme
    private struct Constants {
        
        /// Unless specified otherwise, the number of emojis to show by default
        static let defaultEmojiCount = 3
        
        /// The minimum number of emojis to show
        static let minEmojis = 1
    }
    
    /// The array of emoji strings
    let emojis: [String]
    
    /// The name of the theme
    let name: String
    
    /// A String describing the desired color for this theme
    let color: String
    
    /// How many emojis are desirable to show as part of this theme
    var numEmojisToShow = Constants.defaultEmojiCount
    
    /// Initialize the array of emoji strings, the name of the theme, and the color for this Theme
    /// - Parameters:
    ///   - emojis: an array of Strings
    ///   - name: a String
    ///   - color: a String describing the color associated with this Theme
    init(emojis: [String], name: String, color: String) {
        self.emojis = emojis
        self.name = name
        self.color = color
    }
    
    // MARK: - Instance methods
    
    /// Adds an emoji to the emoji count as long as it does not exceed the total number of emojis
    /// in the emojis array.
    /// - Returns: a Boolean, true if the increment succeeded
    mutating func increaseEmojis() -> Bool {
        if numEmojisToShow < emojis.count {
            numEmojisToShow += 1
            return true
        }
        return false
    }
    
    /// Removes an emoji from the emoji count as long as the number of emojis does not fall
    /// below the miniumum
    /// - Returns: a Boolean, true if the decrement succeeded
    mutating func decreaseEmojis() -> Bool {
        if numEmojisToShow > Constants.minEmojis {
            numEmojisToShow -= 1
            return true
        }
        return false
    }

}

/// The choices for all the possible themes, along with their names
/// Depricated. We are using Strings now for the name of the theme instead
enum ThemeName: String, CaseIterable {
    case travel = "Travel"
    case valentine = "Valentine"
    case sports = "Sports"
    case halloween = "Halloween"
    case food = "Food"
    case occupations = "Occupations"
}

/// An enumeration of all of the possible states a Card can be in that affect how it is shown: any combination
/// of face up or face down and matched or unmatched.
enum CardState {
    case faceDownAndMatched
    case faceDownAndUnmatched
    case faceUpAndMatched
    case faceUpAndUnmatched
}
