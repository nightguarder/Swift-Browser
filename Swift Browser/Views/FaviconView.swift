//
//  FaviconView.swift
//  Swift Browser
//
//  Created by opencode on 06/02/26.
//

import SwiftUI

public struct FaviconView: View {
    let urlString: String
    let title: String
    var size: CGFloat = 18

    public init(urlString: String, title: String, size: CGFloat = 18) {
        self.urlString = urlString
        self.title = title
        self.size = size
    }

    public var body: some View {
        Group {
            if urlString.isEmpty {
                fallback(systemName: "house")
            } else if urlString == "swiftbrowser://settings" {
                fallback(systemName: "gearshape")
            } else if urlString == "swiftbrowser://history" {
                fallback(systemName: "clock")
            } else if urlString == "swiftbrowser://bookmarks" {
                fallback(systemName: "bookmark")
            } else if urlString == "swiftbrowser://shortcuts" {
                fallback(systemName: "keyboard")
            } else if urlString.hasPrefix("swiftbrowser://") {
                fallback(systemName: "doc")
            } else if let url = URL(string: urlString), let host = url.host {
                let scheme = url.scheme ?? "https"
                let favicon = URL(string: "\(scheme)://\(host)/favicon.ico")
                faviconView(url: favicon)
            } else {
                fallback(systemName: "globe")
            }
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private func faviconView(url: URL?) -> some View {
        if #available(macOS 12.0, *), let url {
            AsyncImage(url: url, transaction: Transaction(animation: .none)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: size * 0.15))
                default:
                    fallback(systemName: "globe")
                }
            }
        } else {
            fallback(systemName: "globe")
        }
    }

    private func fallback(systemName: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(Color.primary.opacity(0.06))
            Image(systemName: systemName)
                .font(.system(size: size * 0.6, weight: .regular))
                .foregroundColor(.secondary)
        }
    }
}
