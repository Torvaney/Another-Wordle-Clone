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
    @Published private var model: Wordle =  Wordle(dictionary: loadDictionary())
    
    
    // MARK: Methods fowarded from model (user intents)
    
    func addLetter(_ letter: Character) {
        model.addLetter(letter)
    }

    func removeLetter() {
        model.removeLetter()
    }
    
    func submit() {
        model.submit()
    }
    
    var state: Wordle.GameState {
        model.state
    }
    
    var target: String {
        model.target
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
        // Alternative idea:
        // Break word & target into [(Letter, Index)] (i.e. zip(word, 0..))
        // For each (Letter, Index) in target, find first, best match in word (that hasn't already been matched)?
        
        zip(guess, target).map { (guessLetter, targetLetter) -> LetterGuess in
            LetterGuess.submitted(guessLetter, status: evaluateLetter(guessLetter, targetLetter, target))
        }
    }
            
    func evaluateLetter(_ guessLetter: Character, _ targetLetter: Character, _ target: String) -> GuessStatus {
        if (guessLetter == targetLetter) {
            return .inPosition
        }
        else if target.contains(guessLetter) {
            return .inWord
        }
        else {
            return .notInWord
        }
    }
    
    enum LetterGuess: Hashable {
        // Current guess (and future guesses)
        case empty
        case pending(_ letter: Character)
        
        // Submitted guesses
        case submitted(_ letter: Character, status: GuessStatus)
    }
    
    enum GuessStatus: Comparable {
        case notInWord
        case inWord
        case inPosition
        
        static func < (lhs: Self, rhs: Self) -> Bool {
             switch (lhs, rhs) {
             case (.notInWord, _):
                 return true
             case (.inWord, .inPosition):
                 return true
             default:
                 return false
             }
         }
    }
    
    
    // MARK: Getting used letters
    
    var usedLetters: Set<Character> {
        Set(model.prevGuesses.joined(separator: ""))
    }
    
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
        
        return Dictionary(letterGuesses, uniquingKeysWith: min)
    }
    
    
    // MARK: Dictionary (Temp?)
    
    static func loadDictionary() -> [String] {
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
