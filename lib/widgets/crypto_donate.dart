import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Crypto donation addresses for Custom RR.
///
/// These are PLACEHOLDER addresses. Replace them with your real wallet
/// addresses when ready. They are always shown in the UI.
const Map<String, CryptoCoin> kCryptoDonationAddresses = <String, CryptoCoin>{
  'BTC': CryptoCoin(
    'Bitcoin (P2WPKH)',
    'bc1qaxx6dxkz0s5cw4h9nysw4yvmsaf3qlk7j0gwa2',
    lightning: 'monsiutech@cake.cash',
    explorerUrl:
        'https://mempool.space/address/bc1qaxx6dxkz0s5cw4h9nysw4yvmsaf3qlk7j0gwa2',
    walletScheme: 'bitcoin',
  ),
  'LTC': CryptoCoin(
    'Litecoin (P2WPKH)',
    'ltc1qdrjqjzk0sfn7grysxruxuuev6jpn9yqm8wrrg0',
    explorerUrl:
        'https://litecoinspace.org/address/ltc1qdrjqjzk0sfn7grysxruxuuev6jpn9yqm8wrrg0',
    walletScheme: 'litecoin',
  ),
  'ETH': CryptoCoin(
    'Ethereum (ETH and ERC-20 like USDT, USDC)',
    '0x4e815A295F8096997867FBA2d7bDC6316ad970be',
    explorerUrl:
        'https://etherscan.io/address/0x4e815A295F8096997867FBA2d7bDC6316ad970be',
    walletScheme: 'ethereum',
    networkChip: 'Mainnet',
    networkChipTone: NetworkChipTone.info,
  ),
  'BNB': CryptoCoin(
    'BNB Smart Chain (accepts ETH, USDT, USDC on BSC)',
    '0x4aCD5AD66DD8E64e3117d9cb0CB0434294027CDd',
    explorerUrl:
        'https://bscscan.com/address/0x4aCD5AD66DD8E64e3117d9cb0CB0434294027CDd',
    // EIP-681 style with chain id 56 = BNB Smart Chain. Most EVM wallets
    // (MetaMask, Trust Wallet, Rabby) respect the @<chainId> hint and
    // switch network automatically before pre-filling the send screen.
    // Older or simpler wallets may ignore the hint and stay on Ethereum
    // mainnet, so we show a confirm dialog before launching.
    walletScheme: 'ethereum',
    walletAddressSuffix: '@56',
    networkChip: 'BSC only',
    walletWarning:
        'Your wallet must be set to BNB Smart Chain (BSC) before sending. '
        'Most modern wallets switch automatically, but some open on '
        'Ethereum mainnet by default. Double-check the network on the '
        'send screen.',
  ),
  'SOL': CryptoCoin(
    'Solana',
    '6qC53PkKjoFtyhohHnYFApf3YccZwULFLTfrUMiruM97',
    explorerUrl:
        'https://solscan.io/account/6qC53PkKjoFtyhohHnYFApf3YccZwULFLTfrUMiruM97',
    walletScheme: 'solana',
  ),
  'XMR': CryptoCoin(
    'Monero',
    '8ADyd3DvN5D6wAauq2Q2BSZp7aG3LhYZAFswk5dNQohVUBDT8G84MjPimsj5vzfB8TBrwtC3y3BATNm76bX21kWfUys3ehE',
    walletScheme: 'monero',
  ),
};

class CryptoCoin {
  const CryptoCoin(
    this.name,
    this.address, {
    this.lightning,
    this.explorerUrl,
    this.walletScheme,
    this.walletAddressSuffix,
    this.walletWarning,
    this.networkChip,
    this.networkChipTone = NetworkChipTone.warning,
  });
  final String name;
  final String address;

  /// Optional Lightning Network address (e.g. a Lightning email-style
  /// address like `name@domain`). Shown as a footnote under the address.
  final String? lightning;

  /// Optional block-explorer URL pointing at this address. Lets donors
  /// verify on chain before sending. Omitted for privacy chains like XMR.
  final String? explorerUrl;

  /// URI scheme used to deep-link the user's installed wallet app for this
  /// coin (e.g. `bitcoin`, `ethereum`, `solana`, `monero`). When set, the
  /// tile renders an "Open in wallet" button that fires
  /// `<scheme>:<address><walletAddressSuffix>`.
  final String? walletScheme;

  /// Optional suffix appended after the address in the wallet URI. Used
  /// e.g. for EIP-681 chain hints like `@56` (BNB Smart Chain).
  final String? walletAddressSuffix;

  /// Optional warning shown in a confirm dialog before launching the
  /// wallet. Use this to remind the donor to switch network (e.g. BSC)
  /// when the URI scheme can't guarantee the right chain.
  final String? walletWarning;

  /// Optional short label rendered as a chip next to the coin name to
  /// flag a network constraint at a glance (e.g. `BSC only`).
  final String? networkChip;

  /// Visual tone for [networkChip]. Defaults to warning (red); use
  /// [NetworkChipTone.info] for neutral informational labels.
  final NetworkChipTone networkChipTone;

  /// Full deep-link URI for opening the address in an installed wallet.
  /// Returns `null` when [walletScheme] is not set.
  String? get walletUri {
    final String? scheme = walletScheme;
    if (scheme == null) return null;
    return '$scheme:$address${walletAddressSuffix ?? ''}';
  }
}

/// Visual styles for the per-coin network chip rendered in the donation
/// sheet. `warning` is a red error-container chip (wrong chain risk);
/// `info` is a neutral primary-container chip (just clarifying network).
enum NetworkChipTone { warning, info }

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
                'Tap a row to copy the address. Long-press for actions.',
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
                  lightning: entry.value.lightning,
                  explorerUrl: entry.value.explorerUrl,
                  walletUri: entry.value.walletUri,
                  walletWarning: entry.value.walletWarning,
                  networkChip: entry.value.networkChip,
                  networkChipTone: entry.value.networkChipTone,
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
    this.lightning,
    this.explorerUrl,
    this.walletUri,
    this.walletWarning,
    this.networkChip,
    this.networkChipTone = NetworkChipTone.warning,
  });

  final String symbol;
  final String name;
  final String address;
  final String? lightning;
  final String? explorerUrl;
  final String? walletUri;
  final String? walletWarning;
  final String? networkChip;
  final NetworkChipTone networkChipTone;

  Future<void> _copy(BuildContext context) async {
    await _copyValue(context, address, '$symbol address copied. Thank you for supporting Custom RR!');
  }

  Future<void> _copyLightning(BuildContext context) async {
    final String? ln = lightning;
    if (ln == null) return;
    await _copyValue(context, ln, 'Lightning address copied. Thank you for supporting Custom RR!');
  }

  Future<void> _copyValue(BuildContext context, String value, String message) async {
    // Capture before popping so the snackbar fires against the parent page.
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);
    await Clipboard.setData(ClipboardData(text: value));
    if (navigator.canPop()) {
      navigator.pop();
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showQr(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dctx) {
        final ColorScheme scheme = Theme.of(dctx).colorScheme;
        return AlertDialog(
          title: Text('$symbol address'),
          content: SizedBox(
            width: 260,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: QrImageView(
                    data: address,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  address,
                  style: Theme.of(dctx).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dctx).pop(),
              child: const Text('Close'),
            ),
            FilledButton.tonalIcon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: address));
                if (dctx.mounted) Navigator.of(dctx).pop();
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openExplorer(BuildContext context) async {
    final String? url = explorerUrl;
    if (url == null) return;
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openWallet(BuildContext context) async {
    final String? raw = walletUri;
    if (raw == null) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String? warning = walletWarning;
    if (warning != null) {
      final bool? proceed = await showDialog<bool>(
        context: context,
        builder: (BuildContext dctx) {
          return AlertDialog(
            title: Text('Check $symbol network'),
            content: Text(warning),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dctx).pop(true),
                child: const Text('Open wallet'),
              ),
            ],
          );
        },
      );
      if (proceed != true) return;
    }
    final Uri? uri = Uri.tryParse(raw);
    if (uri == null) return;
    bool launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!launched) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'No $symbol wallet app found. The address was copied so you can paste it.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await Clipboard.setData(ClipboardData(text: address));
    }
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
          onLongPress: () => _copy(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Symbol + network chip in a Wrap so the chip flows to a
                      // second line instead of overflowing on very narrow
                      // phones; both are short so they normally sit inline.
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text(
                            symbol,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (networkChip != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: networkChipTone ==
                                        NetworkChipTone.warning
                                    ? scheme.errorContainer
                                    : scheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                networkChip!,
                                maxLines: 1,
                                softWrap: false,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: networkChipTone ==
                                              NetworkChipTone.warning
                                          ? scheme.onErrorContainer
                                          : scheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Descriptive name on its own line so it can ellipsize
                      // without ever pushing the chip off-screen.
                      Text(
                        name,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                      if (lightning != null) ...<Widget>[
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _copyLightning(context),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  Icons.bolt,
                                  size: 14,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Lightning: ${lightning!}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          fontFamily: 'monospace',
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Show QR',
                  icon: const Icon(Icons.qr_code_2),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: const EdgeInsets.all(6),
                  onPressed: () => _showQr(context),
                ),
                if (walletUri != null)
                  IconButton(
                    tooltip: 'Open in wallet app',
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: const EdgeInsets.all(6),
                    onPressed: () => _openWallet(context),
                  ),
                if (explorerUrl != null)
                  IconButton(
                    tooltip: 'Verify on explorer',
                    icon: const Icon(Icons.open_in_new),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: const EdgeInsets.all(6),
                    onPressed: () => _openExplorer(context),
                  ),
                IconButton(
                  tooltip: 'Copy address',
                  icon: const Icon(Icons.copy),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: const EdgeInsets.all(6),
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
