import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var tripVM: TripViewModel
    @EnvironmentObject var chatVM: ChatViewModel  // <- добавили

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var avatarImage: Image?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // Аватар + имя + email
                VStack(spacing: 12) {
                    ZStack {
                        if let avatarImage {
                            avatarImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else if let img = appVM.currentUser?.avatarImage {
                            img
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(AppTheme.surface)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(AppTheme.textSecondary)
                                )
                                .shadow(color: AppTheme.cardShadow, radius: 10, x: 0, y: 4)
                        }

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Circle()
                                .fill(AppTheme.accent)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 28, y: 28)
                        }
                    }

                    Text(appVM.currentUser?.name.isEmpty == false ? appVM.currentUser!.name : "Traveler")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)

                    Text(appVM.currentUser?.email ?? "")
                        .font(.footnote)
                        .foregroundColor(AppTheme.textSecondary)
                }

                // Выбор языка интерфейса
                VStack(alignment: .leading, spacing: 12) {
                    Text(appVM.strings.languageTitle)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)

                    Picker(appVM.strings.languagePickerLabel,
                           selection: Binding(
                            get: { appVM.appLanguage },
                            set: { newLang in appVM.setLanguage(newLang) }
                           )
                    ) {
                        Text("English").tag(AppLanguage.english)
                        Text("Русский").tag(AppLanguage.russian)
                    }
                    .pickerStyle(.segmented)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: AppTheme.cardShadow, radius: 16, x: 0, y: 8)
                .padding(.horizontal, 20)

                // Logout
                Button(role: .destructive) {
                    // почистить локальные данные при выходе, если хочешь
                    tripVM.trips.removeAll()
                    tripVM.currentTripId = nil

                    chatVM.messages.removeAll()
                    chatVM.draft = ""
                    // (chatVM сам перезапишет историю пустой при следующей инициализации? нет,
                    // но мы можем прямо сейчас очистить UserDefaults:)
                    UserDefaults.standard.removeObject(forKey: "chatHistoryMessages_v1")

                    appVM.logout()
                } label: {
                    Text(appVM.strings.logoutButton)
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(.white)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20)
                }

                Spacer(minLength: 40)
            }
            .padding(.top, 24)
        }
        .background(AppTheme.bgSoft.ignoresSafeArea())
        .navigationTitle(appVM.strings.tabProfile)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPhoto) { newItem in
            Task { await loadAvatar(from: newItem) }
        }
    }

    private func loadAvatar(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let uiImg = UIImage(data: data) {
            avatarImage = Image(uiImage: uiImg)

            // TODO (если захочешь позже):
            // 1. закодировать картинку в base64
            // 2. сохранить в appVM.currentUser?.avatarImageDataBase64
            // 3. отправить это на Back4App
        }
    }
}
