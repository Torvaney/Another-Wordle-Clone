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
            RowOfLetters(guess: game.target)
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
            RowOfLetters(guess: game.target)
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
        ZStack {
            VStack {
                title
                Spacer()
                guesses
                Spacer()
                keyboard
                Divider()
                hardModeToggle
            }
            .padding(.vertical)
            
            VStack {
                alert
                    .padding()
                    .offset(x: 0, y: 10)
                Spacer()
            }
            
        }
    }
    
    private var title: some View {
        Text("Hello, Wordle!")
            .font(.title)
            .bold()
    }
    
    private var hardModeToggle: some View {
        Toggle("Hard mode", isOn: $game.isHardMode)
            .disabled(!game.isGameStart)
            .padding(.horizontal)
    }
    
    private var keyboard: some View {
        WordleKeyboard(
            guessedLetters: game.guessedLetters,
            onLetter: game.addLetter,
            onBackspace: game.removeLetter,
            onEnter: {
                // NOTE: Submission animations are handled using onAppear.
                //       This seems like poor practice?
                //       But not sure how to get it it work as desired otherwise...
                //       Maybe it would work now that the IDs are correct?
                //       TODO: try animating withAnimation instead of onAppear
                let submitResult = game.submit()
                animateAlert(submitResult)
            }
        )
    }
    
    
    // MARK: On-submit alerts (i.e. invalid submission attempt)
    
    @State private var lastSubmitResult: Wordle.SubmitResult? = nil
    @State private var showAlert: Bool = false
    
    private func animateAlert(_ result: Wordle.SubmitResult) -> () {
        lastSubmitResult = result
        
        switch result {
        case .success:
            showAlert = false
        default:
            showAlert = true
            withAnimation(.easeOut(duration: 0.3).delay(1)) {
                showAlert = false
            }
        }
    }
    
    private var alert: some View {
        Text(alertText)
            .foregroundColor(Color(UIColor.systemBackground))
            .bold()
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 5)
                    .fill(.foreground)
            }
            .opacity(showAlert ? 1 : 0)
    }
    
    private var alertText: String {
        switch lastSubmitResult {
        
        // Should never be shown on-screen
        // (i.e. should never co-occur with showAlert)
        case .none:
            return ""
        case .some(.success):
            return ""
            
        // Basic alerts
        case .some(.notInWordList):
            return "Not in word list"
        case .some(.notEnoughLetters):
            return "Not enough letters"
        
        // Hard mode
        case .some(.notUsingKnownLetter(let letter)):
            return "Must use letter \(letter)"
        case .some(.notUsingKnownLetterAtLocation(let letter, at: let at)):
            return "\(ordinalise(at+1)) letter should be \(letter)"
        }
    }
    
    private func ordinalise(_ n: Int) -> String {
        switch n {
        case 1:
            return "1st"
        case 2:
            return "2nd"
        case 3:
            return "3rd"
        default:
            // It's okay to ignore 21st etc, since
            // we will never have that many letters (for now?)
            return "\(n)th"
        }
    }
    
    
    // MARK: Wordle board (current, previous and unused guesses)
    
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
        let guess: WordleGame.IndexedWordGuess
        
        var body: some View {
            HStack {
                ForEach(guess) { LetterCard($0).aspectRatio(1, contentMode: .fit) }
            }
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
        let _ = game.submit()

        game.addLetter("A")
        game.addLetter("B")
        
        return WordleGameView(game: game)
                    .preferredColorScheme(.light)
    }
}

    
