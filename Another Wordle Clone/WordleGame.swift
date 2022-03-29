//
//  WordleGame.swift
//  Another Wordle Clone
//
//  Created by Ben Torvaney on 26/02/2022.
//

import SwiftUI


class WordleGame: ObservableObject {
    @Published private var model: Wordle
    
    init(dictionary: [String]? = nil) {
        model = Wordle(dictionary: dictionary ?? WordleGame.loadDictionary())
    }
    
    var state: Wordle.GameState {
        model.state
    }
    
    var isHardMode: Bool {
        get { model.isHardMode }
        set { self.toggleHardMode() }
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
        model = Wordle(dictionary: model.dictionary, isHardMode: model.isHardMode)
    }
    
    func toggleHardMode() {
        if isGameStart {
            // Creating a new game ensures that hard mode is only ever set at the start of the game
            // (In fact changing mid-game is impossible, because `isHardMode` is immutable :))
            model = Wordle(dictionary: model.dictionary, isHardMode: !model.isHardMode)
        }
    }
    
    
    // MARK: Adding inferred metadata to guesses
    
    typealias WordGuess = [LetterGuess]
    typealias IndexedWordGuess = [IndexedLetterGuess]
    
    private var prevGuesses: [WordGuess] {
        model.prevGuesses.map { guess in evaluateGuess(guess) }
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
    
    var guesses: [IndexedWordGuess] {
        let baseguesses = prevGuesses + [ currentGuess ] + futureGuesses
        
        return baseguesses.enumerated().map { (guessIx, guess) in
            guess.enumerated().map { (letterIx, letter) in
                IndexedLetterGuess(letter, at: (guessIx, letterIx))
            }
        }
    }
    
    var target: IndexedWordGuess {
        // TODO: this assumes you've won the game. Needs to handle losing case, too
        model.target
            .enumerated()
            .map { (ix, letter) in
                IndexedLetterGuess(
                    .submitted(letter, status: .inPosition),
                    at: (0, ix)
                )
            }
    }
    
    var isGameStart: Bool {
        prevGuesses == []
    }
    
    private func evaluateGuess(_ guess: String) -> WordGuess {
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
        let targetIndexed: [(Character, Int)] = Array(zip(model.target, 0..<target.count))
        
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
    
    func evaluateTarget() -> WordGuess {
        // Get the closest guess in each letter
        // NOTE: this method doesn't handle repeated letters in the target well. Is there an elegant solution?
        model.target.map { .submitted($0, status: guessedLetters[$0] ?? .notInWord) }
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
    
    struct IndexedLetterGuess: Identifiable, Hashable {
        let guessIndex: Int
        let letterIndex: Int
        let guess: LetterGuess
        
        init(_ guess: LetterGuess, at: (Int, Int)) {
            self.guess = guess
            guessIndex = at.0
            letterIndex = at.1
        }
        
        // Conform to Identifiable, for the purposes of rendering Views
        // A guess is identified by its position in the grid
        internal var id: Pair<Int, Int> {
            Pair(first: guessIndex, second: letterIndex)
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

struct Pair<T: Hashable, U: Hashable>: Hashable {
  let first: T
  let second: U
}
