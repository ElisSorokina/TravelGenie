import SwiftUI

// MARK: - Shared date formatting helper
func dateRangeString(_ start: Date, _ end: Date) -> String {
    let df = DateFormatter()
    df.dateFormat = "MMM d"
    let sStr = df.string(from: start)
    let eStr = df.string(from: end)
    return "\(sStr) - \(eStr)"
}

// MARK: - TripHeaderCard
// Card with destination, dates, flight booking link, hotel booking link.

// MARK: - DayPlanCard
// One day's schedule: morning / afternoon / evening.
struct DayPlanCard: View {
    let day: DayPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text(day.dateLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppTheme.textPrimary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Morning: \(day.morning)")
                Text("Afternoon: \(day.afternoon)")
                Text("Evening: \(day.evening)")
            }
            .font(.footnote)
            .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.surface)
                .shadow(color: AppTheme.cardShadow, radius: 12, x: 0, y: 6)
        )
    }
}

// MARK: - DayByDaySectionView
// Vertical list of DayPlanCard items
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
