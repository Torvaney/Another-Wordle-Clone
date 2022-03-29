//
//  Array.swift
//  Another Wordle Clone
//
//  Created by Ben Torvaney on 28/03/2022.
//

import Foundation

extension Array {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
