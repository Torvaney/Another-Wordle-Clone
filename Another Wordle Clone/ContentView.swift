//
//  ContentView.swift
//  Another Wordle Clone
//
//  Created by Ben Torvaney on 23/02/2022.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Title()
            Guesses()
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
    var body: some View {
        VStack {
            Row(letters: ["C", "A", "R", "E", "T"])
            Row(letters: ["I", "N", "D", "O", "L"])
            Row()
            Row()
            Row()
            Row()
        }.padding(.horizontal)
    }
}


struct Row: View {
    var letters: [Character?] = [nil, nil, nil, nil, nil]
    
    var body: some View {
        HStack {
            ForEach(letters, id: \.self) { letter in
                LetterCard(letter: letter)
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
    var letter: Character?
    
    var body: some View {
        let outline = RoundedRectangle(cornerRadius: 15)
            .stroke(lineWidth: 2)
        
        switch letter {
        case .some(let char):
            ZStack {
                outline
                Text(String(char))
                    .bold()
            }
        case .none:
            ZStack {
                outline
            }
        }
    }
}




// Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .preferredColorScheme(.light)
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

