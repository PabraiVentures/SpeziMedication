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

    @State private var frequency: Frequency


    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Frequency", selection: $frequency) {
                        Text("Every Day", bundle: .module)
                            .tag(Frequency.regularDayIntervals(1))
                        Text("As Needed", bundle: .module)
                            .tag(Frequency.asNeeded)
                    }
                        .pickerStyle(.inline)
                        .labelsHidden()
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
        hideRegularIntervalPicker _: Bool
    ) {
        self._outsideFrequency = frequency
        self._startDate = startDate
        self._endDate = endDate
        self.supportsEndDate = supportsEndDate
        self._frequency = State(wrappedValue: Self.normalizedFrequency(frequency.wrappedValue))
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

    private static func normalizedFrequency(_ frequency: Frequency) -> Frequency {
        switch frequency {
        case .regularDayIntervals:
            .regularDayIntervals(1)
        case .specificDaysOfWeek:
            .regularDayIntervals(1)
        case .asNeeded:
            .asNeeded
        }
    }
}

#Preview {
    @Previewable @State var frequency: Frequency = .regularDayIntervals(1)
    @Previewable @State var startDate: Date = .now
    @Previewable @State var endDate: Date? = .now

    return ScheduleFrequencyView(
        frequency: $frequency,
        startDate: $startDate,
        endDate: $endDate,
        supportsEndDate: true,
        hideRegularIntervalPicker: true
    )
}
