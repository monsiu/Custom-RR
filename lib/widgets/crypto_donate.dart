import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
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
    'https://trocador.app/anonpay/'
    '?ticker_to=xmr&network_to=Mainnet'
    '&address=8AKYcpCAVrZhUJ4zEmMdgi36sa2DjTWxufpbnXLwzZKU4mnBrVVHWs2eU1SnGtKKBFB3hVVJSrRbZ1zJnGqyWUix5zdmagg'
    '&fiat_equiv=USD&name=Monsiu%20Tech&email=techmonsiu%40gmail.com'
    '&description=Donation%20to%20Custom%20RR%2C%20an%20open-source%20Android%20app%20cataloging%20custom%20ROMs%20and%20recoveries.'
    '&bgcolor=00000000'
    '&direct=False';

Future<void> _openTrocador(BuildContext context) async {
  // Capture the app-level messenger BEFORE popping the sheet so the snackbar
  // shows on the page underneath (not behind the now-closing modal).
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final NavigatorState navigator = Navigator.of(context);

  // Indirect method: GET the AnonPay URL with `direct=False` and Trocador
  // creates the transaction server-side, returning a JSON payload with the
  // transaction ID and a URL the user should be sent to. This prevents the
  // user from tampering with address/amount/etc. in the page.
  Uri? launchTarget;
  String? errorMessage;
  try {
    final http.Response res = await http
        .get(
          Uri.parse(_kTrocadorSwapUrl),
          headers: const <String, String>{'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final dynamic decoded = jsonDecode(res.body);
      if (decoded is Map) {
        final String? url = _pickString(decoded, const <String>[
          'url',
          'payment_url',
          'link',
        ]);
        if (url != null && url.isNotEmpty) {
          launchTarget = Uri.tryParse(url);
        }
      }
      if (launchTarget == null) {
        errorMessage = 'Unexpected response from Trocador';
      }
    } else {
      errorMessage = 'Trocador returned HTTP ${res.statusCode}';
    }
  } on TimeoutException {
    errorMessage = 'Trocador request timed out';
  } catch (_) {
    errorMessage = 'Could not reach Trocador';
  }

  if (launchTarget == null) {
    if (navigator.canPop()) {
      navigator.pop();
    }
    messenger.showSnackBar(
      SnackBar(content: Text(errorMessage ?? 'Could not open Trocador')),
    );
    return;
  }

  final bool ok = await launchUrl(
    launchTarget,
    mode: LaunchMode.inAppBrowserView,
  );
  if (navigator.canPop()) {
    navigator.pop();
  }
  if (ok) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Thank you for supporting Custom RR! Opening Trocador to swap to XMR.',
        ),
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } else {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not open Trocador')),
    );
  }
}

String? _pickString(Map<dynamic, dynamic> map, List<String> keys) {
  for (final String key in keys) {
    final dynamic v = map[key];
    if (v is String && v.isNotEmpty) {
      return v;
    }
  }
  return null;
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
    // Capture before popping so the snackbar fires against the parent page.
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);
    await Clipboard.setData(ClipboardData(text: address));
    if (navigator.canPop()) {
      navigator.pop();
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text('$symbol address copied. Thank you for supporting Custom RR!'),
        duration: const Duration(seconds: 3),
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
