//
//  Swap.swift
//  CookieCrunch
//
//  Created by Dante on 15/7/31.
//  Copyright (c) 2015年 Futurelab. All rights reserved.
//

import Foundation

struct Swap: Printable, Hashable {
    let cookieA: Cookie
    let cookieB: Cookie
    
    init(cookieA: Cookie, cookieB: Cookie) {
        self.cookieA = cookieA
        self.cookieB = cookieB
    }
    
    var description: String {
        return "swap \(cookieA) with \(cookieB)"
    }
    
    var hashValue: Int {
        return self.cookieA.hashValue ^ self.cookieB.hashValue
    }
}

func ==(lhs: Swap, rhs: Swap) -> Bool {
    return (lhs.cookieA == rhs.cookieA && lhs.cookieB == rhs.cookieB)
            || (lhs.cookieB == rhs.cookieA && lhs.cookieA == rhs.cookieB)
    
}