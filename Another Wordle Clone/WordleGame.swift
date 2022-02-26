//
//  WordleGame.swift
//  Another Wordle Clone
//
//  Created by Ben Torvaney on 26/02/2022.
//

import SwiftUI


class WordleGame {
    // NOTE: later, we will load the dictionary from somewhere
    //       could do something fun where you can select the dictionary to use when you start a new game
    // I guess the dictionary should contain some representation of word length
    private var model: Wordle =  Wordle(dictionary: ["POWER", "CAIRN", "FUNKY", "VIVID", "DANCE"])
    
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
        zip(guess, target).map { (guessLetter, targetLetter) -> LetterGuess in
            if (guessLetter == targetLetter) {
                return .inPosition(guessLetter)
            }
            else if target.contains(guessLetter) {
                return .inWord(guessLetter)
            }
            else {
                return .notInWord(guessLetter)
            }
        }
    }
    
    enum LetterGuess: Hashable {
        // NOTE: should these two groups of cases be separated to ensure that the
        // compiler can check that they are used in appropriate places?
        // E.g. maybe viewing the current guess should be totally different
        // from the previous guesses, and thus these types should be split out
        
        // Current guess
        case empty
        case pending(_ letter: Character)
        
        // Submitted guess
        case notInWord(_ letter: Character)
        case inWord(_ letter: Character)
        case inPosition(_ letter: Character)
    }
}
