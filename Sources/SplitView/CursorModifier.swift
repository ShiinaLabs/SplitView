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

/// Returns the native divider cursor on macOS 15 and later, with a deployment-safe
/// fallback for macOS 12 through 14. The selector lookup keeps this source buildable
/// with SDKs that predate the modern cursor declarations.
internal enum SplitterCursor {
    static var modernCursorAPIAvailable: Bool {
        guard #available(macOS 15.0, *) else { return false }
        let cursorClass = NSCursor.self as AnyObject
        return cursorClass.responds(to: NSSelectorFromString("columnResizeCursor"))
            && cursorClass.responds(to: NSSelectorFromString("rowResizeCursor"))
    }

    static func cursor(horizontal: Bool) -> NSCursor {
        let fallback = horizontal ? NSCursor.resizeLeftRight : NSCursor.resizeUpDown
        guard modernCursorAPIAvailable else { return fallback }

        let selectorName = horizontal ? "columnResizeCursor" : "rowResizeCursor"
        let selector = NSSelectorFromString(selectorName)
        let cursorClass = NSCursor.self as AnyObject
        return cursorClass.perform(selector)?.takeUnretainedValue() as? NSCursor ?? fallback
    }
}

extension View {
    internal func cursor(_ cursor: NSCursor) -> some View {
        modifier(CursorModifier(cursor: cursor))
    }
}

#endif
