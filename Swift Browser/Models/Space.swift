import Foundation
import SwiftUI

public struct Space: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var icon: String
    public var colorName: String
    public var isPrivate: Bool
    public var dataStoreIdentifier: UUID?
    
    public init(id: UUID = UUID(), 
                name: String, 
                icon: String, 
                colorName: String = "AccentColor", 
                isPrivate: Bool = false, 
                dataStoreIdentifier: UUID? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorName = colorName
        self.isPrivate = isPrivate
        self.dataStoreIdentifier = dataStoreIdentifier
    }
    
    public var color: Color {
        Color(colorName)
    }
}
