//
//  KeyboardToolbar.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI

/// View modifier that adds a toolbar above the keyboard with Done, Previous, and Next buttons
struct KeyboardToolbarModifier: ViewModifier {
    @FocusState.Binding var focusedField: Int?
    let currentField: Int
    let fieldCount: Int
    let onDone: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .focused($focusedField, equals: currentField)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    HStack(spacing: 16) {
                        // Previous button
                        Button {
                            moveToPreviousField()
                        } label: {
                            Image(systemName: "chevron.up")
                                .font(.body.weight(.medium))
                        }
                        .disabled(currentField == 0)

                        // Next button
                        Button {
                            moveToNextField()
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.body.weight(.medium))
                        }
                        .disabled(currentField == fieldCount - 1)

                        Spacer()

                        // Done button
                        Button("Done") {
                            if let onDone = onDone {
                                onDone()
                            } else {
                                focusedField = nil
                            }
                        }
                        .font(.body.weight(.semibold))
                    }
                }
            }
    }

    private func moveToPreviousField() {
        HapticManager.shared.trigger(.selection)
        if currentField > 0 {
            focusedField = currentField - 1
        }
    }

    private func moveToNextField() {
        HapticManager.shared.trigger(.selection)
        if currentField < fieldCount - 1 {
            focusedField = currentField + 1
        }
    }
}

extension View {
    /// Adds a keyboard toolbar with Done, Previous, and Next navigation buttons
    /// - Parameters:
    ///   - focusedField: Binding to the currently focused field index
    ///   - currentField: The index of this field
    ///   - fieldCount: Total number of fields in the form
    ///   - onDone: Optional custom action when Done is tapped (defaults to dismissing keyboard)
    func keyboardToolbar(
        focusedField: FocusState<Int?>.Binding,
        currentField: Int,
        fieldCount: Int,
        onDone: (() -> Void)? = nil
    ) -> some View {
        modifier(KeyboardToolbarModifier(
            focusedField: focusedField,
            currentField: currentField,
            fieldCount: fieldCount,
            onDone: onDone
        ))
    }
}