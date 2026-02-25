//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Optional capability for medication instances that expose an editable schedule end date.
public protocol EndDateWritableMedicationInstance {
    /// End date of the medication schedule.
    var endDate: Date? { get set }
}
