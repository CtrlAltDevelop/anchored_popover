import 'dart:async';

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
typedef PopoverBuilder = Widget Function(
  BuildContext context,
  VoidCallback dismiss,
);

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
    this.flip = true,
    this.barrierColor,
    this.decorate = true,
    this.screenPadding,
    this.transitionDuration,
    this.reverseTransitionDuration,
    this.curve,
    this.reverseCurve,
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
  /// not also fire.
  final bool dismissOnTapOutside;

  /// Whether scrolling the enclosing scrollable closes the popover, instead of
  /// the popover following it.
  final bool dismissOnScroll;

  /// Whether the popover re-anchors itself as the enclosing scrollable moves.
  ///
  /// Ignored when [dismissOnScroll] is set. Only the popover's position is
  /// recomputed, not its content.
  final bool followAnchorOnScroll;

  /// Whether the popover may flip to the anchor's other side when the preferred
  /// side does not fit.
  final bool flip;

  /// Colour of the full-screen scrim behind the popover.
  ///
  /// Null draws no scrim. A scrim fades with the popover, and — like
  /// [dismissOnTapOutside] — absorbs taps.
  final Color? barrierColor;

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
    with SingleTickerProviderStateMixin {
  final OverlayPortalController _portal = OverlayPortalController();

  /// Bumped to relayout the popover against a moved anchor, without rebuilding
  /// its content.
  final ValueNotifier<int> _anchorRevision = ValueNotifier<int>(0);

  late AnimationController _transition;
  late CurvedAnimation _entrance;

  AnchoredPopoverController? _internalController;
  Timer? _dismissTimer;
  ScrollPosition? _scrollPosition;
  bool _anchorRefreshQueued = false;

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
      _detachScrollListener();
    } else if (_visible && _scrollPosition == null) {
      _attachScrollListener();
    }
  }

  AnchoredPopoverController _controllerOf(AnchoredPopover widget) =>
      widget.controller ?? _internalController!;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _detachScrollListener();
    _controller.removeListener(_handleControllerChanged);
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
    _attachScrollListener();
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
    _detachScrollListener();
    _transition.reverse();
    widget.onDismiss?.call();
  }

  void _startDismissTimer() {
    _dismissTimer?.cancel();
    if (!widget.autoDismiss) {
      _dismissTimer = null;
      return;
    }
    final Duration duration =
        widget.showDuration ??
        AnchoredPopoverTheme.resolve(context).showDuration!;
    _dismissTimer = Timer(duration, _controller.hide);
  }

  void _handleTransitionStatus(AnimationStatus status) {
    // Held open until the exit transition has actually finished — and only if
    // nothing reopened it in the meantime.
    if (status == AnimationStatus.dismissed && !_visible && _portal.isShowing) {
      _portal.hide();
    }
  }

  void _attachScrollListener() {
    if (widget.dismissOnScroll || widget.followAnchorOnScroll) {
      final ScrollPosition? position = Scrollable.maybeOf(context)?.position;
      if (position == _scrollPosition) {
        return;
      }
      _detachScrollListener();
      _scrollPosition = position?..addListener(_handleAnchorMoved);
    }
  }

  void _detachScrollListener() {
    _scrollPosition?.removeListener(_handleAnchorMoved);
    _scrollPosition = null;
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
          onLongPress: show,
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
    if (!widget.dismissOnTapOutside && barrierColor == null) {
      return positioned;
    }

    Widget barrier = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.dismissOnTapOutside ? hide : null,
      child: barrierColor == null ? null : ColoredBox(color: barrierColor),
    );
    if (barrierColor != null) {
      barrier = FadeTransition(opacity: _entrance, child: barrier);
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned.fill(child: barrier),
        Positioned.fill(child: positioned),
      ],
    );
  }
}
