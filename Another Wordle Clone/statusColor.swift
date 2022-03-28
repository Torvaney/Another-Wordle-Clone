//
//  statusColor.swift
//  Another Wordle Clone
//
//  Created by Ben Torvaney on 28/03/2022.
//

import SwiftUI

func statusColor(_ status: WordleGame.GuessStatus) -> Color {
    switch status {
    case .notInWord:
        return .gray
    case .inWord:
        return .orange
    case .inPosition:
        return .green
    }
}
