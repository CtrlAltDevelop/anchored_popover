import 'package:anchored_popover/anchored_popover.dart';
import 'package:material_ui/material_ui.dart';

void main() => runApp(const ExampleApp());

/// A market list whose rows open an anchored popover on a long press.
class ExampleApp extends StatefulWidget {
  /// Creates the example app.
  const ExampleApp({this.initialThemeMode = ThemeMode.system, super.key});

  /// The theme the app starts in. The app bar switches it afterwards.
  final ThemeMode initialThemeMode;

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  late ThemeMode _themeMode = widget.initialThemeMode;

  static ThemeData _themeFor(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: brightness,
      ),
      // One place to set the look and timing of every popover in the app.
      extensions: const <ThemeExtension<dynamic>>[
        AnchoredPopoverTheme(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          padding: EdgeInsets.all(4),
          showDuration: Duration(seconds: 4),
        ),
      ],
    );
  }

  void _toggleBrightness() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Anchored popover',
    debugShowCheckedModeBanner: false,
    theme: _themeFor(Brightness.light),
    darkTheme: _themeFor(Brightness.dark),
    themeMode: _themeMode,
    home: MarketsPage(onToggleBrightness: _toggleBrightness),
  );
}

/// The example's only page.
class MarketsPage extends StatelessWidget {
  /// Creates the market list page.
  const MarketsPage({required this.onToggleBrightness, super.key});

  /// Switches the app between its light and dark themes.
  final VoidCallback onToggleBrightness;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markets'),
        actions: <Widget>[
          // A tap trigger, opening below its anchor and staying up until it is
          // dismissed.
          AnchoredPopover(
            trigger: PopoverTrigger.tap,
            autoDismiss: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 8),
            popoverBuilder: (BuildContext context, VoidCallback dismiss) =>
                const SizedBox(
                  width: 220,
                  child: Text(
                    'Long press a row for its actions. The popover follows '
                    'the row as the list scrolls, and escape closes it.',
                  ),
                ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.help_outline),
            ),
          ),
          // A hover trigger, for a popover that behaves like a rich tooltip.
          // It adds no recogniser, so the button underneath stays a button.
          AnchoredPopover(
            trigger: PopoverTrigger.hover,
            autoDismiss: false,
            targetAnchor: Alignment.bottomCenter,
            followerAnchor: Alignment.topCenter,
            offset: const Offset(0, 8),
            popoverBuilder: (BuildContext context, VoidCallback dismiss) =>
                const SizedBox(
                  width: 200,
                  child: Text(
                    'Rest the pointer here. The popover stays up while the '
                    'pointer is on it, so it can hold something to click.',
                  ),
                ),
            child: IconButton(
              onPressed: onToggleBrightness,
              icon: const Icon(Icons.brightness_6_outlined),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: markets.length,
        itemBuilder: (BuildContext context, int index) =>
            MarketRow(market: markets[index]),
      ),
      bottomNavigationBar: const _ProgrammaticBar(),
    );
  }
}

/// One row of the list, with a long-press popover of actions.
class MarketRow extends StatelessWidget {
  /// Creates a row for [market].
  const MarketRow({required this.market, super.key});

  /// The instrument shown in the row.
  final Market market;

  void _run(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action ${market.symbol}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool up = market.change >= 0;
    return AnchoredPopover(
      semanticLabel: '${market.symbol} actions',
      // A row of buttons is what the keyboard should move to next, and where
      // focus should come back from when it closes.
      autofocus: true,
      popoverBuilder: (BuildContext context, VoidCallback dismiss) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _PopoverAction(
            icon: Icons.star_outline,
            label: 'Watch',
            onPressed: () {
              dismiss();
              _run(context, 'Watching');
            },
          ),
          _PopoverAction(
            icon: Icons.notifications_outlined,
            label: 'Alert',
            onPressed: () {
              dismiss();
              _run(context, 'Alert set for');
            },
          ),
          _PopoverAction(
            icon: Icons.ios_share,
            label: 'Share',
            onPressed: () {
              dismiss();
              _run(context, 'Sharing');
            },
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _run(context, 'Opened'),
        leading: CircleAvatar(child: Text(market.symbol.characters.first)),
        title: Text(market.symbol),
        subtitle: Text(market.name),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              market.price,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '${up ? '+' : ''}${market.change.toStringAsFixed(2)}%',
              style: TextStyle(
                color: up ? Colors.green.shade600 : colors.error,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One icon-over-label button inside a row's popover.
class _PopoverAction extends StatelessWidget {
  const _PopoverAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 20),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// A popover with no trigger of its own, opened from a button beside it.
class _ProgrammaticBar extends StatefulWidget {
  const _ProgrammaticBar();

  @override
  State<_ProgrammaticBar> createState() => _ProgrammaticBarState();
}

class _ProgrammaticBarState extends State<_ProgrammaticBar> {
  final AnchoredPopoverController _popover = AnchoredPopoverController();

  @override
  void dispose() {
    _popover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AnchoredPopover(
            controller: _popover,
            trigger: PopoverTrigger.manual,
            autoDismiss: false,
            barrierColor: Colors.black.withValues(alpha: 0.3),
            popoverBuilder: (BuildContext context, VoidCallback dismiss) =>
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text('Opened by a controller, dismissed by a tap.'),
                ),
            child: FilledButton.tonalIcon(
              onPressed: _popover.toggle,
              icon: const Icon(Icons.bolt_outlined),
              label: const Text('Show programmatically'),
            ),
          ),
        ],
      ),
    );
  }
}

/// An instrument in the example's list.
class Market {
  /// Creates a row of demo data.
  const Market(this.symbol, this.name, this.price, this.change);

  /// Ticker symbol.
  final String symbol;

  /// Human-readable name.
  final String name;

  /// Formatted last price.
  final String price;

  /// Percentage change over the day.
  final double change;
}

/// The demo data behind the list.
const List<Market> markets = <Market>[
  Market('BTC', 'Bitcoin', r'$64,208', 2.41),
  Market('ETH', 'Ethereum', r'$3,142', 1.08),
  Market('SOL', 'Solana', r'$148.22', -0.76),
  Market('XRP', 'Ripple', r'$0.5241', 3.92),
  Market('ADA', 'Cardano', r'$0.4418', -1.35),
  Market('DOT', 'Polkadot', r'$6.907', 0.44),
  Market('LINK', 'Chainlink', r'$14.62', -2.18),
  Market('AVAX', 'Avalanche', r'$27.35', 5.06),
];
