//
//  AppGroupUserDefaults.swift
//  Tempus
//
//  Created by Ronak Pattani on 01/10/2025.
//

import SwiftUI
import Combine

/// Shared UserDefaults for App Group to share data between app and widgets
extension UserDefaults {
    static let shared = UserDefaults(suiteName: "group.tempus-ios.Tempus")!
}

/// Custom property wrapper for App Group UserDefaults
@propertyWrapper
struct AppGroupStorage<Value>: DynamicProperty {
    @ObservedObject private var storage: Storage<Value>

    var wrappedValue: Value {
        get { storage.value }
        nonmutating set { storage.value = newValue }
    }

    var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }

    init(wrappedValue: Value, _ key: String) where Value == Int {
        storage = Storage(key: key, defaultValue: wrappedValue)
    }

    init(wrappedValue: Value, _ key: String) where Value == String {
        storage = Storage(key: key, defaultValue: wrappedValue)
    }

    init(wrappedValue: Value, _ key: String) where Value == Bool {
        storage = Storage(key: key, defaultValue: wrappedValue)
    }

    private class Storage<T>: ObservableObject {
        private let key: String
        private let defaultValue: T
        private var cancellable: AnyCancellable?

        @Published var value: T {
            didSet {
                setValue(value)
            }
        }

        init(key: String, defaultValue: T) {
            self.key = key
            self.defaultValue = defaultValue
            // Initialize value with default first, then load from UserDefaults
            self.value = defaultValue
            // Now load the actual value
            self.value = Self.getValue(key: key, defaultValue: defaultValue)

            // Listen for changes from other instances
            cancellable = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    let newValue = Self.getValue(key: self.key, defaultValue: self.defaultValue)
                    if self.value as? Int != newValue as? Int ||
                       self.value as? String != newValue as? String ||
                       self.value as? Bool != newValue as? Bool {
                        DispatchQueue.main.async {
                            self.value = newValue
                        }
                    }
                }
        }

        private static func getValue(key: String, defaultValue: T) -> T {
            if let intValue = UserDefaults.shared.value(forKey: key) as? Int, T.self == Int.self {
                return intValue as! T
            } else if let stringValue = UserDefaults.shared.string(forKey: key) as? T {
                return stringValue
            } else if let boolValue = UserDefaults.shared.value(forKey: key) as? Bool, T.self == Bool.self {
                return boolValue as! T
            }
            return defaultValue
        }

        private func setValue(_ value: T) {
            if let intValue = value as? Int {
                UserDefaults.shared.set(intValue, forKey: key)
            } else if let stringValue = value as? String {
                UserDefaults.shared.set(stringValue, forKey: key)
            } else if let boolValue = value as? Bool {
                UserDefaults.shared.set(boolValue, forKey: key)
            }
        }
    }
}
