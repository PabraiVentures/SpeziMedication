//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Dosage of a medication.
///
/// Defines the dosage of a ``MedicationInstance`` as a subset of the ``Medication/dosages`` of a ``Medication``.
public protocol Dosage: Codable, Hashable {
/// Localized description of the dosage.
    var localizedDescription: String { get }
}


/// Enum-style dosage, where one option is selected from a list.
public protocol EnumDosage: Dosage {}


/// Quantity-style dosage, where each dosage unit has an editable numeric value.
public protocol QuantityDosage: Dosage {
    /// Numeric value of the dosage.
    var dosageValue: Double { get set }
    /// Unit label of the dosage (e.g., mg, mg/mL).
    var dosageUnit: String { get set }
}


/// Backward-compatible alias for quantity-based dosage workflows.
public typealias EditableDosage = QuantityDosage
