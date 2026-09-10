#if os(macOS)

import AppKit
import SwiftUI

/// Applies an AppKit cursor to the view's bounds.
internal struct CursorModifier: ViewModifier {
    let cursor: NSCursor

    func body(content: Content) -> some View {
        content.overlay(CursorView(cursor: cursor).allowsHitTesting(false))
    }
}

private struct CursorView: NSViewRepresentable {
    let cursor: NSCursor

    func makeNSView(context: Context) -> CursorNSView {
        CursorNSView(cursor: cursor)
    }

    func updateNSView(_ nsView: CursorNSView, context: Context) {
        nsView.cursor = cursor
    }
}

private final class CursorNSView: NSView {
    var cursor: NSCursor {
        didSet {
            if oldValue !== cursor {
                resetCursorRects()
            }
        }
    }

    init(cursor: NSCursor) {
        self.cursor = cursor
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: cursor)
    }
}

extension View {
    internal func cursor(_ cursor: NSCursor) -> some View {
        modifier(CursorModifier(cursor: cursor))
    }
}

#endif
