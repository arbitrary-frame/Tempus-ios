//
//  EmojiIconPicker.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI

/// Inline emoji icon picker - tap to open native emoji keyboard
struct EmojiIconPicker: View {
    @Binding var selectedEmoji: String?
    @State private var emojiText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        Button {
            isFocused = true
        } label: {
            ZStack {
                // Display selected emoji or placeholder icon
                if let emoji = selectedEmoji, !emoji.isEmpty {
                    Text(emoji)
                        .font(.title2)
                } else {
                    Image(systemName: "face.smiling")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                // Hidden TextField for emoji input
                TextField("", text: $emojiText)
                    .focused($isFocused)
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
                    .onChange(of: emojiText) { oldValue, newValue in
                        // Extract only emoji characters (filter out non-emoji)
                        let emojis = newValue.filter { $0.isEmoji }
                        if let firstEmoji = emojis.first {
                            selectedEmoji = String(firstEmoji)
                            emojiText = ""
                            isFocused = false
                            HapticManager.shared.trigger(.selection)
                        }
                    }
            }
        }
        .frame(width: 44, height: 44)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .contextMenu {
            if selectedEmoji != nil {
                Button(role: .destructive) {
                    selectedEmoji = nil
                    HapticManager.shared.trigger(.light)
                } label: {
                    Label("Remove Emoji", systemImage: "trash")
                }
            }
        }
    }
}

// Helper extension to detect emoji characters
extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
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