//
//  MemorizeApp.swift
//  Memorize
//
//  Created by Sigrid Mortensen on 8/12/22.
//  Copyright © 2022 Sigrid E. Mortensen. All rights reserved
//

import SwiftUI

@main
struct MemorizeApp: App {
    private let game = EmojiMemoryGame()
    var body: some Scene {
        WindowGroup {
            EmojiMemoryGameView(game: game)
        }
    }
}
