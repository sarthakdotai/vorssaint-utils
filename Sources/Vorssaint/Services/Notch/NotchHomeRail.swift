// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Ties Home's row to the stored tool history and the feature catalog, kept
/// apart from its rules so they can be tested without either.
extension NotchHomeSupport {
    static func rememberTool(_ item: QuickLauncherItem, in defaults: UserDefaults = .standard) {
        let history = defaults.stringArray(forKey: DefaultsKey.notchRecentTools) ?? []
        defaults.set(remember(item.rawValue, in: history), forKey: DefaultsKey.notchRecentTools)
    }

    static func rail(modules: [NotchModule], defaults: UserDefaults = .standard) -> [Slot] {
        let controls = NotchSupport.controls(in: defaults)
        let history = defaults.stringArray(forKey: DefaultsKey.notchRecentTools) ?? []
        let tool = recentTool(history, shortcuts: controls) {
            QuickLauncherItem(rawValue: $0)?.feature.isAvailable(in: defaults) == true
        }
        return rail(controls: controls, recentTool: tool, toolsPage: modules.contains(.tools))
    }
}
