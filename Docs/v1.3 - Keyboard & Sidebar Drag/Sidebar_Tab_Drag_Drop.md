# Sidebar Tab Drag and Drop

**Commit:** `458b98ef13b7e6ec21a56026cd7d81b6a57645f1`

## Feature

Added drag and drop functionality to reorder tabs in the sidebar.

## Implementation

### Simple Approach

Uses SwiftUI's native `.onDrag` and `.onDrop` modifiers with UUID-based data transfer:

```swift
.onDrag {
    NSItemProvider(object: tab.id.uuidString as NSString)
}
.onDrop(of: [.plainText]) { providers in
    // Load UUID and reorder tabs
}
```

### File Changes

#### 1. TabManager.swift
Added `moveTab(from:to:)` method:

```swift
public func moveTab(from sourceIndex: Int, to destinationIndex: Int) {
    guard sourceIndex >= 0 && sourceIndex < tabs.count,
          destinationIndex >= 0 && destinationIndex < tabs.count,
          sourceIndex != destinationIndex else { return }
    
    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
        let tab = tabs.remove(at: sourceIndex)
        tabs.insert(tab, at: destinationIndex)
    }
}
```

#### 2. SidebarView.swift

Created new `DraggableTabRow` component:

```swift
struct DraggableTabRow: View {
    let tab: BrowserTab
    let onMove: (UUID) -> Void
    
    var body: some View {
        // Tab row UI
        // ...
        .onDrag { NSItemProvider(object: tab.id.uuidString as NSString) }
        .onDrop(of: [.plainText]) { providers in
            // Handle drop and reorder
        }
    }
}
```

### Key Features

1. **Simple Implementation**: No visual feedback, dividers, or complex state management
2. **Space-Aware**: Drag and drop only works within the same space
3. **Smooth Animation**: Spring animation when tabs reorder
4. **Search Mode**: Disabled during tab search (when filtering)

### Usage

1. Click and hold any tab in the sidebar
2. Drag to desired position
3. Drop on another tab to swap positions

### Constraints

- Only works within the same space
- Disabled when search text is entered
- Works only when sidebar is expanded

## Technical Details

### Data Transfer
- Uses `NSItemProvider` with UUID string
- Transfers as plain text (`UTType.plainText`)
- Asynchronous loading with callback

### Index Conversion
Since tabs are filtered by space, the conversion between filtered and global indices:

```swift
private func handleTabMove(sourceID: UUID, targetID: UUID, spaceTabs: [BrowserTab]) {
    // Convert space-filtered indices to global tab array indices
    guard let globalSourceIndex = tabManager.tabs.firstIndex(where: { $0.id == sourceID }),
          let globalTargetIndex = tabManager.tabs.firstIndex(where: { $0.id == targetID }) else {
        return
    }
    
    tabManager.moveTab(from: globalSourceIndex, to: globalTargetIndex)
}
```

## Testing

1. Open multiple tabs in a space
2. Drag a tab to a new position
3. Verify tabs reorder with animation
4. Confirm drag doesn't work between different spaces
5. Verify search mode disables drag functionality
