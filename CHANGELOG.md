# Changelog

## 2.1.0

- The per-frame anchor check that `followAnchorEveryFrame` arms returns straight
  away when no popover is open. The callback it installs is a persistent frame
  callback, which Flutter cannot remove again, so it outlives every popover that
  wanted it; it no longer copies a list on every frame for the rest of the app's
  run to look at nothing.
- `onDismiss` documents that it is not called when the anchor is disposed while
  the popover is up. That was always the behaviour — a disposal is not a
  dismissal, and the callback would fire into a tree already being torn down —
  but the old wording promised it for every close.
- The `material_ui` constraint is `>=1.0.0 <2.0.0` rather than `^1.1.0`. The
  floor is the oldest version the package is tested against, rather than the
  newest one it happened to be written on, so an app held on an early 1.x can
  still take it.

## 2.0.0

Keyboard, pointer and focus support, and a popover that follows its anchor
wherever the anchor goes.

Breaking only in that `PopoverTrigger` gained a value: an exhaustive `switch`
over it in your own code now needs a `hover` case. Nothing that existed behaves
differently, and no other API changed.

### Keyboard and focus

- Escape closes an open popover, focused or not (`dismissOnEscape`). Content
  that wants escape for itself keeps it: while focus is inside the popover the
  key travels the ordinary `Actions` path and only arrives as a `DismissIntent`
  nothing else took. Nested popovers close one at a time, innermost first.
- On Android the system back gesture closes the popover rather than popping the
  route under it (`dismissOnBackButton`), and stops intercepting the moment the
  popover starts closing.
- `autofocus` moves focus into the popover, and `restoreFocus` puts it back on
  the anchor when the popover closes.

### Pointer

- `PopoverTrigger.hover`, for a popover that behaves like a rich tooltip: it
  opens once the pointer has rested on the anchor, stays up while the pointer is
  on the popover itself, and adds no gesture recogniser to the anchor.
  `hoverEnterDuration` and `hoverExitDuration` tune the delays, on the widget or
  on `AnchoredPopoverTheme`.
- The auto-dismiss timer stops while the pointer is over the popover, and
  restarts when it leaves (`pauseAutoDismissOnHover`).
- A long press plays the platform's long-press feedback (`enableFeedback`).

### Following the anchor

- Every scrollable the anchor sits inside now moves the popover, not just the
  innermost one, and a window resize or the software keyboard opening
  re-anchors it too.
- `followAnchorEveryFrame` follows an anchor that moves for no reason anything
  notifies about — one being animated, or dragged in a `ReorderableListView`.
  It schedules no frames of its own and relayouts only when the anchor has
  actually moved.

### Everything else

- The scrim is now a `ModalBarrier`, so it carries the platform's localised
  dismiss action; `barrierSemanticLabel` overrides the label.
- `AnchoredPopoverTheme` has `==` and `hashCode`, so registering an equal theme
  no longer counts as a change.
- Changing `dismissOnEscape`, `autoDismiss`, `showDuration`, `trigger` or
  `followAnchorEveryFrame` while a popover is open now takes effect on that
  popover, rather than on the next one to open.
- The Flutter constraint is relaxed to `>=3.44.0`, verified against that
  version, and CI builds against both it and the latest stable.
- Every line of `lib/` is covered by tests, and CI fails if that stops being
  true. The long-press haptic is asserted at the platform channel, since no
  test can feel one.
- Verified by hand on an Android emulator (back gesture, long press, safe
  area) and in a desktop browser (hover).
- Golden tests for the surface, the scrim, flipping and the entrance
  transition. They are skipped by an ordinary `flutter test`, because rendering
  differs between Flutter versions and platforms; run them with
  `flutter test --run-skipped --tags golden`.

## 1.0.0

Initial stable release.

- `AnchoredPopover`, which opens a popover positioned against its child rather
  than against the screen, on a long press, a tap, a secondary tap, or nothing
  at all.
- `AnchoredPopoverController` and a `GlobalKey`-reachable `AnchoredPopoverState`
  for opening and closing a popover from elsewhere.
- Placement that flips to the anchor's other side when the preferred one does
  not fit and clamps into the safe area, through the public
  `PopoverLayoutDelegate`.
- Anchor following inside a scrollable, or dismissal on scroll.
- Auto-dismiss, outside-tap dismissal, and an optional scrim.
- `AnchoredPopoverTheme`, a `ThemeExtension` carrying app-wide look and timing,
  and the `PopoverSurface` it styles.
