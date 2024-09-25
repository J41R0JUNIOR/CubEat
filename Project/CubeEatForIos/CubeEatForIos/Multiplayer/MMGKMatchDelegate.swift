//
//  MMGKMatchDelegate.swift
//  CubeEatForIos
//
//  Created by Jairo Júnior on 24/09/24.
//

import Foundation
import GameKit
import SwiftUI

extension MultiplayerManager: GKMatchDelegate {
    /// Handles a connected, disconnected, or unknown player state.
    /// - Tag:didChange
    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        switch state {
        case .connected:
            print("\(player.displayName) Connected")
            
            // For automatch, set the opponent and load their avatar.
            if match.expectedPlayerCount == 0 {
                opponent = match.players[0]
                
            }
        case .disconnected:
            print("\(player.displayName) Disconnected")
        default:
            print("\(player.displayName) Connection Unknown")
        }
    }
    
    /// Handles an error during the matchmaking process.
    func match(_ match: GKMatch, didFailWithError error: Error?) {
        print("\n\nMatch object fails with error: \(error!.localizedDescription)")
    }

    /// Reinvites a player when they disconnect from the match.
    func match(_ match: GKMatch, shouldReinviteDisconnectedPlayer player: GKPlayer) -> Bool {
        return false
    }
    
    /// Handles receiving a message from another player.
    /// - Tag:didReceiveData
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        // Decode the data representation of the game data.
        let gameData = decode(matchData: data)
        
        if let score = gameData?.score {
            // Show the opponent's score.
            opponentScore = score
        }
    }
}
