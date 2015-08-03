//
//  Level.seift.swift
//  CookieCrunch
//
//  Created by Dante on 15/7/31.
//  Copyright (c) 2015年 Futurelab. All rights reserved.
//

import Foundation

let NumColumns = 9
let NumRows = 9

class Level {
    private var cookies = Array2D<Cookie>(columns: NumColumns, rows: NumRows)
    private var tiles = Array2D<Tile>(columns: NumColumns, rows: NumRows)
    private var possibleSwaps = Set<Swap>()
    
    var targetScore = 0
    var maximumMoves = 0
    var comboMultipler = 0
    
    init(filename: String) {
        if let dictionary =
            Dictionary<String, AnyObject>.loadJSONFromBundle(filename) {
            if let tilesArray: AnyObject = dictionary["tiles"] {
                for (row, rowArray) in enumerate(tilesArray as! [[Int]]) {
                    let tileRow = NumRows - row - 1
                    
                    for (column, value) in enumerate(rowArray) {
                        if value == 1 {
                            tiles[column, row] = Tile()
                        }
                    }
                }
                self.targetScore = dictionary["targetScore"] as! Int
                self.maximumMoves = dictionary["moves"] as! Int
            }
        }
    }
    
    func cookieAtColumn(column: Int, row: Int) -> Cookie? {
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row <= NumRows)
        
        return cookies[column, row]
    }
    
    func tileAtColumn(column: Int, row: Int) -> Tile? {
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row <= NumRows)
        
        return tiles[column, row]
    }
    
    func shuffle() -> Set<Cookie> {
        var cookies: Set<Cookie>
        do {
            cookies = createInitialCookies()
            detectPossibleSwaps()
            println("possible swaps: \(possibleSwaps.count)")
        } while possibleSwaps.count == 0
        
        return cookies
    }
    
    func detectPossibleSwaps() {
        var set = Set<Swap>()
        
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if let cookie = cookieAtColumn(column, row: row) {
                    if column < NumColumns - 1 {
                        if let other = cookieAtColumn(column + 1, row:row) {
                            cookies[column + 1, row] = cookie
                            cookies[column, row] = other
                            
                            if hasChainAtColumn(column, row: row) ||
                                hasChainAtColumn(column + 1, row: row) {
                                    set.insert(Swap(cookieA: cookie, cookieB: other))
                            }
                            
                            cookies[column + 1, row] = other
                            cookies[column, row] = cookie
                        }
                    }
                    
                    if row < NumRows - 1 {
                        if let other = cookieAtColumn(column, row: row + 1) {
                            cookies[column, row + 1] = cookie
                            cookies[column, row] = other
                            
                            if hasChainAtColumn(column, row: row + 1) || hasChainAtColumn(column, row: row) {
                                set.insert(Swap(cookieA: cookie, cookieB: other))
                            }
                            
                            cookies[column, row + 1] = other
                            cookies[column, row] = cookie
                        }
                    }
                }
            }
        }
        
        possibleSwaps = set
    }
    
    func performSwap(swap: Swap) {
        cookies[swap.cookieA.column, swap.cookieA.row] = swap.cookieB
        cookies[swap.cookieB.column, swap.cookieB.row] = swap.cookieA
        
        var tmp = swap.cookieA.column
        swap.cookieA.column = swap.cookieB.column
        swap.cookieB.column = tmp
        
        tmp = swap.cookieA.row
        swap.cookieA.row = swap.cookieB.row
        swap.cookieB.row = tmp
    }
    
    func isPossibleSwap(swap:Swap) -> Bool {
        return possibleSwaps.contains(swap)
    }
    
    func removeMatches() -> Set<Chain> {
        let horizontalChains = detectHorizontalMatches()
        let verticalChains = detectVerticalMatches()
        
        removeCookies(horizontalChains)
        removeCookies(verticalChains)
        
        calculateScores(horizontalChains)
        calculateScores(verticalChains)
        
        return horizontalChains.union(verticalChains)
    }
    
    func fillHoles() -> [[Cookie]] {
        var columns = [[Cookie]]()
        
        for column in 0..<NumColumns {
            var array = [Cookie]()
            for row in 0..<NumRows {
                if tiles[column, row] != nil && cookies[column, row] == nil {
                    for lookup in (row + 1)..<NumRows {
                        if let cookie = cookies[column, lookup] {
                            cookies[column, lookup] = nil
                            cookies[column, row] = cookie
                            cookie.row = row
                            array.append(cookie)
                            break
                        }
                    }
                }
            }
            
            if !array.isEmpty {
                columns.append(array)
            }
        }
        
        return columns
    }
    
    func topUpCookies() -> [[Cookie]] {
        var columns = [[Cookie]]()
        var lastCookieType: CookieType = .Unkown
        
        for column in 0..<NumColumns {
            var array = [Cookie]()
            lastCookieType = .Unkown
            for var row = NumRows - 1; row >= 0 && cookies[column, row] == nil; --row {
                if tiles[column, row] != nil {
                    var newCookieType: CookieType = .Unkown
                    do {
                        newCookieType = CookieType.random()
                    }
                    while newCookieType == lastCookieType
                    
                    let cookie = Cookie(column: column, row: row, cookieType: newCookieType)
                    lastCookieType = newCookieType
                    cookies[column, row] = cookie
                    
                    array.append(cookie)
                }
            }
            
            if !array.isEmpty {
                columns.append(array)
            }
        }
        
        return columns
    }
    
    func resetComboMultipler() {
        comboMultipler = 1
    }
    
    private func createInitialCookies() -> Set<Cookie> {
        var set = Set<Cookie>()
        
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if tiles[column, row] != nil {
                    var cookieType: CookieType
                    
                    do{
                        cookieType = CookieType.random()
                    }
                    while (column >= 2
                            && cookies[column - 1, row]?.cookieType == cookieType
                            && cookies[column - 2, row]?.cookieType == cookieType)
                        || (row >= 2
                            && cookies[column, row - 1]?.cookieType == cookieType
                            && cookies[column, row - 2]?.cookieType == cookieType)
                    
                    
                    let cookie = Cookie(column: column, row: row, cookieType: cookieType)
                    cookies[column, row] = cookie
                    
                    set.insert(cookie)
                }
            }
        }

        return set
    }
    
    private func hasChainAtColumn(column: Int, row: Int) -> Bool {
        let cookieType = cookieAtColumn(column, row: row)?.cookieType
        
        var horzLength = 1
        for var i = column - 1; i >= 0 && cookies[i, row]?.cookieType == cookieType; --i, ++horzLength {}
        for var i = column + 1; i < NumColumns && cookies[i, row]?.cookieType == cookieType; ++i, ++horzLength {}
        
        if horzLength >= 3 { return true }
        
        var vertLength = 1
        for var i = row - 1; i >= 0 && cookies[column, i]?.cookieType == cookieType; --i, ++vertLength {}
        for var i = row + 1; i < NumRows && cookies[column, i]?.cookieType == cookieType; ++i, ++vertLength {}
        
        return vertLength >= 3
    }
    
    private func detectHorizontalMatches() -> Set<Chain> {
        var result = Set<Chain>()
        
        for row in 0..<NumRows {
            for var column = 0; column < NumColumns - 2;  {
                if let cookie = cookieAtColumn(column, row: row) {
                    let matchType = cookie.cookieType
                    
                    if cookieAtColumn(column + 1, row: row)?.cookieType == matchType && cookieAtColumn(column + 2, row: row)?.cookieType == matchType {
                        
                        let chain = Chain(chainType: .Horizontal)

                        do {
                            chain.addCookie(cookies[column, row]!)
                            ++column
                        }
                        while column < NumColumns &&  cookieAtColumn(column, row: row)?.cookieType == matchType
                        
                        result.insert(chain)
                        continue
                    }
                }
                
                ++column
            }
        }
        
        return result
    }
    
    private func detectVerticalMatches() -> Set<Chain> {
        var result = Set<Chain>()
        
        for column in 0..<NumColumns {
            for var row = 0; row < NumRows - 2; {
                if let cookie = cookieAtColumn(column, row: row) {
                    let matchType = cookie.cookieType
                    
                    if cookieAtColumn(column, row: row + 1)?.cookieType == matchType && cookieAtColumn(column, row: row + 2)?.cookieType == matchType {
                        
                        let chain = Chain(chainType: .Vertical)
                        
                        do {
                            chain.addCookie(cookies[column, row]!)
                            ++row
                        }
                        while row < NumRows && cookieAtColumn(column, row: row)?.cookieType == matchType
                        
                        result.insert(chain)
                        continue
                    }
                }
                ++row
            }
        }
        
        return result
    }
    
    private func removeCookies(chains: Set<Chain>) {
        for chain in chains {
            for cookie in chain.cookies {
                cookies[cookie.column, cookie.row] = nil
            }
        }
    }
    
    private func calculateScores(chains: Set<Chain>) {
        for chain in chains {
            chain.score = (chain.length - 2) * 60 * comboMultipler
            ++comboMultipler
        }
    }
}