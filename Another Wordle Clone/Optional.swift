//
//  Optional.swift
//  Another Wordle Clone
//
//  Created by Ben Torvaney on 28/03/2022.
//

import Foundation


extension Optional {
    var isSome: Bool {
        switch self {
        case .none:
            return false
        case .some:
            return true
        }
    }
    
    func ifSome<X>(_ yes: X, _ no: X) -> X {
        if self.isSome {
            return yes
        } else {
            return no
        }
    }
}
