//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct EditFrequency: View {
    @Binding private var frequency: Frequency
    @Binding private var startDate: Date
    @Binding private var endDate: Date?
    private let supportsEndDate: Bool
    @State private var showFrequencySheet = false


    var body: some View {
        Section {
            Button(
                action: {
                    showFrequencySheet.toggle()
                },
                label: {
                    HStack {
                        Text("Frequency")
                            .foregroundStyle(Color.primary)
                        Spacer()
                        Text(frequency.description)
                            .foregroundStyle(Color.accentColor)
                    }
                }
            )
        }
            .sheet(isPresented: $showFrequencySheet) {
                ScheduleFrequencyView(
                    frequency: $frequency,
                    startDate: $startDate,
                    endDate: $endDate,
                    supportsEndDate: supportsEndDate
                )
            }
    }


    init(frequency: Binding<Frequency>, startDate: Binding<Date>, endDate: Binding<Date?>? = nil) {
        self._frequency = frequency
        self._startDate = startDate
        if let endDate {
            self._endDate = endDate
            self.supportsEndDate = true
        } else {
            self._endDate = .constant(nil)
            self.supportsEndDate = false
        }
    }
}
