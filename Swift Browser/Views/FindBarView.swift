import SwiftUI

public struct FindBarView: View {
    @ObservedObject var manager: FindInPageManager
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onClose: () -> Void
    
    @FocusState private var isFocused: Bool
    
    public init(manager: FindInPageManager, onNext: @escaping () -> Void, onPrevious: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.manager = manager
        self.onNext = onNext
        self.onPrevious = onPrevious
        self.onClose = onClose
    }
    
    public var body: some View {
        HStack {
            TextField("Find in page...", text: $manager.searchText)
                .textFieldStyle(.plain)
                .frame(width: 200)
                .focused($isFocused)
                .onSubmit {
                    onNext()
                }
                .onAppear {
                    isFocused = true
                }
                .onKeyPress(.escape) {
                    onClose()
                    return .handled
                }
            
            if manager.totalResults > 0 {
                Text("\(manager.currentResult)/\(manager.totalResults)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)
            
            Button(action: onNext) {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
            
            Divider()
                .frame(height: 16)
            
            Button(action: onClose) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
        }
        .padding(8)
        .background(.regularMaterial)
        .cornerRadius(8)
        .shadow(radius: 2)
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
    }
}
