//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct ScheduleFrequencyView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding private var outsideFrequency: Frequency
    @Binding private var startDate: Date
    @Binding private var endDate: Date?
    private let supportsEndDate: Bool
    private let hideRegularIntervalPicker: Bool

    @State private var frequency: Frequency
    @State private var regularInterval: Int = 1
    @State private var daysOfTheWeek: Weekdays = .all


    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Frequency", selection: $frequency) {
                        Text("At Regular Intervals", bundle: .module)
                            .tag(Frequency.regularDayIntervals(regularInterval))
                        Text("On Specific Days of the Week", bundle: .module)
                            .tag(Frequency.specificDaysOfWeek(daysOfTheWeek))
                        Text("As Needed", bundle: .module)
                            .tag(Frequency.asNeeded)
                    }
                        .pickerStyle(.inline)
                        .labelsHidden()
                }
                if case .regularDayIntervals = frequency, !hideRegularIntervalPicker {
                    regularDayIntervalsSection
                }
                if case .specificDaysOfWeek = frequency {
                    specificDaysOfWeekSection
                }
                Section {
                    startDateSection
                    if supportsEndDate {
                        endDateControls
                    }
                }
            }
            .toolbar {
                toolbar
            }
        }
    }

    @ViewBuilder private var regularDayIntervalsSection: some View {
        Section(String(localized: "Choose Interval", bundle: .module)) {
            Picker("Every", selection: $regularInterval) {
                ForEach(1..<366) { day in
                    Text(Frequency.regularDayIntervals(day).description)
                        .tag(day)
                }
            }
                .pickerStyle(.wheel)
                .onChange(of: regularInterval) {
                    updateSchedule()
                }
        }
    }

    @ViewBuilder private var specificDaysOfWeekSection: some View {
        Section(String(localized: "Choose Days", bundle: .module)) {
            ForEach(Weekdays.allCases) { weekday in
                if daysOfTheWeek.contains(weekday) {
                    HStack {
                        Button(weekday.localizedDescription) {
                            insert(dayOfTheWeek: weekday)
                        }
                            .foregroundStyle(Color.primary)
                        Spacer()
                        Image(systemName: "checkmark")
                            .accessibilityHidden(true)
                            .foregroundStyle(Color.accentColor)
                    }
                } else {
                    Button(weekday.localizedDescription) {
                        remove(dayOfTheWeek: weekday)
                    }
                        .foregroundStyle(Color.primary)
                }
            }
        }
    }

    @ViewBuilder private var startDateSection: some View {
        HStack {
            Text("Start Date", bundle: .module)
            Spacer()
            DatePicker(
                "",
                selection: $startDate,
                in: Date.distantPast...Date.now,
                displayedComponents: .date
            )
                .labelsHidden()
        }
        .frame(minHeight: 56)
            .onChange(of: startDate) {
                guard let currentEndDate = endDate, currentEndDate < startDate else {
                    return
                }
                endDate = startDate
            }
    }

    @ViewBuilder private var endDateControls: some View {
        Group {
            if endDate != nil {
                HStack {
                    Text("End Date")
                    Spacer()
                    DatePicker(
                        "",
                        selection: endDateSelection,
                        in: startDate...Date.distantFuture,
                        displayedComponents: .date
                    )
                        .labelsHidden()
                }
                .frame(minHeight: 56)

                Button("Remove End Date", role: .destructive) {
                    withAnimation {
                        endDate = nil
                    }
                }
            } else {
                Button("Add End Date") {
                    withAnimation {
                        endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate) ?? startDate
                    }
                }
            }
        }
        .id(endDate != nil)
    }

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(String(localized: "Cancel", bundle: .module)) {
                dismiss()
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button(String(localized: "Done", bundle: .module)) {
                outsideFrequency = frequency
                dismiss()
            }
                .bold()
        }
    }


    init(
        frequency: Binding<Frequency>,
        startDate: Binding<Date>,
        endDate: Binding<Date?>,
        supportsEndDate: Bool,
        hideRegularIntervalPicker: Bool
    ) {
        self._outsideFrequency = frequency
        self._startDate = startDate
        self._endDate = endDate
        self.supportsEndDate = supportsEndDate
        self.hideRegularIntervalPicker = hideRegularIntervalPicker
        self._frequency = State(wrappedValue: frequency.wrappedValue)

        switch frequency.wrappedValue {
        case let .specificDaysOfWeek(daysOfTheWeek):
            self._daysOfTheWeek = State(wrappedValue: daysOfTheWeek)
        case let .regularDayIntervals(regularDayIntervals):
            self._regularInterval = State(wrappedValue: regularDayIntervals)
        case .asNeeded:
            break
        }
    }


    private var endDateSelection: Binding<Date> {
        Binding(
            get: {
                endDate ?? startDate
            },
            set: { newValue in
                endDate = newValue
            }
        )
    }

    private func insert(dayOfTheWeek: Weekdays) {
        daysOfTheWeek.subtract(dayOfTheWeek)
        updateSchedule()
    }

    private func remove(dayOfTheWeek: Weekdays) {
        daysOfTheWeek.insert(dayOfTheWeek)
        updateSchedule()
    }

    private func updateSchedule() {
        switch frequency {
        case .regularDayIntervals:
            self.frequency = .regularDayIntervals(regularInterval)
        case .specificDaysOfWeek:
            self.frequency = .specificDaysOfWeek(daysOfTheWeek)
        case .asNeeded:
            return
        }
    }
}

#Preview {
    @Previewable @State var frequency: Frequency = .specificDaysOfWeek(.all)
    @Previewable @State var startDate: Date = .now
    @Previewable @State var endDate: Date? = .now

    return ScheduleFrequencyView(
        frequency: $frequency,
        startDate: $startDate,
        endDate: $endDate,
        supportsEndDate: true,
        hideRegularIntervalPicker: false
    )
}
