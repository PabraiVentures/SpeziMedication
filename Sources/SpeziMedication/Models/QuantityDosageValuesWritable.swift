//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Optional capability for medication instances that can absorb per-index quantity dosage values.
public protocol QuantityDosageValuesWritable {
    /// Update the medication instance with quantity values keyed by dosage index.
    mutating func setQuantityDosageValues(_ valuesByIndex: [Int: Double])
}
