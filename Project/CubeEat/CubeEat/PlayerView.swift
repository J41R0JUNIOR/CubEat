//
//  PlayerView.swift
//  CubeEat
//
//  Created by Jairo Júnior on 13/09/24.
//

import SwiftUI


struct PlayerView: View {
    var player: Player

    var body: some View {
        // Mostra um quadrado ou triângulo baseado no papel do jogador
        if player.role == .playerSQUARE {
            Rectangle()
                .frame(width: 100, height: 100)
                .position(player.position)
                .foregroundColor(.blue)
                .onAppear {
                    print("opa")
                }
        } else if player.role == .playerTRIANGLE {
            Triangle()
                .frame(width: 100, height: 100)
                .position(player.position)
                .foregroundColor(.red)
                .onAppear {
                    print("epa")
                }
        }
    }
}

enum Direction {
    case up
    case down
    case left
    case right
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}
