//
//  AppearanceSettings.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/8/26.
//

import Foundation
internal import Combine
import SwiftUI

enum ThemeMode: String, CaseIterable, Identifiable {
  case system
  case light
  case dark

  var id: String { rawValue }

  var preferredColorScheme: ColorScheme? {
    switch self {
    case .system:
      return nil
    case .light:
      return .light
    case .dark:
      return .dark
    }
  }
}

@MainActor
final class AppearanceSettings: ObservableObject {
  private static let themeModeStorageKey = "appearance.themeMode"
  private let userDefaults: UserDefaults

  @Published private(set) var themeMode: ThemeMode {
    didSet {
      userDefaults.set(themeMode.rawValue, forKey: Self.themeModeStorageKey)
    }
  }

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults

    if
      let rawValue = userDefaults.string(forKey: Self.themeModeStorageKey),
      let storedMode = ThemeMode(rawValue: rawValue)
    {
      themeMode = storedMode
    } else {
      themeMode = .system
    }
  }

  var preferredColorScheme: ColorScheme? {
    themeMode.preferredColorScheme
  }

  var useSystem: Bool {
    themeMode == .system
  }

  var isDarkModeEnabled: Bool {
    themeMode == .dark
  }

  func setUseSystem(_ enabled: Bool, currentVisualScheme: ColorScheme) {
    if enabled {
      themeMode = .system
      return
    }

    guard themeMode == .system else {
      return
    }

    themeMode = currentVisualScheme == .dark ? .dark : .light
  }

  func setDarkMode(_ enabled: Bool) {
    themeMode = enabled ? .dark : .light
  }
}
