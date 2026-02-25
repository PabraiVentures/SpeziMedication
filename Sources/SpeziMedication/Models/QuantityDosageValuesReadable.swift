//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Optional capability for medication instances exposing persisted dosage values by index.
public protocol QuantityDosageValuesReadable {
    /// Persisted dosage values ordered by dosage index.
    var dosageValues: [Double]? { get }
}
