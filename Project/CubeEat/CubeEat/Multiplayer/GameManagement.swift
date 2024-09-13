import Foundation
import GameKit
import SwiftUI
import AppKit
import Combine

enum PlayerAuthState {
    case unauthenticated
    case authenticated
    case restricted
}




enum GameAuthState {
    case outGame
    case inPreGame
    case inGame
    case gameReady
}

enum GameMessage: Codable {
    // game controls
    case position(CGPoint)
    case gameTime(TimeInterval)
    
    case goToGame
    case startGame
    case endGame(Player.PlayerRole?)
    case resetGame
    
    // role selection
    case playerRole(Player.PlayerRole?)
    
    // timer
    case timer(Int)
    
    
    // encode and decode the message into / from Data
    func encode() -> Data? {
        try? JSONEncoder().encode(self)
    }
    
    static func decode(from data: Data) -> GameMessage? {
        try? JSONDecoder().decode(GameMessage.self, from: data)
    }
}

struct Player: Identifiable, Codable {
    var id: UUID = UUID()
    var displayName: String
    var isHost: Bool = false
    var role: PlayerRole? = nil
    var position: CGPoint = .zero
    
    enum PlayerRole: String, Codable {
        case playerSQUARE
        case playerTRIANGLE
    }
}

@Observable
class GameManagement: NSObject, GKLocalPlayerListener {
    
    var isAuthenticated = false
    var authenticationError: String?
    var localPlayer: GKLocalPlayer = .init()
    var playerAuthState: PlayerAuthState = .unauthenticated
    var isCommunicationAllowed = false
    var currentInvite: GKInvite?
    var match: GKMatch?
//    var playerSelection: Player?
//    var otherPlayerSelection: Player?
    
    var playerSelection: Player? = Player(displayName: "Player 1", isHost: true, role: .playerSQUARE, position: CGPoint(x: 600, y: 200))
      var otherPlayerSelection: Player? = Player(displayName: "Player 2", isHost: false, role: .playerTRIANGLE, position: CGPoint(x: 900, y: 400))
      
    
    var otherPlayer: GKPlayer?
    var gameState: GameAuthState = .outGame
    
    
    var gameTimer: AnyCancellable?
    var currentTime: TimeInterval = 0
    
    var countdownTimer: Cancellable?
    var remainingTime = 20 { // This is the variable that is going to be shared
        willSet {
            if playerSelection!.isHost {
                sendGameMessage(.timer(newValue))
            } // every sec
        }
    }
    
    var rootViewController: NSViewController? {
        guard let keyWindow = NSApplication.shared.windows.first else {
            return nil
        }
        return keyWindow.contentViewController
    }

    override init(){
        super.init()
        self.authenticatePlayer()
    }
    
    func authenticatePlayer() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self = self else { return }
            
            self.localPlayer = GKLocalPlayer.local
            
            if let viewController = viewController {
                self.rootViewController?.presentAsModalWindow(viewController)
            } else if localPlayer.isAuthenticated {
                self.isAuthenticated = true
                self.playerAuthState = .authenticated
                print("Jogador autenticado com sucesso!")
               
            } else if let error = error {
                self.isAuthenticated = false
                self.authenticationError = error.localizedDescription
                self.playerAuthState = .unauthenticated
                print("Erro ao autenticar: \(error.localizedDescription)")
            } else {
                self.playerAuthState = .unauthenticated
                print("Não autenticado e sem erro específico.")
            }
        }
    }

    
    func sendInvite() {
        let request = GKMatchRequest()
        request.maxPlayers = 2
        request.minPlayers = 2
        
        if let matchmakerVC = GKMatchmakerViewController(matchRequest: request) {
            matchmakerVC.matchmakerDelegate = self
            rootViewController?.presentAsModalWindow(matchmakerVC)
        }
    }
    
    func startMatchmaking(withInvite invite: GKInvite? = nil) {
        guard localPlayer.isAuthenticated else { return }
        currentInvite = invite
        if let invite = invite, let matchmakerViewController = GKMatchmakerViewController(invite: invite) {
            matchmakerViewController.matchmakerDelegate = self
            rootViewController?.present(matchmakerViewController, animator: true as! NSViewControllerPresentationAnimator)
        }
    }
    
    func setRolesAndStartNewMatch(newMatch: GKMatch) {
        match = newMatch
        match?.delegate = self

        if currentInvite != nil {
            playerSelection = Player(displayName: localPlayer.displayName, isHost: true, role: .playerSQUARE)
        } else {
            playerSelection = Player(displayName: localPlayer.displayName, role: .playerTRIANGLE)
        }
        
        if playerSelection?.isHost == true {
            otherPlayerSelection = Player(displayName: match!.players.first!.displayName, role: .playerTRIANGLE)
        } else {
            otherPlayerSelection = Player(displayName: match!.players.first!.displayName, role: .playerSQUARE)
        }
        
        otherPlayer = match?.players.first
        gameState = .inPreGame
    }

    
    func sendGameMessage(_ message: GameMessage) {
        guard let data = message.encode() else { return }
        do {
            try match?.sendData(toAllPlayers: data, with: .reliable)
        } catch {
            print(error)
        }
    }
    
    
    
    func sendPosition(position: CGPoint) {
        guard match != nil, gameState == .inGame else { return }
        sendGameMessage(.position(position))
    }
    
    // MARK: - SYNCHRONIZED TIME
    func startGameTimer() {
        guard playerSelection?.isHost == true else { return }
        
        gameTimer = Timer.publish(every: 1/60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                self.currentTime += 1/60
                self.sendGameTime(self.currentTime)
                
                self.updatePlayerPosition()
            }
    }
    
    func sendGameTime(_ time: TimeInterval) {
        sendGameMessage(.gameTime(time))
    }
    
    func updatePlayerPosition() {
        let newPosition = calculateNewPosition(for: currentTime)
        sendPosition(position: newPosition)
    }
    
    func calculateNewPosition(for time: TimeInterval) -> CGPoint {
        return CGPoint(x: time * 10, y: time * 10)
    }
}


// MARK: - RECEIVE DATA
extension GameManagement: GKMatchDelegate {
    func match(_ match: GKMatch, didReceive data: Data, forRecipient recipient: GKPlayer, fromRemotePlayer player: GKPlayer) {
        if let gameMessage = GameMessage.decode(from: data) {
            DispatchQueue.main.async {
                switch gameMessage {
                case .position(let position):
                    // Atualiza a posição do outro jogador
                    self.otherPlayerSelection?.position = position
                case .gameTime(let time):
                    self.currentTime = time
                    self.syncGameTimer()
                case .goToGame:
                    self.gameState = .gameReady
                case .startGame:
                    self.gameState = .inGame
                case .endGame:
                    self.stopTimer()
                case .resetGame:
                    self.gameState = .gameReady
                case .playerRole(let role):
                    self.otherPlayerSelection!.role = role
                case .timer(let time):
                    self.remainingTime = time
                }
            }
        }
    }

    
    func syncGameTimer() {
        if playerSelection?.isHost == false {
            if gameTimer == nil {
                startGameTimer()
            }
        }
    }
}

// MARK: - Gerenciamento do Matchmaking
extension GameManagement: GKMatchmakerViewControllerDelegate {
    func player(_ player: GKPlayer, didAccept invite: GKInvite) {
        startMatchmaking(withInvite: invite)
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        viewController.dismiss(true)
        setRolesAndStartNewMatch(newMatch: match)
    }
    
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        viewController.dismiss(true)
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        viewController.dismiss(true)
        print("Matchmaker error: \(error.localizedDescription)")
    }
}

// TIMER
/// Controlled by the host
extension GameManagement {
    // Starts the timer
    func startTimer() {
        guard playerSelection?.isHost == true else { return }
        
        countdownTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.remainingTime -= 1
            }
    }
    
    // Stops the timer
    func stopTimer() {
        guard playerSelection?.isHost == true else { return }
        
        countdownTimer?.cancel()
    }
}
