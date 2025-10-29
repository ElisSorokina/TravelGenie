import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var tripVM: TripViewModel
    @EnvironmentObject var chatVM: ChatViewModel

    var body: some View {
        TabView {
            NavigationStack {
                PlanTripView()
            }
            .tabItem {
                Label(appVM.strings.tabPlan, systemImage: "airplane.departure")
            }

            NavigationStack {
                MyTripView()
            }
            .tabItem {
                Label(appVM.strings.tabMyTrip, systemImage: "checklist")
            }

            NavigationStack {
                ChatView()
            }
            .tabItem {
                Label(appVM.strings.tabChat, systemImage: "bubble.left.and.bubble.right")
            }

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label(appVM.strings.tabProfile, systemImage: "person.circle")
            }
        }
        .tint(AppTheme.accent)
    }
}
