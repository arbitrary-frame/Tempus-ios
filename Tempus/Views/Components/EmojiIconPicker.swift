//
//  EmojiIconPicker.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI

/// Inline emoji icon picker - tap to open emoji selection sheet
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
        .sheet(isPresented: $showingPicker) {
            EmojiPickerSheet(selectedEmoji: $selectedEmoji)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
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

/// Full emoji picker sheet with categories
struct EmojiPickerSheet: View {
    @Binding var selectedEmoji: String?
    @Environment(\.dismiss) private var dismiss
    @State private var showingSkinTones: String? = nil

    // Skin tone modifiers
    private let skinToneModifiers = ["", "🏻", "🏼", "🏽", "🏾", "🏿"]

    // Emojis that support skin tone variations
    private let skinToneSupported: Set<String> = [
        "👋", "🤚", "🖐️", "✋", "🖖", "👌", "🤌", "🤏", "✌️", "🤞", "🤟", "🤘",
        "🤙", "👈", "👉", "👆", "🖕", "👇", "☝️", "👍", "👎", "✊", "👊", "🤛",
        "🤜", "👏", "🙌", "👐", "🤲", "🤝", "🙏", "✍️", "💅", "🤳", "💪", "🦵",
        "🦶", "👂", "🦻", "👃", "👶", "👧", "🧒", "👦", "👩", "🧑", "👨", "👩‍🦱",
        "🧑‍🦱", "👨‍🦱", "👩‍🦰", "🧑‍🦰", "👨‍🦰", "👱‍♀️", "👱", "👱‍♂️", "👩‍🦳", "🧑‍🦳",
        "👨‍🦳", "👩‍🦲", "🧑‍🦲", "👨‍🦲", "🧔‍♀️", "🧔", "🧔‍♂️", "🏋️", "🏋️‍♀️", "🏋️‍♂️",
        "🤸", "🤸‍♀️", "🤸‍♂️", "🤾", "🤾‍♀️", "🤾‍♂️", "🏃", "🏃‍♀️", "🏃‍♂️", "🚴",
        "🚴‍♀️", "🚴‍♂️", "🏊", "🏊‍♀️", "🏊‍♂️", "🧘", "🧘‍♀️", "🧘‍♂️", "🧗", "🧗‍♀️", "🧗‍♂️"
    ]

    // Comprehensive emoji collection organized by category
    private let emojiCategories: [(String, String, [String])] = [
        ("💪", "Fitness", ["💪", "🏋️", "🏋️‍♀️", "🏋️‍♂️", "🤸", "🤸‍♀️", "🤸‍♂️", "🤾", "🤾‍♀️", "🤾‍♂️", "🏃", "🏃‍♀️", "🏃‍♂️", "🚴", "🚴‍♀️", "🚴‍♂️", "🏊", "🏊‍♀️", "🏊‍♂️", "🧘", "🧘‍♀️", "🧘‍♂️", "🧗", "🧗‍♀️", "🧗‍♂️", "🤺", "🥊", "🥋", "⛷️", "🏂"]),
        ("🦵", "Body Parts", ["🦵", "🦶", "👣", "🦴", "💪", "🦾", "🫀", "🫁", "🧠", "🦷", "👁️", "👀", "👂", "🦻", "👃", "👄", "🫦", "👅", "🤳", "💅", "🤲", "👐", "🙌", "👏", "🤝", "👍", "👎", "👊", "✊", "🤛", "🤜", "🤞", "✌️", "🤟", "🤘", "👌", "🤌", "🤏", "🫰", "🫱", "🫲", "🫳", "🫴", "🫷", "🫸", "👋", "🤚", "🖐️", "✋", "🖖"]),
        ("🔥", "Symbols", ["🔥", "⚡️", "💯", "🎯", "⭐️", "✨", "💥", "✅", "❌", "🚀", "📈", "📊", "⏰", "⏱️", "⏲️", "🎵", "🎶", "💊", "🧠", "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔"]),
        ("🏆", "Achievement", ["🏆", "🥇", "🥈", "🥉", "🏅", "🎖️", "👑", "💎", "🔱", "⚔️", "🛡️", "🎯", "📈", "✅", "💯", "⚡️", "🔥", "💪", "👊", "✊", "🤜", "🤛", "👏"]),
        ("⚽️", "Sports", ["⚽️", "🏀", "🏈", "⚾️", "🥎", "🎾", "🏐", "🏉", "🥏", "🎱", "🪀", "🏓", "🏸", "🏒", "🏑", "🥍", "🏏", "🪃", "🥅", "⛳️", "🪁", "🏹", "🎣", "🤿", "🥊", "🥋", "🎽", "🛹", "🛼", "🛷"]),
        ("🍎", "Food", ["🍎", "🥗", "🥑", "🥦", "🥒", "🌽", "🥕", "🧄", "🧅", "🍇", "🍊", "🍋", "🍌", "🍉", "🍓", "🫐", "🍒", "🍑", "🥭", "🍍", "🥥", "🥝", "🍅", "🍆", "🥔", "🥐", "🥖", "🧀", "🥚"]),
        ("😀", "Faces", ["😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂", "🙂", "🙃", "🫠", "😉", "😊", "😇", "🥰", "😍", "🤩", "😘", "😗", "😚", "😙", "🥲", "😋", "😛", "😜", "🤪", "😝", "🤑", "🤗", "🤭"]),
        ("🐶", "Animals", ["🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯", "🦁", "🐮", "🐷", "🐸", "🐵", "🐔", "🐧", "🐦", "🐤", "🦆", "🦅", "🦉", "🦇", "🐺", "🐗", "🐴", "🦄", "🐝", "🪱", "🐛"]),
        ("🌈", "Nature", ["🌈", "☀️", "🌤️", "⛅️", "🌥️", "☁️", "🌦️", "🌧️", "⛈️", "🌩️", "🌨️", "❄️", "☃️", "⛄️", "🌬️", "💨", "🌪️", "🌫️", "☔️", "💧", "💦", "🌊", "🌍", "🌎", "🌏", "🪐", "⭐️", "🌟", "✨", "💫"]),
        ("🎮", "Activities", ["🎮", "🕹️", "👾", "🎯", "🎲", "🎰", "🎳", "🎴", "🃏", "🎭", "🎨", "🧩", "🎪", "🎡", "🎢", "🎠", "🎬", "🎤", "🎧", "🎼", "🎹", "🥁", "🎷", "🎺", "🎸", "🪕", "🎻", "🎲", "♟️", "🎯"]),
    ]

    private let columns = Array(repeating: GridItem(.adaptive(minimum: 44), spacing: 12), count: 8)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(emojiCategories, id: \.1) { (icon, category, emojis) in
                        if !emojis.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Text(icon)
                                        .font(.title3)
                                    Text(category)
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal)

                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(emojis, id: \.self) { emoji in
                                        let baseEmoji = getBaseEmoji(emoji)
                                        let supportsSkinTone = skinToneSupported.contains(baseEmoji)

                                        Button {
                                            selectedEmoji = emoji
                                            HapticManager.shared.trigger(.selection)
                                            dismiss()
                                        } label: {
                                            Text(emoji)
                                                .font(.system(size: 32))
                                                .frame(width: 44, height: 44)
                                                .background(
                                                    selectedEmoji == emoji ? Color.accentColor.opacity(0.2) : Color.clear,
                                                    in: RoundedRectangle(cornerRadius: 8)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                        .contextMenu {
                                            if supportsSkinTone {
                                                ForEach(skinToneModifiers, id: \.self) { modifier in
                                                    let modifiedEmoji = modifier.isEmpty ? baseEmoji : baseEmoji + modifier
                                                    Button {
                                                        selectedEmoji = modifiedEmoji
                                                        HapticManager.shared.trigger(.selection)
                                                        dismiss()
                                                    } label: {
                                                        Text(modifiedEmoji)
                                                            .font(.system(size: 24))
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Choose Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if selectedEmoji != nil {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Remove", role: .destructive) {
                            selectedEmoji = nil
                            HapticManager.shared.trigger(.light)
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    // Helper function to strip skin tone modifiers from emoji
    private func getBaseEmoji(_ emoji: String) -> String {
        // Remove all skin tone modifiers to get base emoji
        let skinTones: [String] = ["🏻", "🏼", "🏽", "🏾", "🏿"]
        var result = emoji
        for tone in skinTones {
            result = result.replacingOccurrences(of: tone, with: "")
        }
        return result
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