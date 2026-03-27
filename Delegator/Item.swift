//
//  Item.swift
//  Delegator
//
//  Created by Jacob Cuthbertson on 3/27/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
