//
//  NoGameView.swift
//  CubeEatForIos
//
//  Created by Jairo Júnior on 24/09/24.
//

import SwiftUI
import GameKit

struct JoinGameView: View {
    @Bindable var game: MultiplayerManager
    var body: some View {
        Button("Start Game"){
            if game.automatch {
                // Turn automatch off.
                GKMatchmaker.shared().cancel()
                game.automatch = false
            }
            game.choosePlayer()
        }.buttonStyle(.borderedProminent)
    }
}

#Preview {
    JoinGameView(game: MultiplayerManager())
}
