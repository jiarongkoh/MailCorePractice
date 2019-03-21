//
//  Utilities.swift
//  MailCorePractice
//
//  Created by Koh Jia Rong on 2019/2/22.
//  Copyright © 2019 Koh Jia Rong. All rights reserved.
//

import Foundation

class Utilities {
    
    // Returns length of LCS for X[0..m-1], Y[0..n-1]
    private static func lcSubstring(_ X : String  , _ Y : String  ) -> String {
        let m = X.count
        let n = Y.count
        
        var L = Array(repeating: Array(repeating: 0, count: n + 1 ) , count: m + 1)
        var result : (length : Int, iEnd : Int, jEnd : Int) = (0,0,0)
        // Following steps build L[m+1][n+1] in bottom up fashion. Note
        // that L[i][j] contains length of LCS of X[0..i-1] and Y[0..j-1]
        for i in stride(from: 0, through: m, by: 1)
        {
            for j in stride(from: 0, through: n, by: 1)
            {
                if i == 0 || j == 0
                {
                    L[i][j] = 0;
                }
                else if X[X.index( X.startIndex , offsetBy: (i - 1) )] == Y[Y.index( Y.startIndex , offsetBy: (j - 1) )]
                {
                    L[i][j] = L[i-1][j-1] + 1
                    
                    if result.0 < L[i][j]
                    {
                        result.length = L[i][j]
                        result.iEnd = i
                        result.jEnd = j
                    }
                }
                else
                {
                    L[i][j] = 0 //max(L[i-1][j], L[i][j-1])
                }
            }
            
        }
        
        let lcs = X.substring(with: X.index(X.startIndex, offsetBy: result.iEnd-result.length)..<X.index(X.startIndex, offsetBy: result.iEnd))
        
        // return the lcs
        return lcs
    }
    
    static func substringOf(_ strings : [String] ) -> String {
        var answer = strings[0] // For on string answer is itself
        
        for i in stride(from: 1, to: strings.count, by: 1) {
            answer = Utilities.lcSubstring(answer,strings[i])
        }
        return answer
    }
    
}
