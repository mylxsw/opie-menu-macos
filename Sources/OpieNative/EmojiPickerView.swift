import SwiftUI

private struct EmojiGroup: Identifiable {
    let id: String
    let icon: String
    let entries: [(String, String)]
}

private let emojiGroups: [EmojiGroup] = [
    EmojiGroup(id: "Recent", icon: "clock", entries: [
        ("🤩", "star eyes"), ("🥳", "party"), ("📍", "pin"), ("✨", "sparkles"), ("🎭", "masks"), ("🇨🇳", "China"),
        ("🪼", "jellyfish"), ("🐶", "dog"), ("🙈", "monkey"), ("🍬", "candy"), ("😂", "laugh"), ("❤️", "heart"),
        ("😍", "love"), ("😒", "unamused"), ("👌", "okay"), ("☺️", "smile"), ("😊", "happy"), ("😘", "kiss"),
        ("😭", "cry"), ("😩", "tired"), ("💕", "hearts"), ("😔", "sad"), ("😏", "smirk"), ("😁", "grin"),
        ("😳", "flushed"), ("👍", "thumbs up"), ("✌️", "peace"), ("😉", "wink"), ("😌", "relieved"), ("🤷", "shrug"),
        ("😀", "happy face"), ("😃", "smiling face"), ("😄", "smiling eyes"), ("😆", "laughing"), ("😝", "tongue"), ("🥺", "pleading"),
        ("😅", "sweat smile"), ("🤣", "rolling laugh"), ("😢", "tear"), ("🥲", "smiling tear"), ("😚", "kiss face"), ("🤗", "hug"),
        ("😇", "angel"), ("🙂", "slight smile"), ("🙃", "upside down"), ("😋", "delicious"), ("😴", "sleep"), ("🥰", "loving")
    ]),
    EmojiGroup(id: "Faces", icon: "face.smiling", entries: [
        ("😎", "cool"), ("🤓", "nerd"), ("🥸", "disguise"), ("🤔", "thinking"), ("🤨", "raised eyebrow"), ("😐", "neutral"),
        ("😮", "surprised"), ("😱", "scream"), ("😡", "angry"), ("🤯", "mind blown"), ("🤠", "cowboy"), ("🥹", "teary"),
        ("😷", "mask"), ("🤒", "sick"), ("😵", "dizzy"), ("🤫", "quiet"), ("🤭", "giggle"), ("🫠", "melting")
    ]),
    EmojiGroup(id: "Animals", icon: "pawprint", entries: [
        ("🐱", "cat"), ("🐻", "bear"), ("🐼", "panda"), ("🦊", "fox"), ("🐰", "rabbit"), ("🦁", "lion"),
        ("🐸", "frog"), ("🐵", "monkey"), ("🦋", "butterfly"), ("🐝", "bee"), ("🐬", "dolphin"), ("🐧", "penguin")
    ]),
    EmojiGroup(id: "Food", icon: "apple.logo", entries: [
        ("🍎", "apple"), ("🍌", "banana"), ("🍓", "strawberry"), ("🍉", "watermelon"), ("🥑", "avocado"), ("🍕", "pizza"),
        ("🍔", "burger"), ("🍣", "sushi"), ("☕️", "coffee"), ("🍰", "cake"), ("🍩", "donut"), ("🥐", "croissant")
    ]),
    EmojiGroup(id: "Activity", icon: "soccerball", entries: [
        ("⚽️", "soccer"), ("🏀", "basketball"), ("🏈", "football"), ("⚾️", "baseball"), ("🎾", "tennis"), ("🏓", "table tennis"),
        ("🎨", "art"), ("🎮", "games"), ("🎲", "dice"), ("🎤", "sing"), ("🎸", "guitar"), ("🏆", "trophy")
    ]),
    EmojiGroup(id: "Travel", icon: "car", entries: [
        ("🚗", "car"), ("✈️", "plane"), ("🚄", "train"), ("🚲", "bicycle"), ("🚀", "rocket"), ("🏖️", "beach")
    ]),
    EmojiGroup(id: "Objects", icon: "lightbulb", entries: [
        ("💡", "idea"), ("📱", "phone"), ("💻", "computer"), ("🎧", "headphones"), ("📷", "camera"), ("🎁", "gift")
    ]),
    EmojiGroup(id: "Symbols", icon: "heart", entries: [
        ("❤️", "heart"), ("💛", "yellow heart"), ("💚", "green heart"), ("💙", "blue heart"), ("💜", "purple heart"), ("🖤", "black heart"),
        ("⭐️", "star"), ("⚡️", "lightning"), ("🔥", "fire"), ("✅", "check"), ("❌", "cross"), ("💯", "hundred")
    ]),
    EmojiGroup(id: "Flags", icon: "flag", entries: [
        ("🇨🇳", "China"), ("🇺🇸", "United States"), ("🇯🇵", "Japan"), ("🇸🇬", "Singapore"), ("🇬🇧", "United Kingdom"), ("🇫🇷", "France"),
        ("🇩🇪", "Germany"), ("🇨🇦", "Canada"), ("🇦🇺", "Australia"), ("🇮🇹", "Italy"), ("🇰🇷", "Korea"), ("🇪🇸", "Spain")
    ])
]

struct EmojiPickerView: View {
    let onPick: (String) -> Void
    let onClose: () -> Void
    var autoFocus = true
    @State private var search = ""
    @State private var selected = "Recent"
    @FocusState private var searchFocused: Bool

    private var entries: [(String, String)] {
        if search.isEmpty { return emojiGroups.first(where: { $0.id == selected })?.entries ?? [] }
        let query = search.lowercased()
        return emojiGroups.flatMap(\.entries).filter { $0.1.localizedCaseInsensitiveContains(query) || $0.0.contains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onClose) { Image(systemName: "xmark.circle.fill").font(.system(size: 14)).foregroundStyle(.gray) }
                    .buttonStyle(.plain)
                Spacer()
                Image(systemName: "rectangle.on.rectangle").foregroundStyle(.gray).font(.system(size: 13))
            }
            .padding(.horizontal, 10).frame(height: 32)

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").font(.system(size: 13)).foregroundStyle(.white.opacity(0.6))
                TextField("Search", text: $search)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($searchFocused)
                    .onSubmit { if let first = entries.first { onPick(first.0) } }
            }
            .padding(.horizontal, 10).frame(height: 30)
            .background(Color.white.opacity(0.16), in: Capsule())
            .padding(.horizontal, 9).padding(.bottom, 8)

            Rectangle().fill(.white.opacity(0.08)).frame(height: 1)
            ScrollView {
                Grid(horizontalSpacing: 2, verticalSpacing: 4) {
                    ForEach(0..<((entries.count + 5) / 6), id: \.self) { row in
                        GridRow {
                            ForEach(0..<6, id: \.self) { column in
                                let index = row * 6 + column
                                if index < entries.count {
                                    let entry = entries[index]
                                    Button { onPick(entry.0) } label: {
                                        Text(entry.0).font(.system(size: 25)).frame(width: 38, height: 34)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(EmojiHoverStyle())
                                    .help(entry.1)
                                } else {
                                    Color.clear.frame(width: 38, height: 34)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
            }
            .scrollIndicators(.hidden)

            HStack(spacing: 0) {
                ForEach(emojiGroups) { group in
                    Button {
                        selected = group.id
                        search = ""
                    } label: {
                        Image(systemName: group.icon)
                            .font(.system(size: 13))
                            .foregroundStyle(selected == group.id ? .white : .white.opacity(0.68))
                            .frame(maxWidth: .infinity).frame(height: 27)
                            .background(selected == group.id ? Color.white.opacity(0.19) : .clear, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help(group.id)
                }
                Button {
                    let index = emojiGroups.firstIndex(where: { $0.id == selected }) ?? 0
                    selected = emojiGroups[(index + 1) % emojiGroups.count].id
                    search = ""
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 20, height: 27)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 6).padding(.vertical, 4)
            .background(.white.opacity(0.06))
        }
        .frame(width: 268, height: 400)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .background(Color(red: 0.13, green: 0.13, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.14), lineWidth: 1))
        .onAppear { if autoFocus { searchFocused = true } }
        .onExitCommand(perform: onClose)
    }
}

private struct EmojiHoverStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.white.opacity(0.16) : .clear, in: RoundedRectangle(cornerRadius: 7))
    }
}
