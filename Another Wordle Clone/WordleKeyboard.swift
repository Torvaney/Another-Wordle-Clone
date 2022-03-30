//
//  WordleKeyboard.swift
//  Another Wordle Clone
//
//  Created by Ben Torvaney on 28/03/2022.
//

import SwiftUI

struct WordleKeyboard: View {
    @ObservedObject var game: WordleGame

    // TODO: want to show the alerts over the whole view - how best to achieve this?
    @State private var lastSubmitResult: Wordle.SubmitResult? = nil
    @State private var showAlert: Bool = false
    
    private let alphabet = "QWERTYUIOPASDFGHJKLZXCVBNM"
    
    var body: some View {
        ZStack {
        
            LazyVGrid(columns: Array(repeating: GridItem(), count: 10), alignment: .center) {
                ForEach(Array(alphabet), id: \.self) { letter in
                    LetterKey(letter: letter, status: game.guessedLetters[letter])
                        .onTapGesture {
                            game.addLetter(letter)
                        }
                }
                Spacer()
                Spacer()
                backspaceKey
                    .onTapGesture {
                        game.removeLetter()
                    }
                enterKey
                    .onTapGesture {
                        // NOTE: Submission animations are handled using onAppear.
                        //       This seems like poor practice?
                        //       But not sure how to get it it work as desired otherwise...
                        let submitResult = game.submit()
                        lastSubmitResult = submitResult
                        
                        switch submitResult {
                        case .success:
                            showAlert = false
                        default:
                            showAlert = true
                            withAnimation(.easeOut(duration: 0.3).delay(1)) {
                                showAlert = false
                            }
                        }
                    }
            }
            .padding(.horizontal)
            
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
    }
    
    private var alertText: String {
        switch lastSubmitResult {
        
        // Should never happen
        case .none:
            return ""
        case .some(.success):
            return ""
            
        // Basic alerts
        case .some(.notInDictionary):
            return "Not in word list"
        case .some(.notEnoughLetters):
            return "Not enough letters"
        
        // Hard mode
        case .some(.notUsingKnownLetter(let letter)):
            return "Must use letter \(letter)"
        case .some(.notUsingKnownLetterAtLocation(let letter, at: let at)):
            return "Letter \(letter) must be in location \(at + 1)"
        }
    }
    
    private struct Key<Content>: View where Content: View {
        let fill: Color
        let opacity: CGFloat
        let content: () -> Content
        
        init(fill: Color, opacity: CGFloat, @ViewBuilder content: @escaping () -> Content) {
            self.fill = fill
            self.opacity = opacity
            self.content = content
        }
        
        var body: some View {
            let shape = RoundedRectangle(cornerRadius: KeyConstants.cornerRadius)
            
            ZStack {
                shape
                    .fill(fill)
                    .opacity(opacity)
                    .transition(.opacity.animation(.easeIn))
                content()
            }
            .aspectRatio(KeyConstants.aspectRatio, contentMode: KeyConstants.aspectMode)
        }
    }
    
    private struct LetterKey: View {
        let letter: Character
        let status: WordleGame.GuessStatus?
        
        var body: some View {
            let fill = status.map(statusColor) ?? KeyConstants.baseFill
            let opacity = status.ifSome(1, KeyConstants.baseOpacity)
            
            return Key(fill: fill, opacity: opacity) {
                Text(String(letter))
                    .foregroundColor(status.ifSome(.white, .primary))
            }
        }
    }
    
    var enterKey: some View {
        Key(fill: KeyConstants.baseFill, opacity: KeyConstants.baseOpacity) { Image(systemName: "return") }
    }
    
    var backspaceKey: some View {
        Key(fill: KeyConstants.baseFill, opacity: KeyConstants.baseOpacity) { Image(systemName: "delete.backward") }
    }
    
    private struct KeyConstants {
        static let aspectRatio: CGFloat = 3/4
        static let aspectMode: ContentMode = .fit
        static let baseOpacity: CGFloat = 0.35
        static let baseFill: Color = .secondary
        static let cornerRadius: CGFloat = 3
        
    }
}

struct WordleKeyboard_Previews: PreviewProvider {
    static var previews: some View {
        let game = WordleGame(dictionary: ["THICK"])
        
        game.addLetter("T")
        game.addLetter("I")
        game.addLetter("G")
        game.addLetter("H")
        game.addLetter("T")
        let _ = game.submit()
        
        return WordleKeyboard(game: game)
    }
}
