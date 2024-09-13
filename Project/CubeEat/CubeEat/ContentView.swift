import SwiftUI
import GameKit

struct ContentView: View {
    @Bindable var matchMaker = GameManagement()

    var body: some View {
        VStack {
            Text("Hello, \(matchMaker.localPlayer.displayName)!")
                .font(.largeTitle)
            
            ZStack {
                // Jogador Local (Player)
                if let player = matchMaker.playerSelection {
                    PlayerView(player: player)
                }
                
                // Outro jogador (Opponent)
                if let otherPlayer = matchMaker.otherPlayerSelection {
                    PlayerView(player: otherPlayer)
                }
            }
            
            Spacer()

            HStack {
                Button("Left") {
                    movePlayer(direction: .left)
                }
                Button("Up") {
                    movePlayer(direction: .up)
                }
                Button("Down") {
                    movePlayer(direction: .down)
                }
                Button("Right") {
                    movePlayer(direction: .right)
                }
            }
            
            Button("Game Center") {
                matchMaker.sendInvite()
            }
        }
        .padding()
    }

    func movePlayer(direction: Direction) {
        guard let player = matchMaker.playerSelection else { return }

        let moveAmount: CGFloat = 10 // Define o quanto o jogador se move em cada ação
        var newPosition = player.position

        switch direction {
        case .up:
            newPosition.y -= moveAmount
        case .down:
            newPosition.y += moveAmount
        case .left:
            newPosition.x -= moveAmount
        case .right:
            newPosition.x += moveAmount
        }

        // Atualizar a posição do jogador local e enviar a nova posição
        matchMaker.playerSelection?.position = newPosition
        matchMaker.sendPosition(position: newPosition)
    }
}


#Preview {
    ContentView()
}
