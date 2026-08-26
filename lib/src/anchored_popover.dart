import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'anchored_popover_controller.dart';
import 'anchored_popover_theme.dart';
import 'popover_layout_delegate.dart';
import 'popover_trigger.dart';
import 'widgets/popover_surface.dart';

/// Builds the content of a popover.
///
/// [dismiss] closes the popover that is being built, which is what an action
/// inside it usually wants to do once it has run.
typedef PopoverBuilder =
    Widget Function(BuildContext context, VoidCallback dismiss);

/// Shows a popover anchored to [child] rather than to the screen.
///
/// Wrap the widget the popover belongs to. On the [trigger] gesture the popover
/// is rendered into the ambient [Overlay] — above dialogs, sheets and anything
/// that clips — but positioned against [child], and it keeps following [child]
/// while the list it is in scrolls.
///
/// ```dart
/// AnchoredPopover(
///   popoverBuilder: (context, dismiss) => GestureDetector(
///     onTap: () {
///       toggleFavorite();
///       dismiss();
///     },
///     child: const Text('Favourite'),
///   ),
///   child: MarketRow(symbol: 'BTC'),
/// );
/// ```
///
/// That is the whole of the common case: long-press the row, a small card opens
/// just above it, and three seconds later it fades away.
///
/// The popover stays inside the [Overlay]: if there is no room on the preferred
/// side it flips to the other one, and whatever still overflows is clamped
/// inside the safe area plus [screenPadding]. See [PopoverLayoutDelegate].
///
/// Because it renders through an [OverlayPortal], the content is built in this
/// widget's own place in the tree — so [Theme], [Directionality],
/// [MediaQuery] and your localisations resolve exactly as they do for [child],
/// and there is no [OverlayEntry] left to leak if the anchor is disposed while
/// the popover is up.
class AnchoredPopover extends StatefulWidget {
  /// Creates a popover anchored to [child].
  const AnchoredPopover({
    required this.child,
    required this.popoverBuilder,
    this.trigger = PopoverTrigger.longPress,
    this.controller,
    this.targetAnchor = Alignment.topCenter,
    this.followerAnchor = Alignment.bottomCenter,
    this.offset = const Offset(0, -8),
    this.autoDismiss = true,
    this.showDuration,
    this.dismissOnTapOutside = true,
    this.dismissOnScroll = false,
    this.followAnchorOnScroll = true,
    this.followAnchorEveryFrame = false,
    this.flip = true,
    this.barrierColor,
    this.barrierSemanticLabel,
    this.decorate = true,
    this.screenPadding,
    this.transitionDuration,
    this.reverseTransitionDuration,
    this.curve,
    this.reverseCurve,
    this.dismissOnEscape = true,
    this.dismissOnBackButton = true,
    this.autofocus = false,
    this.restoreFocus = true,
    this.enableFeedback = true,
    this.pauseAutoDismissOnHover = true,
    this.hoverEnterDuration,
    this.hoverExitDuration,
    this.semanticLabel,
    this.onShow,
    this.onDismiss,
    super.key,
  });

  /// The anchor. Laid out and hit-tested exactly as if this widget were not
  /// here, apart from the one recogniser [trigger] adds.
  final Widget child;

  /// Builds the popover's content, without the surface around it.
  final PopoverBuilder popoverBuilder;

  /// The gesture on [child] that opens the popover.
  final PopoverTrigger trigger;

  /// Opens and closes the popover from elsewhere.
  ///
  /// When null, one is created and disposed internally.
  final AnchoredPopoverController? controller;

  /// The point of [child] the popover is placed against.
  ///
  /// Pass an [AlignmentDirectional] for a side that should mirror in RTL.
  final AlignmentGeometry targetAnchor;

  /// The point of the popover put onto the [targetAnchor] point.
  ///
  /// Also the origin the entrance transition scales out of, so the popover
  /// appears to grow from the anchor.
  final AlignmentGeometry followerAnchor;

  /// Shifted by this much once the anchors line up. Not mirrored in RTL.
  final Offset offset;

  /// Whether the popover closes itself after [showDuration].
  ///
  /// Set false for a popover the user has to dismiss — one holding something
  /// they need time to read or copy.
  final bool autoDismiss;

  /// How long the popover stays up when [autoDismiss] is set.
  ///
  /// Defaults to [AnchoredPopoverTheme.showDuration], then to 3 seconds.
  final Duration? showDuration;

  /// Whether a tap anywhere outside the popover closes it.
  ///
  /// The tap is absorbed rather than passed through, so the widget under it does
  /// not also fire. Ignored under [PopoverTrigger.hover], where a full-screen
  /// barrier would swallow the pointer the popover is following.
  final bool dismissOnTapOutside;

  /// Whether scrolling the enclosing scrollable closes the popover, instead of
  /// the popover following it.
  final bool dismissOnScroll;

  /// Whether the popover re-anchors itself as the anchor moves.
  ///
  /// Covers every scrollable the anchor sits inside — not just the innermost
  /// one — along with window resizes and the software keyboard opening under
  /// it. Ignored when [dismissOnScroll] is set. Only the popover's position is
  /// recomputed, not its content.
  ///
  /// What it does not cover is an anchor that moves without any of those
  /// happening: one being animated, or a row being dragged in a
  /// [ReorderableListView]. See [followAnchorEveryFrame].
  final bool followAnchorOnScroll;

  /// Whether the popover checks its anchor every frame rather than only when
  /// something known to move it happens.
  ///
  /// Set it for an anchor that animates, or one the user can drag. It schedules
  /// no frames of its own — it looks at the anchor on frames that were going to
  /// happen anyway, which is all an animation or a drag needs — and relayout
  /// happens only when the anchor has actually moved. It is off by default
  /// because most anchors only ever move for a reason
  /// [followAnchorOnScroll] already covers.
  ///
  /// Ignored when [followAnchorOnScroll] is not set, or when [dismissOnScroll]
  /// is.
  final bool followAnchorEveryFrame;

  /// Whether the popover may flip to the anchor's other side when the preferred
  /// side does not fit.
  final bool flip;

  /// Colour of the full-screen scrim behind the popover.
  ///
  /// Null draws no scrim. A scrim fades with the popover, and — like
  /// [dismissOnTapOutside] — absorbs taps.
  final Color? barrierColor;

  /// Read out for the scrim, and the label of the dismiss action a screen
  /// reader offers on it.
  ///
  /// Only used when the scrim is there to be dismissed — that is, when
  /// [dismissOnTapOutside] is set. Defaults to
  /// [MaterialLocalizations.modalBarrierDismissLabel].
  final String? barrierSemanticLabel;

  /// Whether to wrap the content in a [PopoverSurface].
  ///
  /// Set false to paint everything yourself; the content is still put in a
  /// transparent [Material] so text styles and ink respond normally.
  final bool decorate;

  /// How close to the edge of the [Overlay] the popover may be placed, on top of
  /// the safe-area insets.
  ///
  /// Defaults to [AnchoredPopoverTheme.screenPadding], then to 8 on all sides.
  final EdgeInsetsGeometry? screenPadding;

  /// How long the popover takes to fade and scale in.
  final Duration? transitionDuration;

  /// How long the popover takes to fade and scale back out.
  final Duration? reverseTransitionDuration;

  /// Curve of the entrance transition.
  final Curve? curve;

  /// Curve of the exit transition.
  final Curve? reverseCurve;

  /// Whether pressing escape closes the popover.
  ///
  /// Works whether or not anything inside the popover has focus, so a popover
  /// opened by a pointer is still dismissible from the keyboard.
  ///
  /// Content that wants escape for itself keeps it: while focus is inside the
  /// popover the key travels the ordinary [Actions] path, and only reaches the
  /// popover as a [DismissIntent] nothing else took. Nested popovers close one
  /// at a time, innermost first.
  final bool dismissOnEscape;

  /// Whether the system back gesture or button closes the popover instead of
  /// popping the route under it.
  ///
  /// Only intercepts while the popover is open, and only reaches Android's back
  /// gesture; there is nothing to intercept on the other platforms.
  final bool dismissOnBackButton;

  /// Whether opening the popover moves focus into it.
  ///
  /// Off by default, because a popover that opens beside a text field should
  /// not take the caret out of it. Set it for a popover holding the controls
  /// the user is meant to move to next — a menu, a confirmation.
  final bool autofocus;

  /// Whether closing the popover puts focus back where it was.
  ///
  /// Only applies to a popover that took focus in the first place; see
  /// [autofocus].
  final bool restoreFocus;

  /// Whether opening the popover on a long press plays the platform's
  /// long-press feedback.
  ///
  /// Ignored by every other [trigger] — no platform has a haptic for a tap or a
  /// hover.
  final bool enableFeedback;

  /// Whether the auto-dismiss timer stops while the pointer is over the
  /// popover.
  ///
  /// Keeps a popover up while it is being read, and restarts the timer when the
  /// pointer leaves. Ignored when [autoDismiss] is not set.
  final bool pauseAutoDismissOnHover;

  /// How long the pointer must rest on the anchor before a
  /// [PopoverTrigger.hover] popover opens.
  ///
  /// Defaults to [AnchoredPopoverTheme.hoverEnterDuration], then to 300ms.
  final Duration? hoverEnterDuration;

  /// How long after the pointer leaves both the anchor and the popover a
  /// [PopoverTrigger.hover] popover closes.
  ///
  /// The delay is what lets the pointer travel across the gap between the two
  /// without the popover closing underneath it. Defaults to
  /// [AnchoredPopoverTheme.hoverExitDuration], then to 100ms.
  final Duration? hoverExitDuration;

  /// Announced by screen readers when the popover opens.
  ///
  /// Leave null when the content is already readable on its own.
  final String? semanticLabel;

  /// Called when the popover opens. Not called when an open popover is reopened.
  final VoidCallback? onShow;

  /// Called when the popover starts closing, however it was closed.
  final VoidCallback? onDismiss;

  @override
  State<AnchoredPopover> createState() => AnchoredPopoverState();
}

/// State of an [AnchoredPopover].
///
/// Reachable with a [GlobalKey] for code that would rather not hold an
/// [AnchoredPopoverController].
class AnchoredPopoverState extends State<AnchoredPopover>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final OverlayPortalController _portal = OverlayPortalController();

  /// Bumped to relayout the popover against a moved anchor, without rebuilding
  /// its content.
  final ValueNotifier<int> _anchorRevision = ValueNotifier<int>(0);

  late AnimationController _transition;
  late CurvedAnimation _entrance;

  /// Every popover currently open, oldest first.
  ///
  /// Escape belongs to the last one — the one the user opened most recently —
  /// so nested popovers close one at a time rather than all at once.
  static final List<AnchoredPopoverState> _openPopovers =
      <AnchoredPopoverState>[];

  /// Drives the [PopScope] that puts the popover in the way of a route pop.
  ///
  /// Separate from [_visible] because the overlay child has to rebuild when it
  /// changes: a popover on its way out should stop intercepting back.
  final ValueNotifier<bool> _intercepting = ValueNotifier<bool>(false);

  /// Focus for the popover's content, so it can be tabbed through and put back
  /// where it came from.
  final FocusScopeNode _focusScope = FocusScopeNode(
    debugLabel: 'AnchoredPopover',
  );

  AnchoredPopoverController? _internalController;
  Timer? _dismissTimer;
  Timer? _hoverTimer;

  /// Every scrollable the anchor sits inside, innermost first — not just the
  /// nearest one, because an outer scrollable moves the anchor just as surely
  /// as the inner one does.
  final List<ScrollPosition> _scrollPositions = <ScrollPosition>[];

  /// The anchor's bounds as of the last check, so a frame in which it has not
  /// moved costs no layout.
  Rect? _lastAnchorRect;

  /// Whether the library's per-frame check has been registered yet.
  ///
  /// One callback serves every popover: a persistent frame callback cannot be
  /// removed once added, and a package cannot leave one behind per anchor.
  static bool _watchingFrames = false;

  /// Looks at the anchor of every open popover that asked to be followed
  /// closely, on frames that are happening regardless.
  ///
  /// Deliberately not a [Ticker]: a ticker would ask for a frame every 16ms for
  /// as long as a popover was open, which burns battery and stops
  /// `pumpAndSettle` from ever settling. An anchor that is animating or being
  /// dragged is already producing frames, and an anchor that is producing no
  /// frames is not moving.
  static void _checkAnchors(Duration timeStamp) {
    for (final AnchoredPopoverState popover in _openPopovers.toList()) {
      popover._checkAnchor();
    }
  }

  FocusNode? _focusToRestore;
  bool _anchorRefreshQueued = false;
  bool _escapeHandlerAttached = false;
  bool _pointerOnPopover = false;

  /// Mirrors the controller, so a reopen can be told from a first open and the
  /// exit transition knows whether it is still on its way out.
  bool _visible = false;

  AnchoredPopoverController get _controller =>
      widget.controller ?? _internalController!;

  /// Whether the popover is showing. See [AnchoredPopoverController.isOpen].
  bool get isOpen => _controller.isOpen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _transition = AnimationController(vsync: this)
      ..addStatusListener(_handleTransitionStatus);
    _entrance = CurvedAnimation(parent: _transition, curve: Curves.linear);
    if (widget.controller == null) {
      _internalController = AnchoredPopoverController();
    }
    _controller.addListener(_handleControllerChanged);
    if (_controller.isOpen) {
      // The anchor has no size until the first layout, so an initially open
      // popover has nothing to anchor to yet.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.isOpen && !_visible) {
          _open();
        }
      });
    }
  }

  @override
  void didUpdateWidget(AnchoredPopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controllerOf(oldWidget).removeListener(_handleControllerChanged);
      if (widget.controller != null) {
        _internalController?.dispose();
        _internalController = null;
      } else {
        _internalController = _visible
            ? AnchoredPopoverController.open()
            : AnchoredPopoverController();
      }
      _controller.addListener(_handleControllerChanged);
      if (_controller.isOpen != _visible) {
        _handleControllerChanged();
      }
    }
    if (!widget.followAnchorOnScroll && !widget.dismissOnScroll) {
      _detachAnchorListeners();
    } else if (_visible && _scrollPositions.isEmpty) {
      _attachAnchorListeners();
    }
    if (_visible &&
        widget.followAnchorEveryFrame != oldWidget.followAnchorEveryFrame) {
      _attachAnchorListeners();
    }
    if (widget.trigger != oldWidget.trigger &&
        widget.trigger != PopoverTrigger.hover) {
      // A pending open-on-hover belongs to a trigger that is no longer there.
      _hoverTimer?.cancel();
      _hoverTimer = null;
    }
    if (!_visible) {
      return;
    }
    if (widget.dismissOnEscape != oldWidget.dismissOnEscape) {
      if (widget.dismissOnEscape) {
        _attachEscapeHandler();
      } else {
        _detachEscapeHandler();
      }
    }
    if (widget.autoDismiss != oldWidget.autoDismiss ||
        widget.showDuration != oldWidget.showDuration) {
      // Restarts against the new duration, or cancels outright — see
      // _startDismissTimer.
      _startDismissTimer();
    }
  }

  AnchoredPopoverController _controllerOf(AnchoredPopover widget) =>
      widget.controller ?? _internalController!;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dismissTimer?.cancel();
    _hoverTimer?.cancel();
    _detachEscapeHandler();
    _detachAnchorListeners();
    _controller.removeListener(_handleControllerChanged);
    _openPopovers.remove(this);
    _intercepting.dispose();
    _focusScope.dispose();
    _internalController?.dispose();
    _entrance.dispose();
    _transition.dispose();
    _anchorRevision.dispose();
    super.dispose();
  }

  /// Opens the popover. Reopening restarts the auto-dismiss timer.
  void show() => _controller.show();

  /// Closes the popover.
  void hide() => _controller.hide();

  /// [hide] when open, [show] when not.
  void toggle() => _controller.toggle();

  void _handleControllerChanged() {
    if (_controller.isOpen) {
      if (_visible) {
        _startDismissTimer();
      } else {
        _open();
      }
    } else if (_visible) {
      _close();
    }
  }

  void _open() {
    final AnchoredPopoverTheme theme = AnchoredPopoverTheme.resolve(context);
    _visible = true;
    _transition
      ..duration = widget.transitionDuration ?? theme.transitionDuration
      ..reverseDuration =
          widget.reverseTransitionDuration ?? theme.reverseTransitionDuration;
    _entrance
      ..curve = widget.curve ?? theme.curve!
      ..reverseCurve = widget.reverseCurve ?? theme.reverseCurve;
    _attachAnchorListeners();
    _attachEscapeHandler();
    _openPopovers
      ..remove(this)
      ..add(this);
    _intercepting.value = true;
    if (widget.autofocus) {
      _focusToRestore = FocusManager.instance.primaryFocus;
      // The scope has no children to focus until the overlay child is built.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _visible) {
          _focusScope.requestFocus();
        }
      });
    }
    if (!_portal.isShowing) {
      _portal.show();
    }
    _transition.forward();
    _startDismissTimer();
    widget.onShow?.call();
  }

  void _close() {
    _visible = false;
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _hoverTimer?.cancel();
    _hoverTimer = null;
    _pointerOnPopover = false;
    _openPopovers.remove(this);
    _intercepting.value = false;
    _detachEscapeHandler();
    _detachAnchorListeners();
    _restoreFocus();
    _transition.reverse();
    widget.onDismiss?.call();
  }

  void _startDismissTimer() {
    _dismissTimer?.cancel();
    if (!widget.autoDismiss || _pointerOnPopover) {
      _dismissTimer = null;
      return;
    }
    final Duration duration =
        widget.showDuration ??
        AnchoredPopoverTheme.resolve(context).showDuration!;
    _dismissTimer = Timer(duration, _controller.hide);
  }

  void _attachEscapeHandler() {
    if (!widget.dismissOnEscape || _escapeHandlerAttached) {
      return;
    }
    // Handled at the keyboard rather than through Shortcuts: a popover opened
    // by a long press has taken no focus, so there is no node for a key event
    // to travel up from.
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _escapeHandlerAttached = true;
  }

  void _detachEscapeHandler() {
    if (!_escapeHandlerAttached) {
      return;
    }
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _escapeHandlerAttached = false;
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!_visible ||
        event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape) {
      return false;
    }
    // Escape is the innermost popover's to take. Without this, opening a
    // popover from inside another would close both on one press.
    if (_openPopovers.isNotEmpty && _openPopovers.last != this) {
      return false;
    }
    // Focus is inside the popover, so the key has somewhere ordinary to go: a
    // text field's own escape handling, an Autocomplete's, a nested
    // Shortcuts'. Whatever none of them takes arrives back here as a
    // DismissIntent — see _buildPopover.
    if (_focusScope.hasFocus) {
      return false;
    }
    _controller.hide();
    return true;
  }

  void _restoreFocus() {
    final FocusNode? node = _focusToRestore;
    _focusToRestore = null;
    if (!widget.restoreFocus ||
        node == null ||
        node.context == null ||
        !node.canRequestFocus) {
      return;
    }
    node.requestFocus();
  }

  /// The pointer arriving on the anchor or on the popover itself.
  void _handlePointerEnter() {
    _hoverTimer?.cancel();
    _hoverTimer = null;
    if (_visible) {
      return;
    }
    _hoverTimer = Timer(
      widget.hoverEnterDuration ??
          AnchoredPopoverTheme.resolve(context).hoverEnterDuration!,
      _controller.show,
    );
  }

  /// The pointer arriving on the popover's own content.
  void _handlePopoverEnter() {
    _pointerOnPopover = true;
    if (widget.trigger == PopoverTrigger.hover) {
      _hoverTimer?.cancel();
      _hoverTimer = null;
    }
    if (widget.autoDismiss && widget.pauseAutoDismissOnHover) {
      _dismissTimer?.cancel();
      _dismissTimer = null;
    }
  }

  /// The pointer leaving the popover's own content.
  void _handlePopoverExit() {
    _pointerOnPopover = false;
    if (widget.trigger == PopoverTrigger.hover) {
      _handlePointerExit();
      return;
    }
    if (widget.pauseAutoDismissOnHover) {
      _startDismissTimer();
    }
  }

  /// The pointer leaving the anchor or the popover itself.
  void _handlePointerExit() {
    _hoverTimer?.cancel();
    if (!_visible) {
      _hoverTimer = null;
      return;
    }
    _hoverTimer = Timer(
      widget.hoverExitDuration ??
          AnchoredPopoverTheme.resolve(context).hoverExitDuration!,
      _controller.hide,
    );
  }

  void _handleTransitionStatus(AnimationStatus status) {
    // Held open until the exit transition has actually finished — and only if
    // nothing reopened it in the meantime.
    if (status == AnimationStatus.dismissed && !_visible && _portal.isShowing) {
      _portal.hide();
    }
  }

  void _attachAnchorListeners() {
    if (!widget.dismissOnScroll && !widget.followAnchorOnScroll) {
      return;
    }
    _detachAnchorListeners();
    for (final ScrollPosition position in _ancestorScrollPositions()) {
      position.addListener(_handleAnchorMoved);
      _scrollPositions.add(position);
    }
    if (_followsEveryFrame) {
      _lastAnchorRect = _resolveAnchorRect();
      if (!_watchingFrames) {
        _watchingFrames = true;
        SchedulerBinding.instance.addPersistentFrameCallback(_checkAnchors);
      }
    }
  }

  bool get _followsEveryFrame =>
      widget.followAnchorOnScroll &&
      widget.followAnchorEveryFrame &&
      !widget.dismissOnScroll;

  void _detachAnchorListeners() {
    for (final ScrollPosition position in _scrollPositions) {
      position.removeListener(_handleAnchorMoved);
    }
    _scrollPositions.clear();
    _lastAnchorRect = null;
  }

  /// Every [Scrollable] between the anchor and the root, innermost first.
  Iterable<ScrollPosition> _ancestorScrollPositions() {
    final List<ScrollPosition> positions = <ScrollPosition>[];
    context.visitAncestorElements((Element element) {
      if (element is StatefulElement && element.state is ScrollableState) {
        // A ScrollableState has its position by the time anything below it
        // builds, which is the only way this element could have been reached.
        positions.add((element.state as ScrollableState).position);
      }
      return true;
    });
    return positions;
  }

  /// Looks at the anchor once, and relayouts the popover if it has moved.
  ///
  /// This is how an anchor that moves for a reason nothing notifies about — an
  /// animation, a drag — is still followed.
  void _checkAnchor() {
    if (!_visible || !mounted || !_followsEveryFrame) {
      return;
    }
    final Rect? rect = _resolveAnchorRect();
    if (rect == null || rect == _lastAnchorRect) {
      return;
    }
    _lastAnchorRect = rect;
    _anchorRevision.value++;
  }

  /// The anchor's bounds in the overlay's coordinate space, or null while
  /// either of them is unmeasured.
  Rect? _resolveAnchorRect() {
    final RenderObject? anchor = context.findRenderObject();
    final RenderObject? overlay = Overlay.maybeOf(
      context,
    )?.context.findRenderObject();
    if (anchor is! RenderBox ||
        overlay is! RenderBox ||
        !anchor.attached ||
        !anchor.hasSize ||
        !overlay.attached ||
        !overlay.hasSize) {
      return null;
    }
    return anchor.localToGlobal(Offset.zero, ancestor: overlay) & anchor.size;
  }

  @override
  void didChangeMetrics() {
    // The window resized, or the software keyboard opened under the anchor.
    if (_visible) {
      _handleAnchorMoved();
    }
  }

  void _handleAnchorMoved() {
    if (widget.dismissOnScroll) {
      _controller.hide();
      return;
    }
    // A ScrollPosition notification arrives before the scrollable has laid
    // out its children. Resolve the new rect after that layout, then relayout
    // the portal on the following frame. Coalescing matters for a drag, where
    // many position notifications can arrive in one frame.
    if (_anchorRefreshQueued) {
      return;
    }
    _anchorRefreshQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _anchorRefreshQueued = false;
      if (mounted && _visible) {
        _anchorRevision.value++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _buildPopover,
      child: _withTrigger(widget.child),
    );
  }

  Widget _withTrigger(Widget child) {
    switch (widget.trigger) {
      case PopoverTrigger.manual:
        return child;
      case PopoverTrigger.longPress:
        // Not excluded from semantics: the recogniser contributes a
        // long-press action to the child's node, which is how a screen reader
        // user reaches the popover at all.
        //
        // Opaque, not deferToChild: the whole of the anchor's box should
        // respond, including the gaps between a Row's children and any part of
        // it that paints nothing. Children are still hit-tested first, so
        // gestures the child already handles keep working.
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () {
            if (widget.enableFeedback) {
              Feedback.forLongPress(context);
            }
            show();
          },
          child: child,
        );
      case PopoverTrigger.tap:
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: toggle,
          child: child,
        );
      case PopoverTrigger.secondaryTap:
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onSecondaryTap: show,
          child: child,
        );
      case PopoverTrigger.hover:
        // No gesture recogniser at all, so the anchor stays as tappable as it
        // was and a touch user is unaffected by a hover popover.
        return MouseRegion(
          onEnter: (_) => _handlePointerEnter(),
          onExit: (_) => _handlePointerExit(),
          child: child,
        );
    }
  }

  Widget _buildPopover(BuildContext context) {
    final OverlayState overlay = Overlay.of(this.context);
    final RenderBox? anchorBox = this.context.findRenderObject() as RenderBox?;
    final RenderBox? overlayBox =
        overlay.context.findRenderObject() as RenderBox?;
    if (anchorBox == null ||
        !anchorBox.hasSize ||
        overlayBox == null ||
        !overlayBox.hasSize) {
      return const SizedBox.shrink();
    }

    final AnchoredPopoverTheme theme = AnchoredPopoverTheme.resolve(context);
    final TextDirection direction = Directionality.of(context);
    final EdgeInsets screenPadding =
        (widget.screenPadding ?? theme.screenPadding!).resolve(direction) +
        MediaQuery.paddingOf(overlay.context);

    Widget content = widget.popoverBuilder(context, hide);
    content = widget.decorate
        ? PopoverSurface(child: content)
        // Ink and text styles still need a Material above them, even when
        // nothing is painted.
        : Material(type: MaterialType.transparency, child: content);
    if (widget.semanticLabel != null) {
      content = Semantics(
        container: true,
        liveRegion: true,
        label: widget.semanticLabel,
        child: content,
      );
    }
    if (widget.trigger == PopoverTrigger.hover ||
        (widget.autoDismiss && widget.pauseAutoDismissOnHover)) {
      // Wrapped inside the transitions, so the region is the popover's own box
      // rather than the whole overlay.
      content = MouseRegion(
        onEnter: (_) => _handlePopoverEnter(),
        onExit: (_) => _handlePopoverExit(),
        child: content,
      );
    }
    content = FocusScope(node: _focusScope, child: content);
    if (widget.dismissOnEscape) {
      // The focused path. Registered below the content's own handlers, so it
      // only ever sees a dismiss nothing inside the popover wanted.
      content = Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (DismissIntent intent) {
              hide();
              return null;
            },
          ),
        },
        child: content,
      );
    }
    content = FadeTransition(
      opacity: _entrance,
      child: ScaleTransition(
        scale: _entrance,
        alignment: widget.followerAnchor.resolve(direction),
        child: content,
      ),
    );

    final Widget positioned = ValueListenableBuilder<int>(
      valueListenable: _anchorRevision,
      child: content,
      builder: (BuildContext context, int revision, Widget? child) {
        return CustomSingleChildLayout(
          delegate: PopoverLayoutDelegate(
            anchorRect:
                anchorBox.localToGlobal(Offset.zero, ancestor: overlayBox) &
                anchorBox.size,
            targetAnchor: widget.targetAnchor.resolve(direction),
            followerAnchor: widget.followerAnchor.resolve(direction),
            offset: widget.offset,
            screenPadding: screenPadding,
            flip: widget.flip,
          ),
          child: child,
        );
      },
    );

    final Color? barrierColor = widget.barrierColor;
    final bool dismissible =
        widget.dismissOnTapOutside && widget.trigger != PopoverTrigger.hover;
    if (!dismissible && barrierColor == null) {
      return _withBackButton(positioned);
    }

    Widget barrier = ModalBarrier(
      color: barrierColor,
      dismissible: dismissible,
      onDismiss: hide,
      semanticsLabel: dismissible
          ? widget.barrierSemanticLabel ??
                Localizations.of<MaterialLocalizations>(
                  context,
                  MaterialLocalizations,
                )?.modalBarrierDismissLabel
          : null,
    );
    if (barrierColor != null) {
      barrier = FadeTransition(opacity: _entrance, child: barrier);
    }

    return _withBackButton(
      Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(child: barrier),
          Positioned.fill(child: positioned),
        ],
      ),
    );
  }

  /// Puts the popover in the way of a route pop, so back closes the popover
  /// rather than the page under it.
  Widget _withBackButton(Widget child) {
    if (!widget.dismissOnBackButton) {
      return child;
    }
    return ValueListenableBuilder<bool>(
      valueListenable: _intercepting,
      child: child,
      builder: (BuildContext context, bool intercepting, Widget? child) {
        // Stops intercepting the moment the popover starts closing, rather than
        // when it has finished: a back press during the exit transition should
        // pop the route, not fall into a dead zone.
        return PopScope(
          canPop: !intercepting,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (!didPop) {
              hide();
            }
          },
          child: child!,
        );
      },
    );
  }
}
