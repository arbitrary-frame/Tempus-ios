//
//  NumberTextFieldWithToolbar.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import UIKit

/// Manages all text fields in a form for keyboard navigation
class TextFieldManager {
    var textFields: [Int: UITextField] = [:]

    var totalFieldCount: Int {
        // Return the highest registered field index + 1
        return (textFields.keys.max() ?? -1) + 1
    }

    func register(_ textField: UITextField, for index: Int) {
        textFields[index] = textField
        print("📝 Registered field \(index), total registered: \(textFields.count), totalFieldCount: \(totalFieldCount)")
    }

    func focusField(_ index: Int) {
        print("🎯 Trying to focus field \(index), registered fields: \(textFields.keys.sorted())")

        // If field exists, focus it immediately
        if let textField = textFields[index] {
            print("✅ Found field \(index), focusing")
            textField.becomeFirstResponder()
        } else {
            print("❌ Field \(index) not found, will retry")
            // Field doesn't exist yet (SwiftUI hasn't rendered it)
            // Wait a bit and try again
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                if let textField = self?.textFields[index] {
                    print("✅ Retry: Found field \(index), focusing")
                    textField.becomeFirstResponder()
                } else {
                    print("❌ Retry: Field \(index) still not found. Registered: \(self?.textFields.keys.sorted() ?? [])")
                }
            }
        }
    }

    func dismissKeyboard() {
        textFields.values.forEach { $0.resignFirstResponder() }
    }
}

/// A text field optimized for number entry with a toolbar containing Previous, Next, and Done buttons
struct NumberTextFieldWithToolbar: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    let fieldIndex: Int
    let totalFields: Int
    let manager: TextFieldManager

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.borderStyle = .roundedRect
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)

        // Register with manager
        manager.register(textField, for: fieldIndex)

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
        context.coordinator.previousButton = previousButton

        // Next button
        let nextButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.down"),
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.nextTapped)
        )
        context.coordinator.nextButton = nextButton

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

        context.coordinator.updateButtonStates()

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        // Only update text if the field is not currently being edited
        // This prevents the "2" -> "2.0" issue while typing
        if !uiView.isFirstResponder && uiView.text != text {
            uiView.text = text
        }
        context.coordinator.updateButtonStates()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            text: $text,
            fieldIndex: fieldIndex,
            totalFields: totalFields,
            manager: manager
        )
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        let fieldIndex: Int
        let manager: TextFieldManager

        var previousButton: UIBarButtonItem?
        var nextButton: UIBarButtonItem?

        init(
            text: Binding<String>,
            fieldIndex: Int,
            totalFields: Int, // Kept for compatibility but not used
            manager: TextFieldManager
        ) {
            self._text = text
            self.fieldIndex = fieldIndex
            self.manager = manager
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
            text = textField.text ?? ""
        }

        func updateButtonStates() {
            let totalFields = manager.totalFieldCount
            previousButton?.isEnabled = fieldIndex > 0
            nextButton?.isEnabled = fieldIndex < totalFields - 1
            print("🔄 Updated button states for field \(fieldIndex): prev=\(previousButton?.isEnabled ?? false), next=\(nextButton?.isEnabled ?? false), totalFields=\(totalFields)")
        }

        @objc func previousTapped() {
            HapticManager.shared.trigger(.selection)
            if fieldIndex > 0 {
                print("⬆️ Previous from \(fieldIndex) to \(fieldIndex - 1)")
                manager.focusField(fieldIndex - 1)
            }
        }

        @objc func nextTapped() {
            HapticManager.shared.trigger(.selection)
            let totalFields = manager.totalFieldCount
            if fieldIndex < totalFields - 1 {
                print("⬇️ Next from \(fieldIndex) to \(fieldIndex + 1)")
                manager.focusField(fieldIndex + 1)
            } else {
                print("⛔ Next blocked: fieldIndex=\(fieldIndex), totalFields=\(totalFields)")
            }
        }

        @objc func doneTapped() {
            HapticManager.shared.trigger(.light)
            manager.dismissKeyboard()
        }
    }
}