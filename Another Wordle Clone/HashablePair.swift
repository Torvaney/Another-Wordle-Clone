//
//  HashablePair.swift
//  Another Wordle Clone
//
//  Created by Ben Torvaney on 31/03/2022.
//

import Foundation


struct HashablePair<T: Hashable, U: Hashable>: Hashable {
    let first: T
    let second: U
    
    init(first: T, second: U) {
        self.first = first
        self.second = second
    }
    
    init(fromTuple: (T, U)) {
        first = fromTuple.0
        second = fromTuple.1
    }
}
