//
//  WordleGame.swift
//  Another Wordle Clone
//
//  Created by Ben Torvaney on 26/02/2022.
//

import SwiftUI


class WordleGame: ObservableObject {
    // NOTE: later, we will load the dictionary from somewhere
    //       could do something fun where you can select the dictionary to use when you start a new game
    // I guess the dictionary should contain some representation of word length
    @Published private var model: Wordle = Wordle(dictionary: loadDictionary())
    
    
    var state: Wordle.GameState {
        model.state
    }
    
    var target: String {
        model.target
    }
    
    
    // MARK: User intents
    // (inc. methods fowarded from model
    
    func addLetter(_ letter: Character) {
        model.addLetter(letter)
    }

    func removeLetter() {
        model.removeLetter()
    }
    
    func submit() {
        model.submit()
    }
    
    func reset() {
        model = Wordle(dictionary: WordleGame.loadDictionary())
    }
    
    
    // MARK: Adding inferred metadata to guesses
    
    typealias WordGuess = [LetterGuess]
    
    private var prevGuesses: [WordGuess] {
        model.prevGuesses.map { guess in evaluateGuess(guess, target: model.target) }
    }
    
    private var currentGuess: WordGuess {
        let nRemaining = model.targetLength - model.currentGuess.count
        return model.currentGuess.map { .pending($0) } + Array(repeating: .empty, count: nRemaining)
    }
    
    private var futureGuesses: [WordGuess] {
        let nFutureGuesses = model.maxGuesses - prevGuesses.count - 1
        let emptyGuess = Array(repeating: LetterGuess.empty, count: model.targetLength)
        return Array(repeating: emptyGuess, count: nFutureGuesses)
    }
    
    var guesses: [WordGuess] {
        prevGuesses + [ currentGuess ] + futureGuesses
    }
    
    func evaluateGuess(_ guess: String, target: String) -> WordGuess {
        // We need to get the status of each letter in the guessed word.

        // Each letter should indicate the status of only one letter within the
        // target word. In case of repeated letters in the guess word, the most correct
        // letter should take precedence. If all letters in the guessed word are
        // equally correct, then the first letter should equal precedence.
        // For example, if the target is ABLED and the guess is ALLOY, then
        // the second L should be .inPosition and the first L should be .notInWord.
        // This indicates to the player that there is only one L in the target word.
        
        // If multiple letters appear in both guess and target letters, then the same
        // logic applies. For example, if the target is ALOOF and the guess is BOOST, then
        // the second O is evaluated as .inPosition and the first O is .inWord
        
        // To achieve this, we first break word & target into [(Letter, Index)]
        // Then, for each target letter we pair off the first, best matching letter
        // Any unpaired letters are `.notInWord`

        let guessIndexed: [(Character, Int)] = Array(zip(guess, 0..<guess.count))
        let targetIndexed: [(Character, Int)] = Array(zip(target, 0..<guess.count))
        
        let (allMatched, allRemaining): ([(LetterGuess, Int)], [(Character, Int)]) = targetIndexed.reduce(([], guessIndexed), { x, y in
            let (matched, remaining) = x
            let (letter, index) = y
            
            // Get the first, best match for the target letter
            if let firstBestMatch = findFirstBestMatch(letter, index, remaining) {
                // If there is a match, remove letter from the remaining letters and add to
                // the matched list
                return (matched + [firstBestMatch], remaining.filter { (_, ix) in ix != firstBestMatch.1 })
            } else {
                // If there is no match, return the pair unchanged
                return (matched, remaining)
            }
        })
        
        return (allMatched + allRemaining.map { (.submitted($0, status: .notInWord), $1) })
            .sorted { $0.1 < $1.1 }
            .map { $0.0 }
    }
    
    private func findFirstBestMatch(_ letter: Character, _ index: Int, _ remaining: [(Character, Int)]) -> (WordleGame.LetterGuess, Int)? {
        remaining
            // First, check whether any guessed letters are a match
            .map {
                if $0.0 == letter && $0.1 == index  {
                    return (.inPosition, $0.1)
                } else if $0.0 == letter {
                    return (.inWord, $0.1)
                } else {
                    return (.notInWord, $0.1)
                }
            }
            .filter { $0.0.isInWord() }
            // Then, find the first, best matching letter
            .max {
                if $0.0 == $1.0 {
                    return $0.1 >= $1.1
                } else {
                    return $0.0 < $1.0
                }
            }
            .map { (.submitted(letter, status: $0), $1) }
    }
    
    enum LetterGuess: Identifiable, Hashable {
        // Current guess (and future guesses)
        case empty
        case pending(_ letter: Character)
        
        // Submitted guesses
        case submitted(_ letter: Character, status: GuessStatus)
        
        // Conform to Identifiable
        // Although... I'm not sure this is actually correct...
        // Shouldn't a letter guess be identified by the Guess # and the letter index?
        // i.e. the position on the grid?
        internal var id: UUID { UUID() }
    }
    
    enum GuessStatus: Comparable {
        case notInWord
        case inWord
        case inPosition
        
        // We have implemented a basic ordering of statuses
        // so that we can easily find the highest priority one
        // for informing the player of their "best guess so far" for each letter
        static func < (lhs: Self, rhs: Self) -> Bool {
             switch (lhs, rhs) {
             case (.notInWord, _):
                 return true
             case (_, .inPosition):
                 return true
             default:
                 return false
             }
         }
        
        func isInWord() -> Bool {
            switch self {
            case .notInWord:
                return false
            default:
                return true
            }
        }
    }
    
    
    // MARK: Getting used letters
    
    var guessedLetters: Dictionary<Character, GuessStatus> {
        let letterGuesses: [(Character, GuessStatus)] = prevGuesses
            .joined()
            .compactMap { guess in
                switch guess {
                case .submitted(let letter, status: let status):
                    return (letter, status)
                default:
                    return nil
                }
            }
        
        return Dictionary(letterGuesses, uniquingKeysWith: max)
    }
    
    
    // MARK: Dictionary (Temp?)
    
    private static func loadDictionary() -> [String] {
        if let dictionaryFilepath = Bundle.main.path(forResource: "DefaultDictionary", ofType: "txt") {
            do {
                let wordList = try String(contentsOfFile: dictionaryFilepath)
                return wordList
                    .split(whereSeparator: \.isNewline)
                    .map { String($0).uppercased() }
            } catch {
                // File can't be loaded!
                // TODO: handle the failure cases with an optional instead
                return []
            }
        } else {
            // File not found!
            return []
        }
    }
}
