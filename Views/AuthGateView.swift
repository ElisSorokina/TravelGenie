import SwiftUI

struct AuthGateView: View {
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var tripVM: TripViewModel
    @EnvironmentObject var chatVM: ChatViewModel

    var body: some View {
        if appVM.currentUser != nil {
            MainTabView()
                .environmentObject(appVM)
                .environmentObject(tripVM)
                .environmentObject(chatVM)
        } else {
            LoginView()
                .environmentObject(appVM)
                .environmentObject(tripVM)
                .environmentObject(chatVM)
        }
    }
}
