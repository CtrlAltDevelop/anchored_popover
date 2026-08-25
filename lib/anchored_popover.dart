/// A popover that anchors to a widget instead of the screen.
///
/// Wrap the widget it belongs to, and on a long press — or a tap, or nothing at
/// all — a card opens in the [Overlay] but positioned against that widget. It
/// follows the widget as the list scrolls, flips and clamps to stay on screen,
/// and fades itself back out.
///
/// ```dart
/// AnchoredPopover(
///   popoverBuilder: (context, dismiss) => const Text('Favourite'),
///   child: MarketRow(symbol: 'BTC'),
/// );
/// ```
library;

export 'src/anchored_popover.dart';
export 'src/anchored_popover_controller.dart';
export 'src/anchored_popover_theme.dart';
export 'src/popover_layout_delegate.dart';
export 'src/popover_trigger.dart';
export 'src/widgets/popover_surface.dart';
