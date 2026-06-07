import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../util/request_project.dart';

/// Standard AppBar share/contact menu used across all pages.
class AppShareMenu extends StatelessWidget {
  const AppShareMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ShareAction>(
      icon: const Icon(Icons.more_vert),
      onSelected: (_ShareAction action) async {
        switch (action) {
          case _ShareAction.share:
            await SharePlus.instance.share(
              ShareParams(
                text:
                    'Check out Custom RR: discover Android custom ROMs and recoveries! '
                    'Open source on GitHub: https://github.com/monsiu/Custom-RR',
                subject: 'Custom RR',
              ),
            );
            break;
          case _ShareAction.requestProject:
            await openProjectRequest(kind: 'ROM or recovery');
            break;
          case _ShareAction.contact:
            final Uri uri = Uri(
              scheme: 'mailto',
              path: 'contactmonsiu@gmail.com',
              query: 'subject=Custom RR Feedback',
            );
            await launchUrl(uri);
            break;
        }
      },
      itemBuilder: (BuildContext _) => const <PopupMenuEntry<_ShareAction>>[
        PopupMenuItem<_ShareAction>(
          value: _ShareAction.share,
          child: ListTile(
            leading: Icon(Icons.share_outlined),
            title: Text('Share the app'),
          ),
        ),
        PopupMenuItem<_ShareAction>(
          value: _ShareAction.requestProject,
          child: ListTile(
            leading: Icon(Icons.playlist_add),
            title: Text('Request a ROM or recovery'),
          ),
        ),
        PopupMenuItem<_ShareAction>(
          value: _ShareAction.contact,
          child: ListTile(
            leading: Icon(Icons.mail_outline),
            title: Text('Contact us'),
          ),
        ),
      ],
    );
  }
}

enum _ShareAction { share, requestProject, contact }
