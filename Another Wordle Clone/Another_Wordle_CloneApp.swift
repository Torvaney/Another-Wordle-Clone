//
//  Another_Wordle_CloneApp.swift
//  Another Wordle Clone
//
//  Created by Ben Torvaney on 23/02/2022.
//

import SwiftUI

@main
struct Another_Wordle_CloneApp: App {
    private let game = WordleGame()
    
    var body: some Scene {
        WindowGroup {
            ContentView(game: game)
        }
    }
}
