//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Optional capability for medication instances that expose a dedicated quantity value.
public protocol QuantityWritableMedicationInstance {
    /// Quantity value associated with the medication instance.
    var quantity: Double? { get set }
}
