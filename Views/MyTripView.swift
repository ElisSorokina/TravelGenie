import SwiftUI

struct MyTripView: View {
    @EnvironmentObject var tripVM: TripViewModel
    @EnvironmentObject var appVM: AppViewModel

    @State private var showAddChecklist = false
    @State private var addTarget: ListTarget = .checklist

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // TRIPS LIST
                TripsSection(
                    strings: appVM.strings,
                    trips: tripVM.trips,
                    currentTripId: tripVM.currentTripId,
                    onSelect: { id in tripVM.selectTrip(id) },
                    onDelete: { id in tripVM.deleteTrip(id) }
                )

                // ACTIVE TRIP DETAILS
                if let trip = tripVM.currentTrip {
                    TripHeaderCard(trip: trip)

                    ChecklistSectionView(
                        title: appVM.strings.preTripChecklist,
                        items: trip.checklist,
                        onToggle: { tripVM.toggleChecklistItem($0) },
                        onDelete: { tripVM.removeChecklistItem($0, listTarget: .checklist) },
                        onAddTap: {
                            addTarget = .checklist
                            showAddChecklist = true
                        }
                    )

                    ChecklistSectionView(
                        title: appVM.strings.mustSeeTitle,
                        items: trip.mustSeeList,
                        onToggle: { tripVM.toggleChecklistItem($0) },
                        onDelete: { tripVM.removeChecklistItem($0, listTarget: .mustSee) },
                        onAddTap: {
                            addTarget = .mustSee
                            showAddChecklist = true
                        }
                    )

                    DayByDaySectionView(
                        title: "Day by day",
                        days: trip.dayByDayPlan
                    )
                } else {
                    Text(appVM.strings.noTripYet)
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.top, 8)
                }
            }
            .padding(16)
        }
        .background(AppTheme.bgSoft.ignoresSafeArea())
        .sheet(isPresented: $showAddChecklist) {
            AddItemSheet(
                strings: appVM.strings,
                onAdd: { title, notes in
                    tripVM.addChecklistItem(title: title, notes: notes, listTarget: addTarget)
                }
            )
            .presentationDetents([.medium])
        }
        .navigationTitle(appVM.strings.tabMyTrip)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // auto-select first if none
            if tripVM.currentTripId == nil, let first = tripVM.trips.first {
                tripVM.selectTrip(first.id)
            }
        }
    }
}

// MARK: - Trips list

private struct TripsSection: View {
    let strings: LocalizedStrings
    let trips: [Trip]
    let currentTripId: UUID?
    let onSelect: (UUID) -> Void
    let onDelete: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(strings.yourTripsTitle)
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            if trips.isEmpty {
                Text(strings.noTripsYet)
                    .font(.footnote)
                    .foregroundColor(AppTheme.textSecondary)
            } else {
                ForEach(trips) { trip in
                    TripListCard(
                        trip: trip,
                        isActive: (trip.id == currentTripId),
                        onOpen: { onSelect(trip.id) },
                        onDelete: { onDelete(trip.id) }
                    )
                }
            }
        }
    }
}

private struct TripListCard: View {
    let trip: Trip
    let isActive: Bool
    let onOpen: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.destination)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)

                Text(dateRangeString(trip.startDate, trip.endDate))
                    .font(.footnote)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            Button {
                onOpen()
            } label: {
                Text("Open")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppTheme.accent)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash.fill")
                    .font(.footnote.weight(.bold))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isActive ? AppTheme.accent.opacity(0.4) : .clear, lineWidth: 2)
                )
        )
        .shadow(color: AppTheme.cardShadow, radius: 10, x: 0, y: 4)
    }
}

// MARK: - Active trip header (with links)

struct TripHeaderCard: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(trip.destination)
                .font(.title2.bold())
                .foregroundColor(AppTheme.textPrimary)

            Text(dateRangeString(trip.startDate, trip.endDate))
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)

            if let f = trip.flightInfo {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "airplane.departure")
                            .foregroundColor(AppTheme.accent)
                        Text("Flight")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    Text(f.priceEstimate)
                        .font(.footnote)
                        .foregroundColor(AppTheme.textSecondary)

                    if let url = URL(string: f.url) {
                        Link("Book flight", destination: url)
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(AppTheme.accent)
                            .lineLimit(1)
                    }
                }
            }

            if let h = trip.hotelInfo {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "bed.double.fill")
                            .foregroundColor(AppTheme.accent)
                        Text("Hotel")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    Text(h.priceEstimate)
                        .font(.footnote)
                        .foregroundColor(AppTheme.textSecondary)

                    if let url = URL(string: h.url) {
                        Link("Book hotel", destination: url)
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(AppTheme.accent)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppTheme.cardShadow, radius: 16, x: 0, y: 8)
    }
}

// MARK: - Checklist section

private struct ChecklistSectionView: View {
    let title: String
    let items: [ChecklistItem]
    let onToggle: (UUID) -> Void
    let onDelete: (UUID) -> Void
    let onAddTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Button {
                    onAddTap()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppTheme.accent)
                }
                .buttonStyle(.plain)
            }

            if items.isEmpty {
                Text("No items yet")
                    .font(.footnote)
                    .foregroundColor(AppTheme.textSecondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(items) { item in
                        ChecklistRow(
                            item: item,
                            toggle: { onToggle(item.id) },
                            delete: { onDelete(item.id) }
                        )
                    }
                }
            }
        }
    }
}

private struct ChecklistRow: View {
    let item: ChecklistItem
    let toggle: () -> Void
    let delete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            Button { toggle() } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isDone ? AppTheme.accent : AppTheme.textSecondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .strikethrough(item.isDone, color: AppTheme.textPrimary.opacity(0.5))

                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.footnote)
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let link = item.link, let url = URL(string: link) {
                    Link("Open", destination: url)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(AppTheme.accent)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button(role: .destructive) { delete() } label: {
                Image(systemName: "trash.fill")
                    .foregroundColor(.red)
                    .font(.footnote.weight(.bold))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: AppTheme.cardShadow, radius: 10, x: 0, y: 4)
    }
}

// MARK: - Day-by-day


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
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppTheme.cardShadow, radius: 12, x: 0, y: 6)
    }
}

// MARK: - Add item sheet

private struct AddItemSheet: View {
    let strings: LocalizedStrings
    let onAdd: (_ title: String, _ notes: String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField(strings.fieldTitle, text: $title)
                TextField(strings.fieldNotesOptional, text: $notes)
            }
            .navigationTitle(strings.addItemTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(strings.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(strings.add) {
                        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        onAdd(title, notes.isEmpty ? nil : notes)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Helpers

private func dateRangeString(_ s: Date, _ e: Date) -> String {
    let df = DateFormatter()
    df.dateFormat = "MMM d"
    return "\(df.string(from: s)) - \(df.string(from: e))"
}

