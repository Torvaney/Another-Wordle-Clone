//
//  LetterCard.swift
//  Another Wordle Clone
//
//  Created by Ben Torvaney on 31/03/2022.
//

import SwiftUI

struct LetterCard: View {
    private let letterGuess: WordleGame.IndexedLetterGuess
    
    init(_ letterGuess: WordleGame.IndexedLetterGuess) {
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
            
            switch letterGuess.guess {
                
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
                    // Avoid singular matrix when rotation is exactly 90
                    // See: https://stackoverflow.com/questions/66031386/ignoring-singular-matrix-should-i-concerning-ignoring-to-this-console-massage-i
                    self.rotation = 89.99
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


struct LetterCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            LetterCard(WordleGame.IndexedLetterGuess(.empty, at: (0, 0)))
                .aspectRatio(1, contentMode: .fit)
            LetterCard(WordleGame.IndexedLetterGuess(.pending("E"), at: (1, 0)))
                .aspectRatio(1, contentMode: .fit)
            HStack {
                LetterCard(WordleGame.IndexedLetterGuess(.submitted("A", status: .notInWord), at: (2, 0)))
                LetterCard(WordleGame.IndexedLetterGuess(.submitted("B", status: .inWord), at: (2, 1)))
                LetterCard(WordleGame.IndexedLetterGuess(.submitted("C", status: .inPosition), at: (2, 2)))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding()
    }
}
