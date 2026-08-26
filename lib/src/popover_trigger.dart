/// The gesture on an [AnchoredPopover]'s child that opens its popover.
///
/// A popover only ever adds the one recogniser it needs, so gestures the child
/// already handles keep working: a row that is an `InkWell` with an `onTap`
/// stays tappable under [PopoverTrigger.longPress].
enum PopoverTrigger {
  /// A long press. What a row in a list usually wants.
  longPress,

  /// A single tap.
  tap,

  /// A secondary tap — a right click, or a two-finger trackpad tap.
  secondaryTap,

  /// The pointer resting on the child, for a popover that behaves like a rich
  /// tooltip.
  ///
  /// Adds no gesture recogniser, so the child stays exactly as tappable as it
  /// was and a touch user — who never hovers — is unaffected. The popover stays
  /// up while the pointer is on it, so it can hold something to click.
  hover,

  /// Nothing. The popover opens only through its
  /// [AnchoredPopoverController].
  manual,
}
