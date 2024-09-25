//
//  MMMatchData.swift
//  CubeEatForIos
//
//  Created by Jairo Júnior on 24/09/24.
//

import Foundation
import GameKit
import SwiftUI

extension MultiplayerManager {
    
    // MARK: Codable Game Data
    
    /// Creates a data representation of the local player's score for sending to other players.
    ///
    /// - Returns: A representation of game data that contains only the score.
    func encode(score: Int) -> Data? {
        let gameData = GameData(matchName: matchName, playerName: GKLocalPlayer.local.displayName, score: score, message: nil, outcome: nil)
        return encode(gameData: gameData)
    }
    
    /// Creates a data representation of game data for sending to other players.
    ///
    /// - Returns: A representation of game data.
    func encode(gameData: GameData) -> Data? {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        
        do {
            let data = try encoder.encode(gameData)
            return data
        } catch {
            print("Error: \(error.localizedDescription).")
            return nil
        }
    }
    
    /// Decodes a data representation of match data from another player.
    ///
    /// - Parameter matchData: A data representation of the game data.
    /// - Returns: A game data object.
    func decode(matchData: Data) -> GameData? {
        // Convert the data object to a game data object.
        return try? PropertyListDecoder().decode(GameData.self, from: matchData)
    }
}
