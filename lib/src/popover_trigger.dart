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

  /// Nothing. The popover opens only through its
  /// [AnchoredPopoverController].
  manual,
}
