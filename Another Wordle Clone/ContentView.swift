//
//  ContentView.swift
//  Another Wordle Clone
//
//  Created by Ben Torvaney on 23/02/2022.
//

import SwiftUI

struct ContentView: View {
    var game: WordleGame
    
    var body: some View {
        VStack {
            Title()
            Guesses(game.guesses)
            Spacer()
        }.padding(.vertical)
    }
}

struct Title: View {
    var body: some View {
        VStack {
            Text("Hello, Wordle!")
                .font(.title)
        }
    }
}


struct Guesses: View {
    let guesses: [WordleGame.WordGuess]
    
    init(_ guesses: [WordleGame.WordGuess]) {
        self.guesses = guesses
    }
    
    var body: some View {
        VStack {
            ForEach(guesses, id: \.self) { guess in
                Row(guess: guess)
            }
        }.padding(.horizontal)
    }
}


struct Row: View {
    var guess: WordleGame.WordGuess
    
    var body: some View {
        HStack {
            ForEach(0..<5) { ix in
                // TODO: need a permanent fix to this. Maybe WordGuess should just be hashable?
                let letterGuess = guess[ix]
                LetterCard(letterGuess)
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }
}


struct LetterCard: View {
    // Note: Will need a more complex data type to represent each letter card in future.
    // Letters can be
    //   * empty
    //   * guessed (temp),
    //   * guessed (submitted)
    //   * guessed (submitted, in word)
    //   * guessed (submitted, in right place)
    var letterGuess: WordleGame.LetterGuess
    
    init(_ letterGuess: WordleGame.LetterGuess) {
        self.letterGuess = letterGuess
    }
    
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 15)
        let outline = shape.strokeBorder(lineWidth: 2)
        
        switch letterGuess {
        case .empty:
            outline
        case .pending(let letter):
            ZStack {
                outline
                viewLetter(letter)
            }
        case .notInWord(let letter):
            ZStack {
                outline
                viewLetter(letter)
            }
        case .inWord(let letter):
            ZStack {
                shape.fill(.orange)
                outline
                viewLetter(letter)
            }
        case .inPosition(let letter):
            ZStack {
                shape.fill(.green)
                outline
                viewLetter(letter)
            }
        }
    }
    
    func viewLetter(_ letter: Character) -> some View {
        Text(String(letter))
            .bold()
            .font(.headline)
    }
}




// Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView(game: WordleGame())
                .preferredColorScheme(.light)
            ContentView(game: WordleGame())
                .preferredColorScheme(.dark)
        }
    }
}

