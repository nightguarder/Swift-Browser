import SwiftUI
import Combine

import SwiftUI
import Combine

struct LockedView: View {
    @ObservedObject var spaceManager = SpaceManager.shared
    @State private var isAuthenticating = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "lock.shield")
                .font(.system(size: 80, weight: .ultraLight))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Swift Browser")
                    .font(.system(size: 28, weight: .semibold))
                
                Text("Your data is encrypted")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.bottom, 8)
            }
            
            Button(action: unlock) {
                HStack(spacing: 8) {
                    if isAuthenticating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "lock.open")
                    }
                    Text("Unlock")
                }
                .frame(width: 200, height: 44)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(isAuthenticating)
            
            Spacer()
                .frame(height: 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func unlock() {
        isAuthenticating = true
        errorMessage = nil
        
        Task {
            do {
                let key = try KeychainManager.shared.retrieveKey()
                CookiePersistenceManager.shared.setEncryptionKey(key)
                
                await MainActor.run {
                    spaceManager.unlock()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to unlock: \(error.localizedDescription)"
                    isAuthenticating = false
                }
            }
        }
    }
}
