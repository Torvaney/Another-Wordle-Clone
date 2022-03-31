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
    
    func cleave(at: Int) -> ([Element], [Element]) {
        // Split an array at a given index into 2 arrays
        // The first array contains elements up to and including `n`
        // The second array contains the elements after `n`
        (Array(self.prefix(at)), Array(self.dropFirst(at)))
    }
}
