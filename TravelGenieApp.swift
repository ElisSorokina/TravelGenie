import SwiftUI

@main
struct TravelGenieApp: App {

    @StateObject private var appVM = AppViewModel()
    @StateObject private var tripVM = TripViewModel()
    @StateObject private var chatVM = ChatViewModel()

    var body: some Scene {
        WindowGroup {
            AuthGateView()
                .environmentObject(appVM)
                .environmentObject(tripVM)
                .environmentObject(chatVM)
                .preferredColorScheme(.light)
                .tint(AppTheme.accent)
        }
    }
}
