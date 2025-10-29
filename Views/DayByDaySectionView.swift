import SwiftUI

// Карточка одного дня


// Секция со списком дней
struct DayByDaySectionView: View {
    let title: String
    let days: [DayPlan]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text(title)
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            VStack(spacing: 12) {
                ForEach(days) { d in
                    DayPlanCard(day: d)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
