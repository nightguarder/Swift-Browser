//
//  SplashScreen.swift
//  Swift Browser
//
//  Created by Nightguarder on 02/02/26.
//

import SwiftUI

struct SplashScreen: View {
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.indigo, Color.cyan]), // Changed colors
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "swift") // Changed icon to swift logo
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100) // Slightly smaller
                    .foregroundStyle(.white)
                    .scaleEffect(scale)
                    .opacity(opacity)

                Text("Swift Browser")
                    .font(.system(size: 32, weight: .bold, design: .rounded)) // Larger font
                    .foregroundColor(.white)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) { // Slower, bouncier animation
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
