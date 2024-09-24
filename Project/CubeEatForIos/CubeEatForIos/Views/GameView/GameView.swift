//
//  GameView.swift
//  CubeEatForIos
//
//  Created by Jairo Júnior on 24/09/24.
//

import SwiftUI

struct GameView: View {
    @Bindable var game: MultiplayerManager
    var body: some View {
        VStack{
            Text("You: \(game.myName) | Points:\(game.myScore)")
            
            Text("Opponent: \(game.opponentName) | Points:\(game.opponentScore)")
            
            HStack{
                Button("Add Score") {
                    game.takeAction(add: true)
                }.buttonStyle(.borderedProminent)
                
                Button("Remove Score") {
                    game.takeAction(add: false)
                }.buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    GameView(game: .init())
}
