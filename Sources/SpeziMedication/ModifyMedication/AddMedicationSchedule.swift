//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziViews
import SwiftUI


struct AddMedicationSchedule<MI: MedicationInstance>: View {
    @Environment(InternalMedicationSettingsViewModel<MI>.self) private var viewModel
    @Binding private var isPresented: Bool

    @State private var frequency: Frequency = .regularDayIntervals(1)
    @State private var startDate: Date = .now
    @State private var endDate: Date?
    @State private var times: [ScheduledTime] = []

    private let medicationOption: MI.InstanceType
    private let dosage: MI.InstanceDosage
    private let draftMedicationID: AnyHashable


    var body: some View {
        VStack(spacing: 0) {
            Form {
                titleSection
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                EditFrequency(
                    frequency: $frequency,
                    startDate: $startDate,
                    endDate: supportsEndDate ? $endDate : nil
                )
                EditScheduleTime(times: $times)
            }
            VStack(alignment: .center) {
                AsyncButton(
                    action: {
                        var medicationInstance = viewModel.createMedicationInstance(
                            medicationOption,
                            dosage,
                            Schedule(frequency: frequency, times: times, startDate: startDate)
                        )

                        if let valuesByIndex = viewModel.quantityDosageValues(for: draftMedicationID),
                           var writableMedicationInstance = medicationInstance as? any QuantityDosageValuesWritable {
                            writableMedicationInstance.setQuantityDosageValues(valuesByIndex)
                            if let typedMedicationInstance = writableMedicationInstance as? MI {
                                medicationInstance = typedMedicationInstance
                            }
                        }

                        if let quantityValue = viewModel.quantity(for: draftMedicationID),
                           var quantityWritableMedicationInstance = medicationInstance as? any QuantityWritableMedicationInstance {
                            quantityWritableMedicationInstance.quantity = quantityValue
                            if let typedMedicationInstance = quantityWritableMedicationInstance as? MI {
                                medicationInstance = typedMedicationInstance
                            }
                        }

                        if let endDate,
                           var endDateWritableMedicationInstance = medicationInstance as? any EndDateWritableMedicationInstance {
                            endDateWritableMedicationInstance.endDate = endDate
                            if let typedMedicationInstance = endDateWritableMedicationInstance as? MI {
                                medicationInstance = typedMedicationInstance
                            }
                        }

                        let medicationID = AnyHashable(medicationInstance.id)
                        if let valuesByIndex = viewModel.quantityDosageValues(for: draftMedicationID) {
                            for (index, value) in valuesByIndex {
                                viewModel.setQuantityDosageValue(value, at: index, for: medicationID)
                            }
                        }
                        if let quantityValue = viewModel.quantity(for: draftMedicationID) {
                            viewModel.setQuantity(quantityValue, for: medicationID)
                        }

                        viewModel.clearQuantityDosageValues(for: draftMedicationID)
                        viewModel.clearQuantity(for: draftMedicationID)

                        viewModel.medicationInstances.append(medicationInstance)
                        viewModel.medicationInstances.sort()
                        isPresented = false
                    },
                    label: {
                        Text("Add Medication", bundle: .module)
                            .frame(maxWidth: .infinity, minHeight: 38)
                    }
                )
                    .buttonStyle(.borderedProminent)
            }
                .padding()
                .background {
                    Color(uiColor: .systemGroupedBackground)
                        .edgesIgnoringSafeArea(.bottom)
                }
        }
            .navigationTitle("Medication Schedule")
    }

    private var supportsEndDate: Bool {
        MI.self is EndDateWritableMedicationInstance.Type
    }

    private var titleSection: some View {
        Section {
            HStack {
                Spacer()
                VStack(alignment: .center) {
                    Image(systemName: "calendar")
                        .resizable()
                        .accessibilityHidden(true)
                        .foregroundColor(.accentColor)
                        .scaledToFit()
                        .frame(width: 70, height: 100)
                    Text("When will you take \(medicationOption.localizedDescription) (\(dosage.localizedDescription))?", bundle: .module)
                        .multilineTextAlignment(.center)
                        .font(.title2)
                }
                Spacer()
            }
        }
    }


    init(
        medicationOption: MI.InstanceType,
        dosage: MI.InstanceDosage,
        draftMedicationID: AnyHashable,
        isPresented: Binding<Bool>
    ) {
        self.medicationOption = medicationOption
        self.dosage = dosage
        self.draftMedicationID = draftMedicationID
        self._isPresented = isPresented
        self._endDate = State(initialValue: nil)
    }
}
