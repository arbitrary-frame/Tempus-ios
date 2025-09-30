//
//  EmojiIconPicker.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI

/// Inline emoji icon picker - tap to open emoji selection popover
struct EmojiIconPicker: View {
    @Binding var selectedEmoji: String?
    @State private var showingPicker = false

    var body: some View {
        Button {
            showingPicker = true
        } label: {
            if let emoji = selectedEmoji, !emoji.isEmpty {
                Text(emoji)
                    .font(.title2)
            } else {
                Image(systemName: "face.smiling")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 44, height: 44)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .popover(isPresented: $showingPicker, arrowEdge: .bottom) {
            EmojiSelectionGrid(selectedEmoji: $selectedEmoji, dismiss: { showingPicker = false })
        }
    }
}

/// Compact emoji selection grid shown in popover
struct EmojiSelectionGrid: View {
    @Binding var selectedEmoji: String?
    let dismiss: () -> Void

    // Curated workout emojis
    private let emojis = [
        "💪", "🏋️", "🔥", "⚡️", "💯", "🎯",
        "🏃", "🚴", "🏊", "🤸", "🧘", "🥊",
        "⚽️", "🏀", "🎾", "🏐", "⛷️", "🧗",
        "❤️", "⭐️", "✨", "🏆", "🥇", "📈",
        "⏰", "✅", "🎵", "🥗", "💊", "🧠"
    ]

    private let columns = Array(repeating: GridItem(.fixed(44), spacing: 8), count: 6)

    var body: some View {
        VStack(spacing: 0) {
            // Header with remove option
            HStack {
                Text("Choose Icon")
                    .font(.headline)
                    .padding()

                Spacer()

                if selectedEmoji != nil {
                    Button {
                        selectedEmoji = nil
                        dismiss()
                    } label: {
                        Text("Remove")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                    .padding()
                }
            }

            Divider()

            // Emoji grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(emojis, id: \.self) { emoji in
                    Button {
                        selectedEmoji = emoji
                        dismiss()
                    } label: {
                        Text(emoji)
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(
                                selectedEmoji == emoji ? Color.accent.opacity(0.2) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 6)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .frame(width: 300, height: 280)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var emoji: String? = "💪"

        var body: some View {
            VStack {
                EmojiIconPicker(selectedEmoji: $emoji)
                Text(emoji ?? "None")
            }
        }
    }

    return PreviewWrapper()
}