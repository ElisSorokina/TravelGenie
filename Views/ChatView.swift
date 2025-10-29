import SwiftUI

struct ChatView: View {
    @EnvironmentObject var chatVM: ChatViewModel
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        VStack(spacing: 0) {

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(chatVM.messages) { msg in
                            HStack {
                                if msg.sender == .assistant {
                                    ChatBubble(text: msg.text,
                                               isUser: false)
                                    Spacer(minLength: 40)
                                } else {
                                    Spacer(minLength: 40)
                                    ChatBubble(text: msg.text,
                                               isUser: true)
                                }
                            }
                            .id(msg.id)
                        }

                        if chatVM.isSending {
                            HStack {
                                ChatBubble(text: "…", isUser: false, isThinking: true)
                                Spacer(minLength: 40)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 80)
                }
                .background(AppTheme.bgSoft.ignoresSafeArea())
                .onChange(of: chatVM.messages.count) { oldValue, newValue in
                    if newValue > oldValue, let lastId = chatVM.messages.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }

            Divider()

            HStack(alignment: .bottom, spacing: 12) {
                TextField(appVM.strings.chatPlaceholder, text: $chatVM.draft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: AppTheme.cardShadow, radius: 8, x: 0, y: 4)
                    .frame(minHeight: 44)

                Button {
                    chatVM.sendCurrentDraft()
                } label: {
                    if chatVM.isSending {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                    }
                }
                .padding(12)
                .background(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .disabled(chatVM.isSending)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppTheme.bgSoft.ignoresSafeArea(edges: .bottom))
        }
        .navigationTitle(appVM.strings.tabChat)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ChatBubble: View {
    let text: String
    let isUser: Bool
    var isThinking: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(text)
                .font(.subheadline)
                .foregroundColor(isUser ? .white : AppTheme.textPrimary)
                .multilineTextAlignment(.leading)

            if isThinking {
                Text("thinking…")
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(12)
        .background(isUser ? AppTheme.accent : AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppTheme.cardShadow, radius: 8, x: 0, y: 4)
    }
}
