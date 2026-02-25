//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziViews
import SwiftUI


struct AddMedicationDosage<MI: MedicationInstance>: View {
    @Environment(InternalMedicationSettingsViewModel<MI>.self) private var viewModel

    @State private var dosage: MI.InstanceDosage
    @State private var quantityText = ""
    @Binding private var isPresented: Bool

    private let medicationOption: MI.InstanceType
    private let draftMedicationID: AnyHashable

    private static var quantityFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = 0
        return formatter
    }


    private var isDuplicate: Bool {
        viewModel.duplicateOf(medication: medicationOption, dosage: dosage)
    }

    private var supportsExplicitQuantity: Bool {
        MI.self is any QuantityWritableMedicationInstance.Type
    }

    private var supportsQuantityDosage: Bool {
        medicationOption.dosages.allSatisfy { $0 is any QuantityDosage }
    }

    private var supportsNewQuantityDosageFlow: Bool {
        supportsExplicitQuantity && supportsQuantityDosage
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    EditDosage<MI>(dosage: $dosage, medication: medicationOption, medicationInstanceID: draftMedicationID, initialDosage: dosage)
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
            }
            actionSection
        }
            .navigationTitle(medicationOption.localizedDescription)
            .onAppear {
                if let nonUsedDosage = medicationOption.dosages.first(where: {
                    !viewModel.duplicateOf(medication: medicationOption, dosage: $0)
                }) {
                    self.dosage = nonUsedDosage
                }

                initializeQuantityText()
            }
    }

    @MainActor @ViewBuilder private var actionSection: some View {
        VStack(alignment: .center) {
            if isDuplicate {
                Text("Medication with this dosage already exists.", bundle: .module)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            addMedicationSaveDosageButton
        }
            .disabled(isDuplicate)
            .padding()
            .background {
                Color(uiColor: .systemGroupedBackground)
                    .edgesIgnoringSafeArea(.bottom)
            }
            .navigationTitle(medicationOption.localizedDescription)
    }

    private var addMedicationSaveDosageButton: some View {
        NavigationLink(
            destination: {
                AddMedicationSchedule<MI>(
                    medicationOption: medicationOption,
                    dosage: dosage,
                    draftMedicationID: draftMedicationID,
                    isPresented: $isPresented
                )
            },
            label: {
                Text("Save Dosage", bundle: .module)
                    .frame(maxWidth: .infinity, minHeight: 38)
            }
        )
        .buttonStyle(.borderedProminent)
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
                viewModel.setQuantity(normalizedValue, for: draftMedicationID)
                quantityText = formatQuantityValue(normalizedValue)
            }
        )
    }

    private func initializeQuantityText() {
        guard supportsNewQuantityDosageFlow else {
            return
        }

        if let cachedQuantity = viewModel.quantity(for: draftMedicationID) {
            quantityText = formatQuantityValue(cachedQuantity)
            return
        }

        let defaultQuantity = 1.0
        quantityText = formatQuantityValue(defaultQuantity)
        viewModel.setQuantity(defaultQuantity, for: draftMedicationID)
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


    init(medicationOption: MI.InstanceType, isPresented: Binding<Bool>) {
        self.medicationOption = medicationOption
        self._isPresented = isPresented
        self.draftMedicationID = AnyHashable(UUID())

        guard let initialDosage = medicationOption.dosages.first else {
            fatalError("No dosage options for the medication: \(medicationOption)")
        }
        self._dosage = State(initialValue: initialDosage)
    }
}
