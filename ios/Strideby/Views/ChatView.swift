import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var app: AppState
    let matchID: String
    @State private var draft = ""

    private var match: Match? {
        app.matches.first { $0.id == matchID }
    }

    var body: some View {
        VStack(spacing: 0) {
            if let match {
                messageList(match)
                if match.messages.isEmpty { icebreakers }
                inputBar
            }
        }
        .background(Theme.cloud)
        .navigationTitle(match?.crossing.profile.firstName ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .task { await app.loadMessages(for: matchID) }
    }

    private func messageList(_ match: Match) -> some View {
        ScrollView {
            VStack(spacing: 10) {
                contextHeader(match)
                ForEach(match.messages) { message in
                    bubble(message)
                }
            }
            .padding(16)
        }
        .defaultScrollAnchor(.bottom)
    }

    private func contextHeader(_ match: Match) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.triangle.swap")
            Text("You crossed on \(match.crossing.routeName) · \(match.crossing.overlapMinutes) min side by side")
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(Theme.slate)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.yellow.opacity(0.2), in: Capsule())
        .padding(.bottom, 8)
    }

    private func bubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.sender == .me { Spacer(minLength: 48) }
            Text(message.text)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    message.sender == .me
                        ? AnyShapeStyle(Theme.brandGradient)
                        : AnyShapeStyle(Color.white),
                    in: RoundedRectangle(cornerRadius: 18)
                )
                .foregroundStyle(message.sender == .me ? Color.white : Theme.ink)
            if message.sender == .them { Spacer(minLength: 48) }
        }
    }

    private var icebreakers: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(["Nice pace out there 👀",
                         "That loop at sunrise — solid choice",
                         "Rematch? Loser buys coffee ☕️"], id: \.self) { line in
                    Button {
                        app.send(line, in: matchID)
                    } label: {
                        Text(line)
                            .font(.footnote.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Theme.yellow.opacity(0.3), in: Capsule())
                            .foregroundStyle(Theme.ink)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 6)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message…", text: $draft)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.white, in: Capsule())
                .onSubmit(sendDraft)
            Button(action: sendDraft) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Theme.orange)
            }
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(12)
        .background(.bar)
    }

    private func sendDraft() {
        let text = draft.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        app.send(text, in: matchID)
        draft = ""
    }
}
