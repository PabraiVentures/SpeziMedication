//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SwiftUI


struct MedicationList<MI: MedicationInstance>: View {
    @Environment(InternalMedicationSettingsViewModel<MI>.self) private var viewModel

    private static var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = 0
        return formatter
    }


    var body: some View {
        @Bindable var viewModel = viewModel
        List {
            ForEach(Array(viewModel.medicationInstances.indices), id: \.self) { index in
                let medicationBinding = $viewModel.medicationInstances[index]
                NavigationLink {
                    EditMedication(medicationInstance: medicationBinding)
                        .environment(viewModel)
                } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(medicationBinding.wrappedValue.localizedDescription)
                            .font(.headline)
                        Text(subtitleText(for: medicationBinding.wrappedValue))
                            .font(.subheadline)
                    }
                }
            }
                .onDelete { offsets in
                    for offset in offsets {
                        let medicationID = AnyHashable(viewModel.medicationInstances[offset].id)
                        withAnimation {
                            _ = viewModel.medicationInstances.remove(at: offset)
                            viewModel.clearQuantityDosageValues(for: medicationID)
                            viewModel.clearQuantity(for: medicationID)
                        }
                    }
                }
        }
    }

    private func subtitleText(for medicationInstance: MI) -> String {
        guard supportsNewQuantityDosageFlow(for: medicationInstance) else {
            return medicationInstance.dosage.localizedDescription
        }

        let medicationID = AnyHashable(medicationInstance.id)
        let cachedValuesByIndex = viewModel.quantityDosageValues(for: medicationID) ?? [:]
        let persistedValues = (medicationInstance as? any QuantityDosageValuesReadable)?.dosageValues ?? []

        let dosageSegments = medicationInstance.type.dosages.enumerated().compactMap { index, dosage -> String? in
            guard let quantityDosage = dosage as? any QuantityDosage else {
                return nil
            }

            let value = cachedValuesByIndex[index] ?? (index < persistedValues.count ? persistedValues[index] : quantityDosage.dosageValue)
            let valueText = formattedMedicationNumber(value)
            let unitText = quantityDosage.dosageUnit.trimmingCharacters(in: .whitespacesAndNewlines)
            if unitText.isEmpty {
                return valueText
            }

            return "\(valueText) \(unitText)"
        }

        guard !dosageSegments.isEmpty else {
            return medicationInstance.dosage.localizedDescription
        }

        let resolvedQuantity = max(
            0,
            viewModel.quantity(for: medicationID)
                ?? (medicationInstance as? any QuantityWritableMedicationInstance)?.quantity
                ?? 1
        )
        let quantitySegment = "\(formattedMedicationNumber(resolvedQuantity)) units"

        return (dosageSegments + [quantitySegment]).joined(separator: ", ")
    }

    private func supportsNewQuantityDosageFlow(for medicationInstance: MI) -> Bool {
        medicationInstance is any QuantityWritableMedicationInstance
            && medicationInstance.type.dosages.allSatisfy { $0 is any QuantityDosage }
    }

    private func formattedMedicationNumber(_ number: Double) -> String {
        Self.numberFormatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}
