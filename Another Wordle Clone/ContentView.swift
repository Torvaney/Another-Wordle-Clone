//
//  ContentView.swift
//  Another Wordle Clone
//
//  Created by Ben Torvaney on 23/02/2022.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var game: WordleGame
    
    var body: some View {
        VStack {
            Title()
            Spacer()
            Guesses(game.guesses)
            Spacer()
            Keyboard(game: game)
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
                // TODO: need a permanent fix for this. Maybe WordGuess should just be a hashable struct?
                let letterGuess = guess[ix]
                LetterCard(letterGuess)
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }
}


struct LetterCard: View {
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


struct Keyboard: View {
    let alphabet = "QWERTYUIOPASDFGHJKLZXCVBNM"
    @ObservedObject var game: WordleGame
    
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
    
    var isUsed: Bool {
        game.usedLetters.contains(letter)
    }
    
    @ViewBuilder
    var background: some View {
        let shape = RoundedRectangle(cornerRadius: 5)
        
        // NOTE: actually need to refactor this to show the best status achieved for that
        // letter so far. I think this will require a little rethinking of the ViewModel
        if isUsed {
            shape.fill(.gray)
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



// Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView(game: WordleGame())
                .preferredColorScheme(.dark)
        }
    }
}

