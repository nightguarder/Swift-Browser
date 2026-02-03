//
//  WelcomeView.swift
//  Swift Browser
//
//  Created by Assistant on 02/03/26.
//

import SwiftUI

struct WelcomeView: View {
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore: Bool = false
    @Binding var showSplash: Bool
    @State private var inputName: String = ""
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.indigo, Color.cyan]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image(systemName: "swift")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.white)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                Text("Welcome to Swift Browser")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(opacity)
                
                Text("What should we call you?")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(opacity)
                
                VStack(spacing: 16) {
                    TextField("Your name", text: $inputName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.9))
                        )
                        .frame(width: 280)
                    
                    Button(action: {
                        userName = inputName.isEmpty ? "User" : inputName
                        hasLaunchedBefore = true
                        
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showSplash = true
                        }
                    }) {
                        Text("Get Started")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.indigo)
                            .frame(width: 280)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    WelcomeView(showSplash: .constant(false))
}