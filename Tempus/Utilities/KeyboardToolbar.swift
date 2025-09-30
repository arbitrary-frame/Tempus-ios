//
//  KeyboardToolbar.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI

extension View {
    /// Adds a keyboard toolbar with Done, Previous, and Next navigation buttons
    func keyboardToolbar<T: Hashable>(
        focusedField: FocusState<T?>.Binding,
        allFields: [T],
        onDone: (() -> Void)? = nil
    ) -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                print("🎹 Keyboard toolbar created with \(allFields.count) fields")
                HStack(spacing: 16) {
                    // Previous button
                    Button {
                        HapticManager.shared.trigger(.selection)
                        moveToPreviousField(focusedField: focusedField, allFields: allFields)
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.body.weight(.medium))
                    }
                    .disabled(!canMovePrevious(focusedField: focusedField.wrappedValue, allFields: allFields))

                    // Next button
                    Button {
                        HapticManager.shared.trigger(.selection)
                        moveToNextField(focusedField: focusedField, allFields: allFields)
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.body.weight(.medium))
                    }
                    .disabled(!canMoveNext(focusedField: focusedField.wrappedValue, allFields: allFields))

                    Spacer()

                    // Done button
                    Button("Done") {
                        HapticManager.shared.trigger(.light)
                        if let onDone = onDone {
                            onDone()
                        } else {
                            focusedField.wrappedValue = nil
                        }
                    }
                    .font(.body.weight(.semibold))
                }
            }
        }
    }

    private func canMovePrevious<T: Hashable>(focusedField: T?, allFields: [T]) -> Bool {
        guard let focused = focusedField,
              let currentIndex = allFields.firstIndex(of: focused) else {
            return false
        }
        return currentIndex > 0
    }

    private func canMoveNext<T: Hashable>(focusedField: T?, allFields: [T]) -> Bool {
        guard let focused = focusedField,
              let currentIndex = allFields.firstIndex(of: focused) else {
            return false
        }
        return currentIndex < allFields.count - 1
    }

    private func moveToPreviousField<T: Hashable>(
        focusedField: FocusState<T?>.Binding,
        allFields: [T]
    ) {
        guard let focused = focusedField.wrappedValue,
              let currentIndex = allFields.firstIndex(of: focused),
              currentIndex > 0 else {
            return
        }
        focusedField.wrappedValue = allFields[currentIndex - 1]
    }

    private func moveToNextField<T: Hashable>(
        focusedField: FocusState<T?>.Binding,
        allFields: [T]
    ) {
        guard let focused = focusedField.wrappedValue,
              let currentIndex = allFields.firstIndex(of: focused),
              currentIndex < allFields.count - 1 else {
            return
        }
        focusedField.wrappedValue = allFields[currentIndex + 1]
    }
}