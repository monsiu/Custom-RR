import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Crypto donation addresses for Custom RR.
///
/// These are PLACEHOLDER addresses. Replace them with your real wallet
/// addresses when ready. They are always shown in the UI.
const Map<String, CryptoCoin> kCryptoDonationAddresses = <String, CryptoCoin>{
  'BTC': CryptoCoin(
    'Bitcoin',
    'bc1qexampleplaceholderaddressreplacebeforeshipping00',
  ),
  'ETH': CryptoCoin(
    'Ethereum / EVM',
    '0xExamplePlaceholderAddressReplaceBeforeShipping00',
  ),
  'SOL': CryptoCoin(
    'Solana',
    'SoLExamplePlaceholderAddressReplaceBeforeShipping00',
  ),
  'XMR': CryptoCoin(
    'Monero',
    '4ExamplePlaceholderMoneroAddressReplaceBeforeShipping0000000000000000000000000000000000000000000',
  ),
};

class CryptoCoin {
  const CryptoCoin(this.name, this.address);
  final String name;
  final String address;
}

/// Shows a bottom sheet listing crypto donation addresses with
/// copy-to-clipboard buttons.
Future<void> showCryptoDonateSheet(BuildContext context) {
  final List<MapEntry<String, CryptoCoin>> entries =
      kCryptoDonationAddresses.entries.toList(growable: false);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (BuildContext ctx) {
      final ColorScheme scheme = Theme.of(ctx).colorScheme;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.currency_bitcoin, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Donate with crypto',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tap a row to copy the address to your clipboard.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              for (final MapEntry<String, CryptoCoin> entry in entries)
                _CryptoAddressTile(
                  symbol: entry.key,
                  name: entry.value.name,
                  address: entry.value.address,
                ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                'Have a different coin? Swap it to Monero anonymously via '
                'Trocador (no account, no KYC). The payout goes straight '
                'to the project XMR address.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: () => _openTrocador(ctx),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Use other crypto (swap to XMR)'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

const String _kTrocadorSwapUrl =
    'https://trocador.app/en/anonpay/'
    '?ticker_to=xmr&network_to=Mainnet'
    '&address=8AKYcpCAVrZhUJ4zEmMdgi36sa2DjTWxufpbnXLwzZKU4mnBrVVHWs2eU1SnGtKKBFB3hVVJSrRbZ1zJnGqyWUix5zdmagg'
    '&fiat_equiv=USD&name=GhostXMR&email=gh0stxmr@protonmail.com'
    '&bgcolor=00000000';

Future<void> _openTrocador(BuildContext context) async {
  final Uri uri = Uri.parse(_kTrocadorSwapUrl);
  final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open Trocador')),
    );
  }
}

class _CryptoAddressTile extends StatelessWidget {
  const _CryptoAddressTile({
    required this.symbol,
    required this.name,
    required this.address,
  });

  final String symbol;
  final String name;
  final String address;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: address));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$symbol address copied'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _copy(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            symbol,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            name,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        address,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copy address',
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copy(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
