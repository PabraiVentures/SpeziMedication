//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct EditScheduleTimeRow: View {
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    @Binding private var time: ScheduledTime
    @Binding private var times: [ScheduledTime]
    @State private var isEditingTime = false


    var body: some View {
        HStack(spacing: 12) {
            Button(
                action: {
                    isEditingTime = true
                },
                label: {
                    Text(Self.timeFormatter.string(from: time.date))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                }
            )
                .buttonStyle(.plain)

            Spacer(minLength: 0)

            Button(
                action: {
                    times.removeAll(where: { $0.id == time.id })
                },
                label: {
                    Image(systemName: "minus.circle.fill")
                        .accessibilityLabel(Text("Delete", bundle: .module))
                        .foregroundStyle(Color.red)
                }
            )
                .buttonStyle(.borderless)
        }
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .onChange(of: time.date) {
            withAnimation {
                times.sort()
            }
        }
        .sheet(isPresented: $isEditingTime) {
            NavigationStack {
                VStack {
                    ScheduledTimeDatePicker(
                        date: $time.date.animation(),
                        excludedDates: times.map(\.date),
                        preferredDatePickerStyle: .wheels
                    )
                    .frame(maxWidth: .infinity, minHeight: 216)
                }
                .navigationTitle(Text("Select Time", bundle: .module))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(
                            action: {
                                isEditingTime = false
                            },
                            label: {
                                Text("Done", bundle: .module)
                            }
                        )
                    }
                }
            }
            .presentationDetents([.height(320)])
        }
    }


    init(time: Binding<ScheduledTime>, times: Binding<[ScheduledTime]>) {
        self._time = time
        self._times = times
    }
}
