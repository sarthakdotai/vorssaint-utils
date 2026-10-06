// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import CoreGraphics

/// Home: what is happening now, the latest notification, and every page one
/// click away. It reads the activities the closed island already tracks, so
/// both always agree on what is live.
enum NotchHomeSupport {
    /// Narrower than this, a card's reading is cut too short to be useful.
    static let minimumCardWidth: CGFloat = 132
    static let maximumCards = 3

    /// How many cards share the row at `width`, never fewer than one.
    static func cardCapacity(width: CGFloat) -> Int {
        guard width.isFinite, width > 0 else { return 1 }
        let fitting = Int((width + NotchLayout.rowSpacing) / (minimumCardWidth + NotchLayout.rowSpacing))
        return min(maximumCards, max(1, fitting))
    }

    /// The live activities, in the order the closed island ranks them, one
    /// card per page they open: Keep Awake opens Controls, so a second
    /// activity on the same page would only repeat its destination.
    static func cards(_ activities: [NotchCompactActivity], width: CGFloat) -> [NotchCompactActivity] {
        var pages = Set<NotchModule>()
        let distinct = activities.filter { pages.insert($0.module).inserted }
        return Array(distinct.prefix(cardCapacity(width: width)))
    }

    /// Every enabled page but Home itself, in the person's own order.
    static func dock(_ modules: [NotchModule]) -> [NotchModule] {
        modules.filter { $0 != .home }
    }

    /// The page's height: cards, an optional notification row, then the dock.
    static func height(hasNotice: Bool) -> CGFloat {
        NotchLayout.homeCardHeight + NotchLayout.rowSpacing
            + (hasNotice ? NotchLayout.homeNoticeHeight + NotchLayout.rowSpacing : 0)
            + NotchLayout.homeDockHeight
    }
}
