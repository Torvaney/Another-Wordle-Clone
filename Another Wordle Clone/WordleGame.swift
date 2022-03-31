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
        // For now, ignore the case where the dictionary is empty (`try!`) when initialising a new Wordle game
        // Since we know that the dictionary will always be loaded in the real app
        // When I learn more about error handling, I will (maybe?) come back and fix this
        // and the failing cases of dictionary loading
        model = try! Wordle(dictionary: dictionary ?? WordleGame.loadDictionary())
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
    
    func submit() -> Wordle.SubmitResult {
        model.submit()
    }
    
    func reset() {
        model = try! Wordle(dictionary: model.dictionary, isHardMode: model.isHardMode)
    }
    
    func toggleHardMode() {
        if isGameStart {
            // Creating a new game ensures that hard mode is only ever set at the start of the game
            // (In fact changing mid-game is impossible, because `isHardMode` is immutable :))
            model = try! Wordle(dictionary: model.dictionary, isHardMode: !model.isHardMode)
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
        model.targetGuesses.map { (letter, ix, status) in
            IndexedLetterGuess(.submitted(letter, status: targetStatusToGuessStatus(status)), at: (0, ix))
        }
    }
    
    private func targetStatusToGuessStatus(_ status: Wordle.TargetLetterStatus) -> GuessStatus {
        switch status {
        case .notGuessed:
            return .notInWord
        case .unknownPosition:
            return .inWord
        case .knownPosition:
            return .inPosition
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
    
    struct Pair<T: Hashable, U: Hashable>: Hashable {
      let first: T
      let second: U
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
    
    typealias LetterLookup = Dictionary<Character, GuessStatus>
    
    var guessedLetters: LetterLookup {
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
                return []
            }
        } else {
            // File not found!
            return []
        }
    }
}
