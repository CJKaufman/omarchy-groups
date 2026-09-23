# Development notes

## Why this base and which separators?

Research checked on 2026-09-07:

| Option | Fit for this layout |
| --- | --- |
| [Nook 1.1.2](https://github.com/Katsari/nook) | Closest fit: actual widgets in an anchored strip below the existing bar. Upstream supports one drawer; this fork adds independent instances. |
| [Skål Bar](https://github.com/outcrop-labs/skal-bar) | Replaces the full bar with reveal controls for its three regions. More replacement code than needed for several independent drawers. |
| [OmaBar Drawer](https://github.com/amitcpatel/omabar-drawer) | Full-bar replacement that collapses the right region behind one icon. |
| [Plugin Drawer](https://github.com/alyayman921/Omarchy-drawer) | Single drawer with a grid/list interface. A different presentation from the small strips wanted here. |
| [Bar Studio](https://github.com/andreconde21/omarchy-bar-studio) | Layout editor, not a multiple-drawer host. Its tray collapse needs a compatible tray; the stock tray does not display its hosted array. |
| Stock `omarchy.spacer` | Built-in blank spacing, repeatable with configurable `size`. |
| [Bar Divider 1.1.0](https://github.com/Rizmi/omarchy-divider-plugin) | Existing repeatable line, dot or pipe separators. Reused unchanged for the live layout. |

Example separator: `{"id":"io.github.rizmi.divider","style":"line","margin":5}`.

## Validation and boundaries

`tests/all.sh` runs the pure layout tests, Qt 6 lint, manifest validation and a
Quickshell harness. The harness exercises separate instance config writes,
settings retention, open/close isolation and sibling closing. The settings harness also drives creation, naming, widget selection/reordering, return to bar, and last-group recovery through the real QML controls. It tests both the direct shell host and the scoped host, using a temporary settings file for disk writes. Its windows stay unmapped and the user configuration is never edited. Pure tests also
cover absent/duplicate IDs and every group-scoped mutation.

Optional real-pointer drag tests require `tests/tools/vptr/build.sh` and
`NOOK_GROUP_ID=<group> bash tests/all.sh --drag`. They temporarily modify and
restore the live layout, so run them only while the pointer is free.

`uv run --no-project python tests/interactions.test.py` uses a temporary harmless
widget to check bar-to-group dragging, group-to-group transfer, cursor-following
drag images, insertion markers, precise bar drop placement, cancellation, and
native tooltip/right-click behavior. It restores the
original configuration and pointer. Set `NOOK_GROUP_ID` and
`NOOK_TARGET_GROUP_ID` to two existing groups (defaults: `windows` and `input`).
Set `NOOK_DRAG_CAPTURE` to a PNG path to capture the held drag over the bar.

Nook integrates with Omarchy's bar internals rather than a stable hosting API.
On shells with scoped plugin APIs, Groups resolves the containing bar through a
first-party widget on the same bar, such as the menu or clock. Keep at least one
such widget present. Hosted third-party widgets retain their scoped APIs.
Drags out of drawers use the bar's ghost overlay and target hit testing; Groups
commits the move because the source entry belongs to a drawer's item list.
Top-bar behavior is the supported and verified configuration here. Some widgets
hide themselves when idle or when hardware is absent; their slots are still
loaded. Widgets retain their own tooltip and status behavior. The group trigger
does not aggregate every plugin's urgency state.

On stock bars that still rebuild array-backed widget lists, Groups installs a
small runtime adapter that preserves native widgets during layout edits. It
changes only those lists in memory, requires no configuration or system-file
edits, and skips bars with the native fix (omacom/omarchy#10931). The adapter
belongs to each native list so removing or reloading Groups does not break the
bar. A shell restart clears it; loading Groups installs it again where needed.
The compatibility harness checks delegate identity, repeated group IDs, nested
settings, reordering, empty sections, orientation changes, and native-fix bypass.

## Performance and drag validation

Unchanged drawer models return before parsing old settings or matching delegates.
Dismissal windows retain their QML objects across hovers, while native surfaces
stay hidden when unused. Icon and widget pickers have empty models until opened;
icon search builds its keyword index once, on the first search.

Overflow scrolling uses Qt's [FrameAnimation](https://doc.qt.io/qt-6/qml-qtquick-frameanimation.html)
with elapsed time, so its speed is independent of refresh rate. It stops at the
scroll boundaries and when hidden. Drag insertion points refresh after scrolling
has updated the row's geometry, including when the pointer stays still.

Run `bash tests/benchmark.sh <baseline-ref>` for before/after measurements in
Qt's JavaScript engine, without a display or GPU. A local sample against
`eb2f0d8` on 2026-09-23 measured:

| Work | Before | After |
| --- | ---: | ---: |
| 5,000 unchanged updates, 24 entries | 328 ms | 158 ms |
| 5,000 unchanged updates, 120 entries | 1,668 ms | 842 ms |
| 1,000 warmed multi-token icon searches | 1,556 ms | 217 ms |

These are microbenchmarks, not desktop frame-rate measurements. Results vary by
machine and load; they are deliberately not pass/fail tests.

On a **dedicated test compositor**, set `GROUPS_NATIVE_TEST=1` when running
`./validate`. This additionally maps the installed native bar with harmless
probe widgets and an in-memory layout. It checks scoped host discovery,
repeated-widget drag identity, exact insertion, shared plugin enablement,
dismissal reuse, and stationary-pointer scrolling. Use a 1920×1080 test output.
The default harnesses remain unmapped and safe to run in the desktop session.
