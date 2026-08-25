import 'package:material_ui/material_ui.dart';

/// Opens and closes an [AnchoredPopover] from outside the popover itself.
///
/// Pass one to [AnchoredPopover.controller] and drive it from anywhere that can
/// reach it — a toolbar button, a bloc listener, a test:
///
/// ```dart
/// final controller = AnchoredPopoverController();
///
/// AnchoredPopover(
///   controller: controller,
///   trigger: PopoverTrigger.manual,
///   popoverBuilder: (context, dismiss) => const Text('Saved'),
///   child: const Icon(Icons.star),
/// );
///
/// controller.show();
/// ```
///
/// The controller holds the open/closed state, so it survives the popover being
/// rebuilt, and reads back correctly the moment [show] returns rather than a
/// frame later. Auto-dismiss and tap-outside go through it as well, which means
/// [isOpen] is never out of step with what is on screen.
///
/// Dispose it with the [State] that owns it. An [AnchoredPopover] never disposes
/// a controller it was given; one it created for itself it does.
class AnchoredPopoverController extends ChangeNotifier {
  /// Creates a controller for a popover that starts closed.
  AnchoredPopoverController() : _isOpen = false;

  /// Creates a controller for a popover that is already open.
  ///
  /// Attached to a widget that has not been laid out yet, the popover opens on
  /// the frame after the anchor first has a size.
  AnchoredPopoverController.open() : _isOpen = true;

  bool _isOpen;

  /// Whether the popover is showing.
  ///
  /// True from the moment [show] is called until the exit transition starts —
  /// not until it finishes, so a popover on its way out already reads as closed.
  bool get isOpen => _isOpen;

  /// Opens the popover, restarting its auto-dismiss timer if it is already open.
  void show() {
    if (_isOpen) {
      // Not a no-op: listeners restart the dismiss timer, which is what a second
      // long press on the same anchor should do.
      notifyListeners();
      return;
    }
    _isOpen = true;
    notifyListeners();
  }

  /// Closes the popover. A no-op when it is already closed.
  void hide() {
    if (!_isOpen) {
      return;
    }
    _isOpen = false;
    notifyListeners();
  }

  /// [hide] when open, [show] when not.
  void toggle() => _isOpen ? hide() : show();
}
