// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum NotchHomeTests {
    static func run(_ suite: TestSuite) {
        let home = NotchHomeSupport.self

        suite.expect(home.cardCapacity(width: 0) == 1 && home.cardCapacity(width: .nan) == 1,
                     "a degenerate width still leaves room for one card")
        suite.expect(home.cardCapacity(width: home.minimumCardWidth * 2 + NotchLayout.rowSpacing) == 2,
                     "two cards share a row exactly as wide as both and their gap")
        suite.expect(home.cardCapacity(width: home.minimumCardWidth * 2 + NotchLayout.rowSpacing - 1) == 1,
                     "a card never shrinks below its readable width to fit another")
        suite.expect(home.cardCapacity(width: 4000) == home.maximumCards, "a wide island stops at three cards")

        let wide: CGFloat = 600
        suite.expect(home.cards([], width: wide).isEmpty, "with nothing live there are no cards")
        suite.expect(home.cards([.music, .timer, .agents], width: wide) == [.music, .timer, .agents],
                     "live activities keep the closed island's ranking")
        suite.expect(home.cards([.music, .timer, .agents, .calendar], width: wide) == [.music, .timer, .agents],
                     "only the cards that fit are shown, the highest ranked first")
        suite.expect(home.cards([.music, .timer], width: home.minimumCardWidth) == [.music],
                     "a narrow island shows the top activity alone")
        suite.expect(home.cards([.keepAwake, .timer], width: wide).map(\.module) == [.controls, .timer],
                     "Keep Awake opens Controls, which has no live card of its own")

        suite.expect(home.dock([.home, .controls, .music]) == [.controls, .music],
                     "the dock lists every page but Home itself")
        suite.expect(home.dock([.music, .home, .controls]) == [.music, .controls],
                     "the dock keeps the person's page order")

        let withNotice = home.height(hasNotice: true)
        let without = home.height(hasNotice: false)
        suite.expect(withNotice - without == NotchLayout.homeNoticeHeight + NotchLayout.rowSpacing,
                     "a notification adds exactly its row and gap")
        suite.expect(withNotice <= NotchLayout.compactContentHeight,
                     "Home fits the compact island without scrolling, notification included")

        suite.expect(NotchModule.allCases.first == .home, "Home leads the default page order")
        let keys = NotchModule.allCases.map(\.shortcutKey)
        suite.expect(Set(keys).count == keys.count, "Home's shortcut takes no other page's key")
        suite.expect(NotchModule.home.isAvailable(in: UserDefaults(suiteName: "com.vorssaint.tests.notch-home")!),
                     "Home needs no optional feature")
    }
}
