//
//  Optional.swift
//  Another Wordle Clone
//
//  Created by Ben Torvaney on 28/03/2022.
//

import Foundation


extension Optional {
    func ifSome<X>(_ yes: X, _ no: X) -> X {
        switch self {
        case .none:
            return no
        case .some:
            return yes
        }
    }
}
