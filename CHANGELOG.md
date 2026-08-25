# Changelog

## 0.1.0

Initial release.

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
