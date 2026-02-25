//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziViews
import SwiftUI


struct EditMedication<MI: MedicationInstance>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(InternalMedicationSettingsViewModel<MI>.self) private var viewModel

    @Binding private var medicationInstance: MI
    @State private var quantityText = ""
    @State private var editableEndDate: Date?

    private static var quantityFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = 0
        return formatter
    }

    private var supportsExplicitQuantity: Bool {
        medicationInstance is any QuantityWritableMedicationInstance
    }

    private var supportsQuantityDosage: Bool {
        medicationInstance.type.dosages.allSatisfy { $0 is any QuantityDosage }
    }

    private var supportsNewQuantityDosageFlow: Bool {
        supportsExplicitQuantity && supportsQuantityDosage
    }

    private var supportsEndDate: Bool {
        medicationInstance is any EndDateWritableMedicationInstance
    }


    var body: some View {
        VStack {
            Form {
                Section(String(localized: "Dosage", bundle: .module)) {
                    EditDosage<MI>(
                        dosage: $medicationInstance.dosage,
                        medication: medicationInstance.type,
                        medicationInstanceID: AnyHashable(medicationInstance.id),
                        initialDosage: medicationInstance.dosage
                    )
                        .labelsHidden()
                }
                if supportsNewQuantityDosageFlow {
                    Section("Quantity") {
                        HStack {
                            TextField("Value", text: quantityBinding)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.leading)
                                .frame(width: 44, alignment: .leading)
                            Text("units")
                            Spacer()
                        }
                    }
                }
                Section(String(localized: "Schedule", bundle: .module)) {
                    EditFrequency(
                        frequency: $medicationInstance.schedule.frequency,
                        startDate: $medicationInstance.schedule.startDate,
                        endDate: supportsEndDate ? $editableEndDate : nil
                    )
                }
                Section(String(localized: "Schedule Times", bundle: .module)) {
                    EditScheduleTime(times: $medicationInstance.schedule.times)
                }
                Section {
                    Button(String(localized: "Delete", bundle: .module), role: .destructive) {
                        let id = medicationInstance.id
                        viewModel.medicationInstances.removeAll(where: { $0.id == id })
                        viewModel.clearQuantityDosageValues(for: AnyHashable(id))
                        viewModel.clearQuantity(for: AnyHashable(id))
                        dismiss()
                    }
                }
            }
        }
            .navigationTitle(medicationInstance.localizedDescription)
            .onAppear {
                initializeQuantityText()
                initializeEndDate()
            }
            .onChange(of: editableEndDate) {
                updateMedicationInstanceEndDate(editableEndDate)
            }
    }

    private var quantityBinding: Binding<String> {
        Binding(
            get: {
                quantityText
            },
            set: { newText in
                quantityText = newText
                guard let parsedValue = parseQuantityValue(newText) else {
                    return
                }

                let normalizedValue = max(0, parsedValue)
                let medicationID = AnyHashable(medicationInstance.id)
                viewModel.setQuantity(normalizedValue, for: medicationID)
                updateMedicationInstanceQuantity(normalizedValue)
                quantityText = formatQuantityValue(normalizedValue)
                viewModel.medicationInstances.sort()
            }
        )
    }

    private func initializeEndDate() {
        guard supportsEndDate else {
            editableEndDate = nil
            return
        }

        editableEndDate = (medicationInstance as? any EndDateWritableMedicationInstance)?.endDate
    }

    private func updateMedicationInstanceEndDate(_ newValue: Date?) {
        guard var writableMedicationInstance = medicationInstance as? any EndDateWritableMedicationInstance else {
            return
        }

        writableMedicationInstance.endDate = newValue
        if let typedMedicationInstance = writableMedicationInstance as? MI {
            medicationInstance = typedMedicationInstance
        }
    }

    private func initializeQuantityText() {
        guard supportsNewQuantityDosageFlow else {
            return
        }

        let medicationID = AnyHashable(medicationInstance.id)
        if let cachedQuantity = viewModel.quantity(for: medicationID) {
            quantityText = formatQuantityValue(cachedQuantity)
            updateMedicationInstanceQuantity(cachedQuantity)
            return
        }

        let currentQuantity = (medicationInstance as? any QuantityWritableMedicationInstance)?.quantity ?? 1
        let normalizedQuantity = max(0, currentQuantity ?? 1)
        quantityText = formatQuantityValue(normalizedQuantity)
        viewModel.setQuantity(normalizedQuantity, for: medicationID)
        updateMedicationInstanceQuantity(normalizedQuantity)
    }

    private func updateMedicationInstanceQuantity(_ value: Double) {
        guard var writableMedicationInstance = medicationInstance as? any QuantityWritableMedicationInstance else {
            return
        }

        writableMedicationInstance.quantity = value
        if let typedMedicationInstance = writableMedicationInstance as? MI {
            medicationInstance = typedMedicationInstance
        }
    }

    private func parseQuantityValue(_ text: String) -> Double? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return nil
        }

        let normalized = trimmedText.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    private func formatQuantityValue(_ value: Double) -> String {
        Self.quantityFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }


    init(medicationInstance: Binding<MI>) {
        self._medicationInstance = medicationInstance
    }
}
