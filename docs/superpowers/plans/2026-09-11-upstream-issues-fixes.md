# Upstream Issues Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve the fork using the four actionable upstream issue groups already tracked in `ShiinaLabs/SplitView` issues #1–#4, while preserving the package's macOS 12, iOS 15, and Mac Catalyst 15 deployment floors.

**Architecture:** Keep the public Split/HSplit/VSplit APIs unchanged. Extract the orientation-dependent transition edge and fraction clamping decisions into small internal helpers so they can be tested without a UI harness; make default fraction holders stable across SwiftUI view reconstruction; replace deprecated `onChange` overloads with publisher-backed observation; and isolate the AppKit cursor implementation behind a macOS-only file while retaining the existing Catalyst fallback.

**Tech Stack:** Swift 5.8, SwiftUI, XCTest, AppKit only under `#if os(macOS)`, Swift Package Manager, Xcode demo targets.

**Spec:** Fork issues [#1](https://github.com/ShiinaLabs/SplitView/issues/1), [#2](https://github.com/ShiinaLabs/SplitView/issues/2), [#3](https://github.com/ShiinaLabs/SplitView/issues/3), and [#4](https://github.com/ShiinaLabs/SplitView/issues/4), each of which links to its upstream Issue or PR source.

**Status:** Implemented and verified in `codex/fix-upstream-issues`; fork PR [#5](https://github.com/ShiinaLabs/SplitView/pull/5) is open for review and remains unmerged.

## Global Constraints

- Preserve `.macOS(.v12)`, `.iOS(.v15)`, and `.macCatalyst(.v15)` support.
- Do not add runtime dependencies or change the public SplitView API.
- Do not post comments or messages to the upstream repository; only reference upstream URLs from our fork's issue/PR text.
- Every behavior change needs a focused regression test or a compile/build verification when the behavior is platform-only UI code.
- Do not merge the PR; leave it open for the user's review.

---

### Task 1: Add tested fraction and transition decisions

**Files:**
- Create: `Sources/SplitView/SplitViewUtilities.swift`
- Create: `Tests/SplitViewTests/SplitViewUtilitiesTests.swift`
- Modify: `Sources/SplitView/Split.swift:100-104,166-174,241-251`

**Interfaces:**
- Produces internal `SplitFraction.constrained(_:minPrimary:minSecondary:) -> CGFloat` for all runtime fraction updates.
- Produces internal `SplitTransition.edge(for:layout:) -> Edge` for direction-aware insertion/removal transitions.

- [ ] **Step 1: Write failing tests for clamping and orientation.**

```swift
import SwiftUI
import XCTest
@testable import SplitView

final class SplitViewUtilitiesTests: XCTestCase {
    func testConstrainedFractionHonorsBothMinimums() {
        XCTAssertEqual(SplitFraction.constrained(0.05, minPrimary: 0.2, minSecondary: 0.3), 0.2)
        XCTAssertEqual(SplitFraction.constrained(0.95, minPrimary: 0.2, minSecondary: 0.3), 0.7)
    }

    func testTransitionEdgesMatchSplitOrientation() {
        XCTAssertEqual(SplitTransition.edge(for: .primary, layout: .horizontal), .leading)
        XCTAssertEqual(SplitTransition.edge(for: .secondary, layout: .horizontal), .trailing)
        XCTAssertEqual(SplitTransition.edge(for: .primary, layout: .vertical), .top)
        XCTAssertEqual(SplitTransition.edge(for: .secondary, layout: .vertical), .bottom)
    }
}
```

- [ ] **Step 2: Run the focused test to verify the missing helper failure.**

Run: `swift test --filter SplitViewUtilitiesTests`

Expected: compilation fails because `SplitFraction` and `SplitTransition` have not been defined yet.

- [ ] **Step 3: Implement the minimal internal helpers.**

```swift
import SwiftUI

enum SplitFraction {
    static func constrained(_ value: CGFloat, minPrimary: CGFloat?, minSecondary: CGFloat?) -> CGFloat {
        min(1 - (minSecondary ?? 0), max((minPrimary ?? 0), value))
    }
}

enum SplitTransition {
    static func edge(for side: SplitSide, layout: SplitLayout) -> Edge {
        if layout == .horizontal {
            return side.isPrimary ? .leading : .trailing
        }
        return side.isPrimary ? .top : .bottom
    }
}
```

- [ ] **Step 4: Run the focused test to verify it passes.**

Run: `swift test --filter SplitViewUtilitiesTests`

Expected: 2 tests pass with 0 failures.

- [ ] **Step 5: Route Split's external and size-derived updates through the helper.**

Use `SplitFraction.constrained` in `setConstrainedFraction` and `fraction(for:in:)`. Observe `fraction.$value` with `onReceive`, clamp the incoming value, and wrap only external updates in `withAnimation`; drag updates continue to write local state directly.

- [ ] **Step 6: Add direction-aware transitions to the conditional panes.**

Apply `.transition(.move(edge: SplitTransition.edge(for: .primary, layout: layout.value)))` to the primary view and the corresponding secondary edge to the secondary view. Keep the splitter's insertion/removal tied to its existing `isDraggable()` condition and choose its edge from `hide.side ?? hide.oldSide ?? .secondary`, so both hiding and showing a primary or secondary side use the correct direction.

- [ ] **Step 7: Run the full unit test suite.**

Run: `swift test`

Expected: all existing and new tests pass with 0 failures.

- [ ] **Step 8: Commit the utility and Split behavior changes.**

```bash
git add Sources/SplitView/SplitViewUtilities.swift Sources/SplitView/Split.swift Tests/SplitViewTests/SplitViewUtilitiesTests.swift
git commit -m "fix: stabilize fraction updates and split transitions"
```

### Task 2: Stabilize default fraction ownership

**Files:**
- Modify: `Sources/SplitView/HSplit.swift:10-43`
- Modify: `Sources/SplitView/VSplit.swift:10-43`
- Modify: `Sources/SplitView/Split.swift:39-130`
- Modify: `Tests/SplitViewTests/SplitViewUtilitiesTests.swift`

**Interfaces:**
- Keeps the existing `FractionHolder` modifier and initializer signatures.
- Makes the holders created by default initializers state-owned, so SwiftUI view reconstruction does not reset an externally published fraction back to the initial value.

- [ ] **Step 1: Add a compile regression check for state-owned holder initialization.**

Use the existing package and demo build targets as the regression harness: the HSplit/VSplit private initializer must accept the property-wrapper backing storage, preserve every public modifier signature, and compile for all supported platforms.

- [ ] **Step 2: Change only default holder storage to `@StateObject` and initialize it from the existing private initializer values.**

Use `_fraction = StateObject(wrappedValue: fraction)` in the private initializers and retain the existing modifier data flow. Do not alter public method signatures or replace caller-owned holders.

- [ ] **Step 3: Run focused and full tests.**

Run: `swift test --filter SplitViewUtilitiesTests && swift test`

Expected: the focused regression and all existing tests pass.

- [ ] **Step 4: Commit the holder stability change.**

```bash
git add Sources/SplitView/HSplit.swift Sources/SplitView/VSplit.swift Sources/SplitView/Split.swift Tests/SplitViewTests/SplitViewUtilitiesTests.swift
git commit -m "fix: preserve default fraction holder state"
```

### Task 3: Remove deprecated observation and harden the cursor implementation

**Files:**
- Create: `Sources/SplitView/CursorModifier.swift`
- Modify: `Sources/SplitView/Splitter.swift:70-94`
- Modify: `Demo/SplitDemo/DemoSplitter.swift:64-106`
- Modify: `README.md:328-382`

**Interfaces:**
- Adds an internal macOS-only `cursor(_:)` view modifier backed by `NSViewRepresentable` cursor rects.
- Leaves Mac Catalyst on the existing hover path and leaves iOS without an AppKit reference.

- [ ] **Step 1: Add a source-level regression test that asserts no deprecated one-argument `onChange` calls remain in library/demo/docs sources.**

The test should read the checked-in source files from the package root when available and fail if it finds `.onChange(of:` in `Sources/SplitView`, `Demo/SplitDemo`, or the README custom splitter example. Keep the test deterministic and skip only when the package root cannot be resolved by XCTest.

- [ ] **Step 2: Run the focused test and confirm it fails against the current source.**

Run: `swift test --filter SplitViewUtilitiesTests.testNoDeprecatedOnChangeOverloadsRemain`

Expected: failure identifying the current deprecated observation calls.

- [ ] **Step 3: Replace one-argument observation with publisher-backed observation.**

Use `onReceive(fraction.$value)` in `Split` and `onReceive(styling.$previewHide)` in `Splitter`, the demo custom splitter, and both README branches. Preserve the existing state updates.

- [ ] **Step 4: Implement the macOS cursor modifier with update-safe cursor rects.**

Guard the file with `#if os(macOS)`, use `NSViewRepresentable`, initialize the cursor view with a non-optional cursor, update the cursor in `updateNSView`, and call `resetCursorRects` when the cursor changes. In `Splitter`, use the cursor-rect modifier with the deployment-safe `NSCursor.resizeLeftRight`/`resizeUpDown` cursors on macOS 12 and later; retain the current `NSCursor.push/pop` hover fallback only for Mac Catalyst. Mark the representable overlay as non-hit-testing so it cannot intercept the splitter drag gesture.

- [ ] **Step 5: Run focused tests and platform builds.**

Run: `swift test --filter SplitViewUtilitiesTests && swift build --sdk iphoneos --triple arm64-apple-ios15.0`

Expected: all focused tests pass and the iOS build succeeds without AppKit symbols.

- [ ] **Step 6: Commit observation and cursor changes.**

```bash
git add Sources/SplitView/CursorModifier.swift Sources/SplitView/Splitter.swift Demo/SplitDemo/DemoSplitter.swift README.md Tests/SplitViewTests/SplitViewUtilitiesTests.swift
git commit -m "fix: modernize observation and splitter cursors"
```

### Task 4: Integrate, review, and publish the fork PR

**Files:**
- Modify: `docs/superpowers/plans/2026-09-11-upstream-issues-fixes.md`
- Modify: Obsidian project notes outside the repository after the PR exists

- [ ] **Step 1: Inspect the combined diff and verify the task checklist.**

Run: `git diff origin/main...HEAD --check` and `git diff --stat origin/main...HEAD`.

Confirm that only the planned source, tests, documentation, and plan files changed.

- [ ] **Step 2: Run the complete verification matrix.**

Run `swift test`, `swift build --sdk iphoneos --triple arm64-apple-ios15.0`, and isolated macOS/iOS demo `xcodebuild` builds with separate DerivedData directories. Run a Mac Catalyst build if the installed SDK supports it. Record exit codes and test counts before claiming readiness.

- [ ] **Step 3: Request an independent code review of the combined branch.**

Provide the reviewer the `origin/main` base SHA, branch HEAD SHA, the four fork issues, and the platform constraints. Fix any critical or important findings, then rerun the full verification matrix.

- [ ] **Step 4: Push the branch to the fork and open a non-draft PR.**

```bash
git push -u origin codex/fix-upstream-issues
gh pr create --repo ShiinaLabs/SplitView --base main --head SHIINASAMA:codex/fix-upstream-issues \
  --title "Fix actionable upstream issues" \
  --body-file /tmp/splitview-pr-body.md
```

The PR body must link the fork issues with `Refs #1`, `Refs #2`, `Refs #3`, and `Refs #4`, link the upstream issues/PR as context, list the verification commands, and explicitly say the PR is left open for review. It must not mention or request an upstream comment.

- [ ] **Step 5: Update durable project memory.**

Update `ShiinaLabs/SplitView 索引.md` and the organization index with the branch, commit/PR URL, completed fixes, verification results, and review status. Do not record credentials, tokens, or temporary shell output.
