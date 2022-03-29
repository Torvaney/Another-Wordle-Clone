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
    let isHardMode: Bool
    
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
    
    init(dictionary: [String], isHardMode: Bool = false) {
        // NOTE: make impossible states impossible. Perhaps an empty dictionary should proceed straight to end game?
        //       or require dictionary to be a non-empty list. Or supply dictionary and target as separate arguments?
        // NOTE: What if we get the target using the date to create an index within the dictionary? (Maybe use date to set the seed?)
        target = dictionary.randomElement() ?? "NIL STATE SHOULD BE IMPOSSIBLE?!"
        self.dictionary = dictionary
        
        maxGuesses = 6
        prevGuesses = []
        currentGuess = []
        
        self.isHardMode = isHardMode
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
    
    mutating func submit() -> SubmitResult {
        if currentGuess.count != targetLength {
            // Technically includes too many letters, too.
            // But that *should* be impossible
            return .notEnoughLetters
        } else if !dictionary.contains(String(currentGuess)) {
            return .notInDictionary
        } else if let result = hardModeResult, isHardMode {
            return result
        } else {
            prevGuesses.append(String(currentGuess))
            currentGuess = []
            return .success
        }
    }
    
    private var hardModeResult: SubmitResult? {
        targetGuesses
            .compactMap { (letter, index, status) -> SubmitResult? in
                switch status {
                case .notGuessed:
                    return nil
                case .unknownPosition:
                    if currentGuess.contains(letter) {
                        return nil
                    } else {
                        return .notUsingKnownLetter(letter)
                    }
                case .knownPosition:
                    if let guessAtIndex = currentGuess[safe: index], guessAtIndex != letter {
                        return .notUsingKnownLetterAtLocation(letter, at: index)
                    } else {
                        // If the guess at the given index is the same as the target letter
                        // OR if there's no letter in the current guess (should be caught elsewhere!)
                        return nil
                    }
                }
            }
            // Picking the first one actually leaks information about the target word
            // TODO: pick using the first one as it appears in the current guess
            .first
    }
    
    var targetGuesses: [(Character, Int, TargetLetterStatus)] {
        let targetIndexed: [(Character, Int)] = Array(zip(target, 0..<target.count))
        let prevIndexed: [(Character, Int)] = prevGuesses.flatMap { Array(zip($0, 0..<$0.count)) }
        
        return targetIndexed
            .map { (letter: Character, ix: Int) -> (Character, Int, TargetLetterStatus) in
                if prevIndexed.contains(where: { $0 == (letter, ix) }) {
                    return (letter, ix, .knownPosition)
                } else if prevIndexed.contains(where: { $0.0 == letter }) {
                    return (letter, ix, .unknownPosition)
                } else {
                    return (letter, ix, .notGuessed)
                }
            }
    }
    
    enum TargetLetterStatus {
        case notGuessed
        case unknownPosition
        case knownPosition
    }
    
    private struct IndexedLetter: Hashable {
        let letter: Character
        let index: Int
    }
    
    enum SubmitResult {
        case success
        case notEnoughLetters
        case notInDictionary
        case notUsingKnownLetter(_ letter: Character)
        case notUsingKnownLetterAtLocation(_ letter: Character, at: Int)
    }
        
    enum GameState {
        case playing
        case won
        case lost
    }
}
