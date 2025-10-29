import Foundation
import SwiftUI

@MainActor
final class TripViewModel: ObservableObject {

    // MARK: - State

    @Published var trips: [Trip] = []
    @Published var currentTripId: UUID? = nil

    @Published var isLoadingTrip: Bool = false
    @Published var apiError: String? = nil

    // MARK: - Storage keys

    private let tripsKey = "tg_trips_v1"
    private let currentTripKey = "tg_current_trip_id_v1"

    init() {
        loadTripsFromStorage()
        loadCurrentTripId()
        // ensure selection if we have trips
        if currentTripId == nil, let first = trips.first { currentTripId = first.id }
    }

    // MARK: - Computed

    var currentTrip: Trip? {
        guard let id = currentTripId else { return nil }
        return trips.first(where: { $0.id == id })
    }

    // MARK: - Persistence

    private func loadTripsFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: tripsKey) else {
            trips = []
            return
        }
        trips = (try? JSONDecoder().decode([Trip].self, from: data)) ?? []
    }

    private func saveTripsToStorage() {
        if let data = try? JSONEncoder().encode(trips) {
            UserDefaults.standard.set(data, forKey: tripsKey)
        }
    }

    private func loadCurrentTripId() {
        if let raw = UserDefaults.standard.string(forKey: currentTripKey),
           let uuid = UUID(uuidString: raw) {
            currentTripId = uuid
        }
    }

    private func saveCurrentTripId() {
        if let id = currentTripId {
            UserDefaults.standard.set(id.uuidString, forKey: currentTripKey)
        } else {
            UserDefaults.standard.removeObject(forKey: currentTripKey)
        }
    }

    // MARK: - Trip list actions

    func selectTrip(_ id: UUID) {
        currentTripId = id
        saveCurrentTripId()
    }

    func deleteTrip(_ id: UUID) {
        trips.removeAll { $0.id == id }
        if currentTripId == id {
            currentTripId = trips.first?.id
        }
        saveTripsToStorage()
        saveCurrentTripId()
    }

    // MARK: - Checklist & Must-See

    func toggleChecklistItem(_ itemId: UUID) {
        guard let tIndex = trips.firstIndex(where: { $0.id == currentTripId }) else { return }

        if let i = trips[tIndex].checklist.firstIndex(where: { $0.id == itemId }) {
            trips[tIndex].checklist[i].isDone.toggle()
            saveTripsToStorage()
            return
        }
        if let i = trips[tIndex].mustSeeList.firstIndex(where: { $0.id == itemId }) {
            trips[tIndex].mustSeeList[i].isDone.toggle()
            saveTripsToStorage()
            return
        }
    }

    func removeChecklistItem(_ itemId: UUID, listTarget: ListTarget) {
        guard let tIndex = trips.firstIndex(where: { $0.id == currentTripId }) else { return }

        switch listTarget {
        case .checklist:
            trips[tIndex].checklist.removeAll { $0.id == itemId }
        case .mustSee:
            trips[tIndex].mustSeeList.removeAll { $0.id == itemId }
        }
        saveTripsToStorage()
    }

    func addChecklistItem(title: String, notes: String?, listTarget: ListTarget) {
        guard let tIndex = trips.firstIndex(where: { $0.id == currentTripId }) else { return }

        let newItem = ChecklistItem(
            id: UUID(),
            title: title,
            notes: notes,
            link: nil,
            isDone: false,
            type: listTarget == .checklist ? .preTrip : .inTrip
        )

        switch listTarget {
        case .checklist:
            trips[tIndex].checklist.append(newItem)
        case .mustSee:
            trips[tIndex].mustSeeList.append(newItem)
        }
        saveTripsToStorage()
    }

    // MARK: - Trip generation via OpenAI

    func generateTrip(
        destination: String,
        startDate: Date,
        endDate: Date,
        departureCity: String,
        user: UserProfile?
    ) async {
        isLoadingTrip = true
        apiError = nil
        defer { isLoadingTrip = false }

        do {
            let newTrip = try await TripAPIService.generateTrip(
                destination: destination,
                startDate: startDate,
                endDate: endDate,
                departureCity: departureCity,
                user: user
            )
            trips.append(newTrip)
            currentTripId = newTrip.id
            saveTripsToStorage()
            saveCurrentTripId()
        } catch {
            apiError = error.localizedDescription
        }
    }
}
