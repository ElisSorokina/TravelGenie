import SwiftUI

struct PlanTripView: View {
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var tripVM: TripViewModel

    @StateObject private var locationService = LocationService()

    @State private var originCountry: CountryModel? = nil
    @State private var originCity: CityModel? = nil

    @State private var destCountry: CountryModel? = nil
    @State private var destCity: CityModel? = nil

    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()

    @State private var showPreview = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    headerSection
                    originSection
                    destinationSection
                    datesSection
                    generateButtonSection
                    previewSection
                }
                .padding(16)
            }
            .blur(radius: tripVM.isLoadingTrip ? 3 : 0)

            if tripVM.isLoadingTrip {
                loadingOverlay
            }
        }
        .background(AppTheme.bgSoft.ignoresSafeArea())
        .navigationTitle(appVM.strings.tabPlan)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPreview) {
            if let trip = tripVM.currentTrip {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        TripHeaderCard(trip: trip)

                        DayByDaySectionView(
                            title: "Day by day",
                            days: trip.dayByDayPlan
                        )
                    }
                    .padding()
                }
                .presentationDetents([.large])
            }
        }
        .task {
            await locationService.loadCountriesIfNeeded()
        }
    }

    // MARK: - Sections broken out

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appVM.strings.screenPlanTitle)
                .font(.title2.bold())
                .foregroundColor(AppTheme.textPrimary)

            Text(appVM.strings.screenPlanSubtitle)
                .font(.footnote)
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private var originSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(appVM.strings.fieldFrom)
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            // Country picker (origin)
            menuCard {
                if locationService.isLoadingCountries {
                    HStack(spacing: 8) {
                        ProgressView().tint(AppTheme.accent)
                        Text("Loading countries…")
                            .font(.footnote)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Picker("Country", selection: Binding(
                        get: { originCountry },
                        set: { newCountry in
                            originCountry = newCountry
                            originCity = nil
                            if let c = newCountry {
                                Task { await locationService.loadCitiesIfNeeded(for: c) }
                            }
                        }
                    )) {
                        Text("Select country").tag(CountryModel?.none)
                        ForEach(locationService.countries) { country in
                            Text(country.name).tag(CountryModel?.some(country))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppTheme.accent)
                }
            }

            // City picker (origin)
            menuCard(disabled: originCountry == nil) {
                if let country = originCountry {
                    if locationService.isLoadingCities.contains(country.code) &&
                        locationService.cities(for: country).isEmpty {

                        HStack(spacing: 8) {
                            ProgressView().tint(AppTheme.accent)
                            Text("Loading cities…")
                                .font(.footnote)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                    } else {
                        Picker("City", selection: Binding(
                            get: { originCity },
                            set: { newCity in
                                originCity = newCity
                            }
                        )) {
                            Text("Select city").tag(CityModel?.none)
                            ForEach(locationService.cities(for: country)) { city in
                                Text(city.name).tag(CityModel?.some(city))
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AppTheme.accent)
                    }
                } else {
                    Text("Select city")
                        .foregroundColor(AppTheme.textSecondary.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.footnote)
                }
            }
        }
    }

    private var destinationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(appVM.strings.fieldTo)
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            // Country picker (destination)
            menuCard {
                if locationService.isLoadingCountries {
                    HStack(spacing: 8) {
                        ProgressView().tint(AppTheme.accent)
                        Text("Loading countries…")
                            .font(.footnote)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Picker("Country", selection: Binding(
                        get: { destCountry },
                        set: { newCountry in
                            destCountry = newCountry
                            destCity = nil
                            if let c = newCountry {
                                Task { await locationService.loadCitiesIfNeeded(for: c) }
                            }
                        }
                    )) {
                        Text("Select country").tag(CountryModel?.none)
                        ForEach(locationService.countries) { country in
                            Text(country.name).tag(CountryModel?.some(country))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppTheme.accent)
                }
            }

            // City picker (destination)
            menuCard(disabled: destCountry == nil) {
                if let country = destCountry {
                    if locationService.isLoadingCities.contains(country.code) &&
                        locationService.cities(for: country).isEmpty {

                        HStack(spacing: 8) {
                            ProgressView().tint(AppTheme.accent)
                            Text("Loading cities…")
                                .font(.footnote)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                    } else {
                        Picker("City", selection: Binding(
                            get: { destCity },
                            set: { newCity in
                                destCity = newCity
                            }
                        )) {
                            Text("Select city").tag(CityModel?.none)
                            ForEach(locationService.cities(for: country)) { city in
                                Text(city.name).tag(CityModel?.some(city))
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AppTheme.accent)
                    }
                } else {
                    Text("Select city")
                        .foregroundColor(AppTheme.textSecondary.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.footnote)
                }
            }
        }
    }

    private var datesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(appVM.strings.fieldDates)
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            dateCard(label: appVM.strings.fieldStart, date: $startDate)
            dateCard(label: appVM.strings.fieldEnd,   date: $endDate)
        }
    }

    private var generateButtonSection: some View {
        Button {
            Task { await handleGenerate() }
        } label: {
            HStack(spacing: 8) {
                if tripVM.isLoadingTrip {
                    ProgressView()
                        .tint(.white)
                }
                Text(tripVM.isLoadingTrip ? appVM.strings.generatingTrip : appVM.strings.buttonGenerateTrip)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.accent)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppTheme.cardShadow, radius: 12, x: 0, y: 6)
        }
        .disabled(!canGenerate || tripVM.isLoadingTrip)
    }

    private var previewSection: some View {
        Group {
            if let lastTrip = tripVM.currentTrip {
                VStack(alignment: .leading, spacing: 12) {
                    Text(appVM.strings.previewTitle)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)

                    TripHeaderCard(trip: lastTrip)
                        .onTapGesture { showPreview = true }
                }
            }
        }
    }

    private var loadingOverlay: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.3)
                .tint(AppTheme.accent)

            Text(appVM.strings.generatingOverlayText)
                .font(.footnote)
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.surface)
                .shadow(color: AppTheme.cardShadow, radius: 20, x: 0, y: 10)
        )
    }

    // MARK: - Helpers

    private var canGenerate: Bool {
        originCountry != nil &&
        originCity != nil &&
        destCountry != nil &&
        destCity != nil &&
        startDate <= endDate
    }

    private func handleGenerate() async {
        guard
            let oCountry = originCountry,
            let oCity = originCity,
            let dCountry = destCountry,
            let dCity = destCity
        else { return }

        let originFull = "\(oCity.name), \(oCountry.name)"
        let destFull = "\(dCity.name), \(dCountry.name)"

        await tripVM.generateTrip(
            destination: destFull,
            startDate: startDate,
            endDate: endDate,
            departureCity: originFull,
            user: appVM.currentUser
        )

        if tripVM.apiError == nil {
            showPreview = true
        }
    }

    // MARK: - Small reusable cards

    @ViewBuilder
    private func menuCard<Content: View>(
        disabled: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface.opacity(disabled ? 0.4 : 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppTheme.cardShadow, radius: 8, x: 0, y: 4)
        .disabled(disabled)
    }

    private func dateCard(label: String, date: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)

            DatePicker("", selection: date, displayedComponents: .date)
                .labelsHidden()
                .tint(AppTheme.accent)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppTheme.cardShadow, radius: 8, x: 0, y: 4)
    }
}
