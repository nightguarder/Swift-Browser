import Foundation
import SwiftUI

public struct Space: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var icon: String
    public var colorName: String
    public var isPrivate: Bool
    public var dataStoreIdentifier: UUID?
    public var blockAllCookies: Bool
    
    public init(id: UUID = UUID(), 
                name: String, 
                icon: String, 
                colorName: String = "AccentColor", 
                isPrivate: Bool = false, 
                dataStoreIdentifier: UUID? = nil,
                blockAllCookies: Bool? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorName = colorName
        self.isPrivate = isPrivate
        self.dataStoreIdentifier = dataStoreIdentifier
        self.blockAllCookies = blockAllCookies ?? isPrivate
    }
    
    public var color: Color {
        switch colorName.lowercased() {
        case "purple":
            return .purple
        case "orange":
            return .orange
        case "blue":
            return .blue
        case "accentcolor":
            return .accentColor
        case "red":
            return .red
        case "green":
            return .green
        case "yellow":
            return .yellow
        case "pink":
            return .pink
        case "cyan":
            return .cyan
        case "indigo":
            return .indigo
        case "teal":
            return .teal
        case "mint":
            return .mint
        case "brown":
            return .brown
        case "gray", "grey":
            return .gray
        default:
            return .accentColor
        }
    }
}
