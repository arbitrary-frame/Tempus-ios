//
//  NumberTextFieldWithToolbar.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import UIKit

/// A text field optimized for number entry with a toolbar containing Previous, Next, and Done buttons
struct NumberTextFieldWithToolbar: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    @FocusState.Binding var focusedField: Int?
    let currentField: Int
    let fieldCount: Int
    let onPrevious: (() -> Void)?
    let onNext: (() -> Void)?
    let onDone: (() -> Void)?

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.borderStyle = .roundedRect
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)

        // Create toolbar
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        // Previous button
        let previousButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.up"),
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.previousTapped)
        )
        previousButton.isEnabled = currentField > 0

        // Next button
        let nextButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.down"),
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.nextTapped)
        )
        nextButton.isEnabled = currentField < fieldCount - 1

        // Flexible space
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        // Done button
        let doneButton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: context.coordinator,
            action: #selector(Coordinator.doneTapped)
        )

        toolbar.items = [previousButton, nextButton, flexSpace, doneButton]
        textField.inputAccessoryView = toolbar

        // Store buttons in coordinator for later updates
        context.coordinator.previousButton = previousButton
        context.coordinator.nextButton = nextButton

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        // Only update text if different to avoid cursor issues
        if uiView.text != text {
            uiView.text = text
        }

        // Update button states
        context.coordinator.previousButton?.isEnabled = currentField > 0
        context.coordinator.nextButton?.isEnabled = currentField < fieldCount - 1

        // Manage focus - wrap in async to avoid conflicts during SwiftUI update cycle
        DispatchQueue.main.async {
            if self.focusedField == self.currentField {
                // This field should be focused
                if !uiView.isFirstResponder {
                    uiView.becomeFirstResponder()
                }
            } else {
                // This field should NOT be focused
                if uiView.isFirstResponder {
                    uiView.resignFirstResponder()
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            text: $text,
            focusedField: $focusedField,
            currentField: currentField,
            fieldCount: fieldCount,
            onPrevious: onPrevious,
            onNext: onNext,
            onDone: onDone
        )
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        @FocusState.Binding var focusedField: Int?
        let currentField: Int
        let fieldCount: Int
        let onPrevious: (() -> Void)?
        let onNext: (() -> Void)?
        let onDone: (() -> Void)?

        var previousButton: UIBarButtonItem?
        var nextButton: UIBarButtonItem?

        init(
            text: Binding<String>,
            focusedField: FocusState<Int?>.Binding,
            currentField: Int,
            fieldCount: Int,
            onPrevious: (() -> Void)?,
            onNext: (() -> Void)?,
            onDone: (() -> Void)?
        ) {
            self._text = text
            self._focusedField = focusedField
            self.currentField = currentField
            self.fieldCount = fieldCount
            self.onPrevious = onPrevious
            self.onNext = onNext
            self.onDone = onDone
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
            text = textField.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            focusedField = currentField
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            if focusedField == currentField {
                focusedField = nil
            }
        }

        @objc func previousTapped() {
            HapticManager.shared.trigger(.selection)
            if let onPrevious = onPrevious {
                onPrevious()
            } else if currentField > 0 {
                // Use async to ensure SwiftUI processes the focus state change
                DispatchQueue.main.async {
                    self.focusedField = self.currentField - 1
                }
            }
        }

        @objc func nextTapped() {
            HapticManager.shared.trigger(.selection)
            if let onNext = onNext {
                onNext()
            } else if currentField < fieldCount - 1 {
                // Use async to ensure SwiftUI processes the focus state change
                DispatchQueue.main.async {
                    self.focusedField = self.currentField + 1
                }
            }
        }

        @objc func doneTapped() {
            HapticManager.shared.trigger(.light)
            if let onDone = onDone {
                onDone()
            } else {
                // Use async to ensure SwiftUI processes the focus state change
                DispatchQueue.main.async {
                    self.focusedField = nil
                }
            }
        }
    }
}