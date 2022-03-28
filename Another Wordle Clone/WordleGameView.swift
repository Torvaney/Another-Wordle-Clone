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
    
    // MARK: End game states
    
    @ViewBuilder
    private var won: some View {
        VStack {
            Text("You won! 🎉")
                .font(.title)
            RowOfLetters(guess: game.evaluateGuess(game.target))
                .padding(.horizontal)
            playAgainButton
        }
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity).animation(.spring()),
            removal: .opacity.animation(.linear(duration: 0.1))
        ))
    }
    
    @ViewBuilder
    private var lost: some View {
        VStack {
            Text("You lost! 😨")
                .font(.title)
            RowOfLetters(guess: game.evaluateTarget())
                .padding(.horizontal)
            playAgainButton
        }
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity).animation(.spring()),
            removal: .opacity.animation(.linear(duration: 0.1))
        ))
    }
    
    private var playAgainButton: some View {
        Button("Play again") {
            game.reset()
        }
        .padding(.vertical)
    }
    
    // MARK: Playing the game
    
    @ViewBuilder
    private var playing: some View {
        VStack {
            title
            Spacer()
            guesses
            Spacer()
            WordleKeyboard(game: game)
        }
        .padding(.vertical)
    }
    
    private var title: some View {
        Text("Hello, Wordle!")
            .font(.title)
            .bold()
    }
    
    private var guesses: some View {
        VStack {
            ForEach(game.guesses, id: \.self) { RowOfLetters(guess: $0) }
        }.padding(.horizontal)
    }
    
    // Using a struct instead of a computed var means that the onAppear animations for submitted
    // letters only appear on submit
    // With a computed var, they are triggered on *any* change to the UI
    // NOTE: Maybe this should be pulled out into a separate view with it's own previews?
    private struct RowOfLetters: View {
        let guess: WordleGame.WordGuess
        
        var body: some View {
            HStack {
                ForEach(guess) { LetterCard($0).aspectRatio(1, contentMode: .fit) }
            }
        }
    }

    private struct LetterCard: View {
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
                        shape.fill(statusColor(status))
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
}



// Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let game = WordleGame(dictionary: ["DANCE", "WHEEL", "PUMPS"])
        
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

    
