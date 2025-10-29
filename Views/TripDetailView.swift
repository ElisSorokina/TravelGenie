import SwiftUI

struct TripDetailView: View {
    let trip: Trip

    var body: some View {
        NavigationStack {
            List {
                if let flight = trip.flightInfo {
                    Section("Flights") {
                        BookingRowView(suggestion: flight)
                    }
                }

                if let hotel = trip.hotelInfo {
                    Section("Hotel") {
                        BookingRowView(suggestion: hotel)
                    }
                }

                Section("Day by Day Plan") {
                    ForEach(trip.dayByDayPlan) { day in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(day.dateLabel)
                                .font(.headline)
                            Text("Morning: \(day.morning)")
                            Text("Afternoon: \(day.afternoon)")
                            Text("Evening: \(day.evening)")
                        }
                        .font(.subheadline)
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Trip Details")
        }
        .tint(AppTheme.accent)
    }
}

struct BookingRowView: View {
    let suggestion: BookingSuggestion

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(suggestion.title)
                .font(.headline)
            Text(suggestion.priceEstimate)
                .font(.subheadline)
                .foregroundColor(.secondary)
            if !suggestion.url.isEmpty, let url = URL(string: suggestion.url) {
                Link("Open link", destination: url)
                    .font(.footnote)
                    .tint(AppTheme.accent)
            }
        }
        .padding(.vertical, 4)
    }
}
