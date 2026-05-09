import SwiftUI

struct FireButton: View {
    @State private var showConfirmation = false
    @State private var isBurning = false

    var body: some View {
        Button(action: { showConfirmation = true }) {
            Image(systemName: "flame.fill")
                .font(AppFont.icon)
                .foregroundStyle(isBurning ? .orange : .secondary)
        }
        .buttonStyle(.plain)
        .disabled(isBurning)
        .alert("Clear All Data?", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Burn", role: .destructive) {
                isBurning = true
                StorageManager.shared.burnAll {
                    isBurning = false
                }
            }
        } message: {
            Text("This will clear cookies, cache, and site data for all spaces. Fireproofed domains will be preserved.")
        }
    }
}
