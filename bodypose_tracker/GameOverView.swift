//
//  GameOverView.swift
//  bodypose_tracker
//
//  Created by Chuah Cheng Hang on 8/9/25.
//

import SwiftUI

struct GameOverView: View {
    @Binding var gameOver: Bool
    var body: some View {
        Text("Game Over")
            .font(.largeTitle)
            .bold()
            .padding()
        Button {
            gameOver = false
        }label: {
            Text("Try Again")
        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    GameOverView(gameOver: .constant(false))
}
