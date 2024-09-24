//
//  ContentView.swift
//  CubeEatForIos
//
//  Created by Jairo Júnior on 23/09/24.
//

import SwiftUI
import GameKit

struct ContentView: View {
    @Bindable var game = MultiplayerManager()
    var body: some View {
        VStack {
            if !game.playingGame {
                JoinGameView(game: game)
                
            }else{
                GameView(game: game)
                
            }
        }
        // Authenticate the local player when the game first launches.
        .onAppear {
            if !game.playingGame {
                game.authenticatePlayer()
            }
        }
    }
}

#Preview {
    ContentView()
}
