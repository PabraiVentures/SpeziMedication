//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SwiftUI


struct EditDosage<MI: MedicationInstance>: View {
    @Environment(InternalMedicationSettingsViewModel<MI>.self) private var viewModel

    @Binding private var dosage: MI.InstanceDosage
    @State private var editableDosageValues: [Int: Double] = [:]
    @State private var editableDosageTexts: [Int: String] = [:]

    private let medication: MI.InstanceType
    private let medicationInstanceID: AnyHashable?
    private let initialDosage: MI.InstanceDosage?

    private static var dosageFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = 0
        return formatter
    }


    private var supportsQuantityDosage: Bool {
        medication.dosages.allSatisfy { $0 is any QuantityDosage }
    }

    var body: some View {
        if supportsQuantityDosage {
            quantityDosageRows
        } else {
            defaultDosagePicker
        }
    }

    @ViewBuilder private var defaultDosagePicker: some View {
        Picker(String(localized: "Dosage: \(medication.localizedDescription)", bundle: .module), selection: $dosage) {
            ForEach(medication.dosages, id: \.self) { dosage in
                if viewModel.duplicateOf(medication: medication, dosage: dosage) && initialDosage != dosage {
                    HStack(spacing: 6) {
                        VStack(alignment: .leading) {
                            Text(dosage.localizedDescription)
                            Text("Medication with this dosage already exists.", bundle: .module)
                                .multilineTextAlignment(.leading)
                                .font(.caption)
                        }
                            .foregroundStyle(Color.secondary)
                            .disabled(true)
                        Spacer()
                    }
                        .padding(.vertical, 11) // Unfortunate workaround as we can not disable touch in Pickers.
                        .padding(.horizontal, 100)
                        .contentShape(Rectangle())
                        .onTapGesture {}
                        .padding(.vertical, -11)
                        .padding(.horizontal, -100)
                } else {
                    Text(dosage.localizedDescription)
                        .tag(dosage)
                }
            }
        }
            .pickerStyle(.inline)
            .accessibilityIdentifier(String(localized: "Dosage Picker", bundle: .module))
            .onChange(of: dosage) {
                viewModel.medicationInstances.sort()
            }
    }

    @ViewBuilder private var quantityDosageRows: some View {
        ForEach(Array(medication.dosages.enumerated()), id: \.offset) { index, option in
            HStack {
                TextField(
                    "Value",
                    text: editableTextBinding(for: index)
                )
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.leading)
                .frame(width: 44, alignment: .leading)

                Text(editableUnitLabel(for: option))

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .onAppear {
            initializeEditableValues()
        }
        .onDisappear {
            persistAllQuantityValuesToCache()
        }
    }

    private func editableTextBinding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                if let text = editableDosageTexts[index] {
                    return text
                }

                let value: Double
                if let storedValue = editableDosageValues[index] {
                    value = storedValue
                } else if index < medication.dosages.count,
                          let quantityDosage = medication.dosages[index] as? any QuantityDosage {
                    value = quantityDosage.dosageValue
                } else {
                    value = 1
                }

                return formatDosageValue(value)
            },
            set: { newText in
                editableDosageTexts[index] = newText

                guard let parsedValue = parseDosageValue(newText) else {
                    return
                }

                let normalizedValue = max(0, parsedValue)
                editableDosageValues[index] = normalizedValue

                if let medicationInstanceID,
                   index < medication.dosages.count,
                   let quantityDosage = medication.dosages[index] as? any QuantityDosage {
                    viewModel.setQuantityDosageValue(normalizedValue, at: index, for: medicationInstanceID)
                }

                guard index < medication.dosages.count else {
                    return
                }

                dosage = editableDosage(for: medication.dosages[index], index: index)
                viewModel.medicationInstances.sort()
            }
        )
    }

    private func parseDosageValue(_ text: String) -> Double? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return nil
        }

        let normalized = trimmedText.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    private func formatDosageValue(_ value: Double) -> String {
        Self.dosageFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func editableUnitLabel(for dosage: MI.InstanceDosage) -> String {
        (dosage as? any QuantityDosage)?.dosageUnit ?? dosage.localizedDescription
    }

    private func editableDosage(for dosage: MI.InstanceDosage, index: Int) -> MI.InstanceDosage {
        guard var quantityDosage = dosage as? any QuantityDosage else {
            return dosage
        }

        quantityDosage.dosageValue = editableDosageValues[index] ?? quantityDosage.dosageValue
        return quantityDosage as? MI.InstanceDosage ?? dosage
    }

    private func initializeEditableValues() {
        guard editableDosageValues.isEmpty else {
            return
        }

        let cachedValuesByIndex: [Int: Double]
        if let medicationInstanceID {
            cachedValuesByIndex = viewModel.quantityDosageValues(for: medicationInstanceID) ?? [:]
        } else {
            cachedValuesByIndex = [:]
        }

        for (index, option) in medication.dosages.enumerated() {
            guard let quantityDosage = option as? any QuantityDosage else {
                continue
            }

            let value: Double
            if let cachedValue = cachedValuesByIndex[index] {
                value = cachedValue
            } else {
                value = quantityDosage.dosageValue
            }

            editableDosageValues[index] = value
            editableDosageTexts[index] = formatDosageValue(value)
        }
    }


    private func persistAllQuantityValuesToCache() {
        guard let medicationInstanceID else {
            return
        }

        for (index, option) in medication.dosages.enumerated() {
            guard option is any QuantityDosage else {
                continue
            }

            if let value = editableDosageValues[index] {
                viewModel.setQuantityDosageValue(value, at: index, for: medicationInstanceID)
                continue
            }

            if let text = editableDosageTexts[index],
               let parsedValue = parseDosageValue(text) {
                let normalizedValue = max(0, parsedValue)
                editableDosageValues[index] = normalizedValue
                viewModel.setQuantityDosageValue(normalizedValue, at: index, for: medicationInstanceID)
            }
        }
    }


    init(
        dosage: Binding<MI.InstanceDosage>,
        medication: MI.InstanceType,
        medicationInstanceID: AnyHashable? = nil,
        initialDosage: MI.InstanceDosage
    ) {
        self._dosage = dosage
        self.medication = medication
        self.medicationInstanceID = medicationInstanceID
        self.initialDosage = initialDosage
    }

    init(dosage: Binding<MI.InstanceDosage>, medication: MI.InstanceType) {
        self._dosage = dosage
        self.medication = medication
        self.medicationInstanceID = nil
        self.initialDosage = nil
    }
}
