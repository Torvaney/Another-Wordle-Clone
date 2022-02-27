//
//  Wordle.swift
//  Another Wordle Clone
//
//  Created by Ben Torvaney on 26/02/2022.
//

import Foundation


struct Wordle {
    let target: String
    let dictionary: [String]
    
    let maxGuesses: Int
    private(set) var prevGuesses: [String]
    private(set) var currentGuess: [Character]
    
    var targetLength: Int {
        target.count
    }
    
    var state: GameState {
        if prevGuesses.count > 0 && prevGuesses.contains(target) {
            return .won
        } else if prevGuesses.count == maxGuesses {
            return .lost
        } else {
            return .playing
        }
    }
    
    init(dictionary: [String]) {
        // NOTE: make impossible states impossible. Perhaps an empty dictionary should proceed straight to end game?
        //       or require dictionary to be a non-empty list. Or supply dictionary and target as separate arguments?
        // NOTE: What if we get the target using the date to create an index within the dictionary? (Maybe use date to set the seed?)
        target = dictionary.randomElement() ?? "NIL STATE SHOULD BE IMPOSSIBLE?!"
        self.dictionary = dictionary
        
        maxGuesses = 6
        prevGuesses = []
        currentGuess = []
    }
    
    // Handling user input
    // User can: Add letter, remove letter, submit guess
    // Maybe a custom data structure (like a Zipper) would handle this more elegantly
    mutating func addLetter(_ letter: Character) {
        if currentGuess.count < targetLength {
            currentGuess.append(letter)
        }
    }

    mutating func removeLetter() {
        if currentGuess.count > 0 {
            currentGuess.removeLast()
        }
    }
    
    // NOTE: might be useful later to return some data indicating the outcome
    // of the submission (success, invalid word, &c)
    mutating func submit() {
        if (currentGuess.count == targetLength) && (dictionary.contains(String(currentGuess))) {
            prevGuesses.append(String(currentGuess))
            currentGuess = [] 
        }
    }
        
    enum GameState {
        case playing
        case won
        case lost
    }
}
