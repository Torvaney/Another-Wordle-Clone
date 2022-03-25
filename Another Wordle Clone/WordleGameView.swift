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
            // Text("The word is \(game.target)")
            Guesses(game.guesses)
            Spacer()
            Keyboard(game: game)
            Spacer()
        }
        .padding(.vertical)
    }
    
    @ViewBuilder
    private var won: some View {
        VStack {
            Text("You won! 🎉")
                .font(.title)
            Row(guess: game.evaluateGuess(game.target, target: game.target))
                .padding(.horizontal)
            PlayAgainButton(game: game)
        }
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity).animation(.spring()),
            removal: .opacity.animation(.linear(duration: 0.1))
        ))
    }
    
    @ViewBuilder
    private var lost: some View {
        VStack {
            Text("You lost! 😨").font(.title)
            Text("The word was \(game.target)")
            PlayAgainButton(game: game)
        }
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity).animation(.spring()),
            removal: .opacity.animation(.linear(duration: 0.1))
        ))
    }
}

struct Title: View {
    var body: some View {
        VStack {
            Text("Hello, Wordle!")
                .font(.title)
                .bold()
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
            ForEach(guesses, id: \.self) { Row(guess: $0) }
        }.padding(.horizontal)
    }
}


struct Row: View {
    let guess: WordleGame.WordGuess
    
    var body: some View {
        HStack {
            ForEach(guess) { LetterCard($0).aspectRatio(1, contentMode: .fit) }
        }
    }
}


struct LetterCard: View {
    private let letterGuess: WordleGame.LetterGuess
    
    init(_ letterGuess: WordleGame.LetterGuess) {
        self.letterGuess = letterGuess
    }

    // Manage animations
    @State private var rotation: Double = 0  // in Degrees
    @State private var scale: Double = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            let shape = RoundedRectangle(cornerRadius: LetterCardConstants.cornerRadius)
            let outline = shape.strokeBorder(lineWidth: LetterCardConstants.strokeWidth)
            let letterSize = geometry.size.width * LetterCardConstants.fontScale
            
            switch letterGuess {
                
            case .empty:
                outline.opacity(LetterCardConstants.emptyOpacity)
                
            case .pending(let letter):
                ZStack {
                    outline.scaleEffect(scale)
                    viewLetter(letter, size: letterSize, color: .primary)
                }
                .onAppear {
                    self.scale = 1.1
                    withAnimation(.linear(duration: LetterCardConstants.bounceDuration)) {
                        self.scale = 1.0
                    }
                }
                
            case .submitted(let letter, let status):
                ZStack {
                    shape.fill(statusColour(status))
                    viewLetter(letter, size: letterSize, color: .white)
                }
                .rotation3DEffect(.degrees(rotation), axis: (1, 0, 0))
                .onAppear {
                    self.rotation = 90
                    withAnimation(.linear(duration: LetterCardConstants.flipDuration)) {
                        self.rotation = 0
                    }
                }
            }
        }
    }
        
    private func viewLetter(_ letter: Character, size: CGFloat, color: Color) -> some View {
        Text(String(letter))
            .font(.system(size: size))
            .foregroundColor(color)
            .bold()
            .multilineTextAlignment(.center)
    }
    
    private struct LetterCardConstants {
        static let cornerRadius: CGFloat = 0
        static let strokeWidth: CGFloat = 2
        static let fontScale: CGFloat = 0.6
        static let emptyOpacity: Double = 0.6
        static let flipDuration: Double = 0.15
        static let bounceDuration: Double = 0.15
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
        let shape = RoundedRectangle(cornerRadius: 3)
        
        if let status = game.guessedLetters[letter] {
            shape
                .fill(statusColour(status))
        } else {
            shape
                .fill(.secondary)
                .opacity(0.35)
        }
    }
    
    var textColor: Color {
        if let _ = game.guessedLetters[letter] {
            return .white
        } else {
            return .primary
        }
    }
    
    var body: some View {
        ZStack {
            background
                .transition(.opacity.animation(.easeIn))
            Text(String(letter))
                .foregroundColor(textColor)
        }
        .aspectRatio(3/4, contentMode: .fit)
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
            // NOTE: Submission animations are handled using onAppear.
            //       This seems like poor practice?
            //       But not sure how to get it it work as desired otherwise...
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
        let game = WordleGame()
        
        game.addLetter("P")
        game.addLetter("O")
        game.addLetter("W")
        game.addLetter("E")
        game.addLetter("R")
        game.submit()
        
        game.addLetter("A")
        game.addLetter("B")
        
        return WordleGameView(game: game)
                    .preferredColorScheme(.light)
    }
}

    
