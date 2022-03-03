//
//  ContentView.swift
//  Another Wordle Clone
//
//  Created by Ben Torvaney on 23/02/2022.
//

import SwiftUI

struct WordleGameView: View {
    @ObservedObject var game: WordleGame
    
    var body: some View {
        switch game.state {
        case .playing: playing
        case .won: won
        case .lost: lost
        }
    }
    
    @ViewBuilder
    private var playing: some View {
        VStack {
            Title()
            Spacer()
            Text("The word is \(game.target)")
            Guesses(game.guesses)
            Spacer()
            Keyboard(game: game)
            Spacer()
        }.padding(.vertical)
    }
    
    @ViewBuilder
    private var won: some View {
        VStack {
            Text("You won! 🎉").font(.title)
            Row(guess: game.evaluateGuess(game.target, target: game.target))
                .padding(.horizontal)
            PlayAgainButton(game: game)
        }
    }
    
    @ViewBuilder
    private var lost: some View {
        VStack {
            Text("You lost! 😨").font(.title)
            Text("The word was \(game.target)")
            PlayAgainButton(game: game)
        }
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


struct PlayAgainButton: View {
    @ObservedObject var game: WordleGame
    
    var body: some View {
        Button("Play again") {
            game.reset()
        }
        .padding(.vertical)
    }
}


struct Guesses: View {
    private let guesses: [WordleGame.WordGuess]
    
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
    let guess: WordleGame.WordGuess
    
    var body: some View {
        HStack {
            ForEach(0..<5) { ix in
                // TODO: need a permanent fix for this. Maybe WordGuess should just be a hashable struct?
                let letterGuess = guess[ix]
                LetterCard(letterGuess)
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }
}


struct LetterCard: View {
    private let letterGuess: WordleGame.LetterGuess
    
    init(_ letterGuess: WordleGame.LetterGuess) {
        self.letterGuess = letterGuess
    }
    
    var body: some View {
        GeometryReader { geometry in
            let shape = RoundedRectangle(cornerRadius: 15)
            let outline = shape.strokeBorder(lineWidth: 2)
            let letterSize = geometry.size.width * DrawingConstants.fontScale
            
            switch letterGuess {
            case .empty:
                outline
            case .pending(let letter):
                ZStack {
                    outline
                    viewLetter(letter, size: letterSize)
                }
                
            case .submitted(let letter, let status):
                ZStack {
                    shape.fill(statusColour(status))
                    outline
                    viewLetter(letter, size: letterSize)
                }
            }
        }
    }
        
    private func viewLetter(_ letter: Character, size: CGFloat) -> some View {
        Text(String(letter))
            .font(.system(size: size))
            .multilineTextAlignment(.center)
    }
    
    private struct DrawingConstants {
        static let fontScale: CGFloat = 0.8
    }
}


struct Keyboard: View {
    @ObservedObject var game: WordleGame
    private let alphabet = "QWERTYUIOPASDFGHJKLZXCVBNM"
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(), count: 10), alignment: .center) {
            ForEach(Array(alphabet), id: \.self) { LetterKey(letter: $0, game: game) }
            Spacer()
            Spacer()
            BackspaceKey(game: game)
            EnterKey(game: game)
        }
        .padding(.horizontal)
    }
}


struct LetterKey: View {
    let letter: Character
    @ObservedObject var game: WordleGame
    
    @ViewBuilder
    var background: some View {
        let shape = RoundedRectangle(cornerRadius: 5)
        
        if let status = game.guessedLetters[letter] {
            shape.fill(statusColour(status))
            shape.strokeBorder()
        } else {
            shape.strokeBorder()
        }
    }
    
    var body: some View {
        ZStack {
            background
            Text(String(letter))
        }
        .onTapGesture {
            game.addLetter(letter)
        }
    }
}


struct EnterKey: View {
    var game: WordleGame
    
    var body: some View {
        ZStack {
            Text("✅")
        }
        .onTapGesture {
            game.submit()
        }
    }
}


struct BackspaceKey: View {
    var game: WordleGame
    
    var body: some View {
        ZStack {
            Text("⬅️")
        }
        .onTapGesture {
            game.removeLetter()
        }
    }
}


func statusColour(_ status: WordleGame.GuessStatus) -> Color {
    switch status {
    case .notInWord:
        return .gray
    case .inWord:
        return .orange
    case .inPosition:
        return .green
    }
}



// Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WordleGameView(game: WordleGame())
                .preferredColorScheme(.light)
        }
    }
}

    
