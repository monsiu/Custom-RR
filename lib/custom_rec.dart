// ignore_for_file: prefer_const_constructors, avoid_unnecessary_containers, prefer_const_literals_to_create_immutables, unused_import, deprecated_member_use, avoid_print
import 'package:custom_rr/devices.dart';
import 'package:custom_rr/twrp.dart';
import 'package:custom_rr/redwolfrec.dart';
import 'package:custom_rr/pitchblackrec.dart';
import 'package:custom_rr/skyhawkrec.dart';
import 'package:custom_rr/custom_roms.dart';
import 'package:custom_rr/orangefoxrec.dart';
import 'package:share_plus/share_plus.dart';
import 'package:custom_rr/crdroid.dart';
import 'package:custom_rr/pixelexperience.dart';
import 'package:custom_rr/dotos.dart';
import 'package:custom_rr/arrowos.dart';
import 'package:custom_rr/bliss.dart';
import 'package:custom_rr/evolutionx.dart';
import 'package:custom_rr/paranoidandroid.dart';
import 'package:custom_rr/potatoaosp.dart';
import 'package:custom_rr/lineage.dart';
import 'package:custom_rr/havoc.dart';
import 'package:flutter/material.dart';
import 'package:custom_rr/home.dart';
import 'package:custom_rr/instructions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomrecPage extends StatelessWidget {
  const CustomrecPage({Key? key}) : super(key: key);

  static const appTitle = 'Custom Recoveries';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      home: const MycustomrecsPage(title: appTitle),
      theme: ThemeData(
          brightness: Brightness.light,
          /* light theme settings */
          canvasColor: Colors.white,
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        /* dark theme settings */
      ),
      themeMode: ThemeMode.system,
      /* ThemeMode.system to follow system theme, 
         ThemeMode.light for light theme, 
         ThemeMode.dark for dark theme
      */
    );
  }
}

class MycustomrecsPage extends StatelessWidget {
  const MycustomrecsPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(title),
          actions: <Widget>[
            IconButton(
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: CustomSearchDelegate(),
                );
              },
              icon: const Icon(Icons.search),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'share') {
                  Share.share(
                      "Custom RR is the home of Custom ROMS and Recoveries that are all sourced from the official websites. All found in one place! \n\nDownload here: www.github.com/monsiu/Custom-RR",
                      subject:
                          "Check out this cool app to get all your Custom Roms and Recoveries!");
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(
                        Icons.share,
                        color: Color(0xFF7ed957),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text("Share the App")
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: '2',
                  child: Row(
                    children: [
                      Icon(
                        Icons.mail,
                        color: Color(0xFF7ed957),
                      ),
                      SizedBox(
                        width: 12,
                      ),
                      Text("Message Us")
                    ],
                  ),
                  onTap: () => launch(
                      'mailto:contactmonsiu@gmail.com?subject=QUERY%20AND%20SUGGESTIONS%20'),
                ),
              ],
            ),
          ],
        ),
        drawer: Drawer(
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          child: ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                    color: Color(0xFF7ed957),
                    image: DecorationImage(
                        image: AssetImage('images/splash.jpg'),
                        fit: BoxFit.cover)),
                child: null,
              ),
              ListTile(
                leading: const Icon(
                  Icons.house,
                  size: 34.0,
                  semanticLabel: 'Home Page',
                ),
                title: const Text('Home'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomePage()));
                  // Update the state of the app
                  // ...
                  // Then close the drawer
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.settings,
                  size: 34.0,
                  semanticLabel: 'Custom Roms',
                ),
                title: const Text('Custom Roms'),
                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CustomromsPage()));
                  // Update the state of the app
                  // ...
                  // Then close the drawer
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.sync,
                  size: 34.0,
                  semanticLabel: 'Custom Recoveries',
                ),
                title: const Text('Custom Recoveries'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CustomrecPage()));
                  // Update the state of the app
                  // ...
                  // Then close the drawer
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.devices,
                  size: 34.0,
                  semanticLabel: 'Devices',
                ),
                title: const Text('Devices'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DevicesPage()));
                  // Update the state of the app
                  // ...
                  // Then close the drawer
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.library_books,
                  size: 34.0,
                  semanticLabel: 'Instructions and info',
                ),
                title: const Text('Instructions'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const InstructionsPage()));
                  // Update the state of the app
                  // ...
                  // Then close the drawer
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.monetization_on,
                  size: 34.0,
                  semanticLabel: 'Support the Project',
                ),
                title: const Text('Support Us'),
                onTap: () => showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: Center(child: const Text('WOW Thanks So MUCH!!')),
                    content: Wrap(
                      children: [
                        ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: Image.asset('images/bmc.png')),
                        SizedBox(
                          width: double.infinity,
                          height: 6,
                        ),
                        Center(
                            child: Text.rich(
                          textAlign: TextAlign.center,
                          TextSpan(
                              text:
                                  'Thank you so much for your contribution to the project since its basically a one man show. You are really awesome.\n\nScan the QR code or just click the \n"Buy Me A Coffee" button below.'),
                        )),
                        GestureDetector(
                          onTap: () async {
                            String url =
                                'https://www.buymeacoffee.com/monsiuYT';
                            if (await canLaunch(url)) {
                              await launch(
                                url,
                                forceSafariVC: false,
                                forceWebView: false,
                                //enableJavaScript: true,
                                //enableDomStorage: true,
                                //webOnlyWindowName: '_self',
                              );
                            } else {
                              print("Not Supported");
                            }
                          },
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: Image.asset(
                                'images/bmcb.png',
                                width: 200,
                                height: 100,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 50,
                        ),
                      ],
                    ),
                    elevation: 24,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16))),
                    actions: <Widget>[
                      IconButton(
                        onPressed: () {
                          showSearch(
                            context: context,
                            delegate: CustomSearchDelegate(),
                          );
                        },
                        icon: const Icon(Icons.search),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'OK'),
                        child: const Text('Enjoy the coffee  ☕'),
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                  leading: const Icon(
                    Icons.info,
                    size: 34.0,
                    semanticLabel: 'Instructions and info',
                  ),
                  title: const Text('About'),
                  onTap: () {
                    Navigator.pop(context);
                    AboutDialog;
                    showAboutDialog(
                        context: context,
                        applicationIcon: ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: (Image.asset(
                            'images/launcher.png',
                            width: 50,
                          )),
                        ),
                        applicationVersion: "v0.3",
                        applicationName: "Custom RR",
                        applicationLegalese: '\u{a9} 2023 Monsiu Tech',
                        children: <Widget>[
                          SizedBox(height: 24),
                          Container(
                            child: Text(
                              'Custom RR is not affiliated with Google. Monsiu and Custom ROM and Recoveries creators and maintainers are NOT liable for any damages done to your device in any shape or form. You ARE responsible for what you do.',
                              textAlign: TextAlign.left,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                          ),
                          Container(
                            child: InkWell(
                              child: Text(
                                'TERMS AND CONDITIONS',
                                style: TextStyle(color: Colors.blue),
                              ),
                              //onTap: () => launch('https://docs.flutter.io/flutter/services/UrlLauncher-class.html')
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                          ),
                          Container(
                            child: InkWell(
                              child: Text(
                                'PRIVACY POLICY',
                                style: TextStyle(color: Colors.blue),
                              ),
                              //onTap: () => launch('https://docs.flutter.io/flutter/services/UrlLauncher-class.html')
                            ),
                          )
                        ]);
                    // Update the state of the app
                    // ...
                    // Then close the drawer
                  }),
              ListTile(
                leading: const Icon(
                  Icons.update,
                  size: 34.0,
                  semanticLabel: 'Check for Updates',
                ),
                title: const Text('Check for Updates'),
                onTap: () async {
                  Navigator.pop(context);
                  // Check for updates
                  // ...
                  // Show a prompt for the user to update
                  // ...
                },
              ),
            ],
          ),
        ),
        body: ListView(children: <Widget>[
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Container(
              child: SizedBox(
                height: 450.0,
                child: Card(
                  elevation: 2.0,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TwrpPage(),
                          ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          CachedNetworkImage(
                            imageUrl:
                                "https://i0.wp.com/www.androidsage.com/wp-content/uploads/2021/01/TWRP-recovery.jpg",
                            placeholder: (context, url) =>
                                CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                          ),
                          SizedBox(
                            height: 20.0,
                          ),
                          Center(
                            child: Text(
                              'Team Win Recovery Project (TWRP)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(
                              top: 19,
                            ),
                            child: Center(
                              child: Text(
                                textAlign: TextAlign.center,
                                'Team Win Recovery Project is an open-source software custom recovery image for Android-based devices. It supports a widest range of Devices in the Custom Recovery space',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Container(
              child: SizedBox(
                height: 400,
                child: Card(
                  elevation: 2.0,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RedwolfrecPage(),
                          ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          CachedNetworkImage(
                            imageUrl:
                                "https://forum.xda-developers.com/proxy.php?image=https%3A%2F%2Fpreview.ibb.co%2FdEEWNk%2F1495640672222.png&hash=39f616ef3fe8296072c24e0f4585d3c9",
                            placeholder: (context, url) =>
                                CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                          ),
                          SizedBox(
                            height: 20.0,
                          ),
                          Center(
                            child: Text(
                              'Red Wolf Recovery Project',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(
                              top: 19,
                            ),
                            child: Center(
                              child: Text(
                                textAlign: TextAlign.center,
                                'Red Wolf Recovery is custom recovery based on TWRP source code, however some things are working here slightly different then you might expected. ​',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Container(
              child: SizedBox(
                height: 360.0,
                child: Card(
                  elevation: 2.0,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PitchblackrecPage(),
                          ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          CachedNetworkImage(
                            imageUrl:
                                "https://techsphinx.com/wp-content/uploads/2020/09/PBRP.png",
                            placeholder: (context, url) =>
                                CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                          ),
                          SizedBox(
                            height: 20.0,
                          ),
                          Center(
                            child: Text(
                              'Pitch Black Recovery Project',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(
                              top: 19,
                            ),
                            child: Center(
                              child: Text(
                                textAlign: TextAlign.center,
                                'Pitch Black Recovery is a fork of TWRP with many improvements to make your experience better. It\'s more flexible & easy to use.',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Container(
              child: SizedBox(
                height: 350.0,
                child: Card(
                  elevation: 2.0,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrangefoxrecPage(), //orange
                          ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          CachedNetworkImage(
                            imageUrl:
                                "https://xiaomitools.com/wp-content/uploads/2020/04/of_forums_header_v2_hed_2-1024x432.jpg",
                            placeholder: (context, url) =>
                                CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                          ),
                          SizedBox(
                            height: 20.0,
                          ),
                          Center(
                            child: Text(
                              'Orange Fox Recovery Project',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(
                              top: 19,
                            ),
                            child: Center(
                              child: Text(
                                textAlign: TextAlign.center,
                                'OrangeFox Recovery is one of the most popular custom recoveries, with additional features, fixes and a host of supported devices.',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Container(
              child: SizedBox(
                height: 400.0,
                child: Card(
                  elevation: 2.0,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SkyhawkrecPage(),
                          ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          CachedNetworkImage(
                            imageUrl:
                                "https://forum.xda-developers.com/proxy.php?image=https%3A%2F%2Fgithub.com%2FDNI9%2FSHRP_%2Fraw%2Fmaster%2Fimg%2Fshrp3_banner_xda.png&hash=64337414359ef1feb6f4de18c17c665b",
                            placeholder: (context, url) =>
                                CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                          ),
                          SizedBox(
                            height: 20.0,
                          ),
                          Center(
                            child: Text(
                              'Sky Hawk Recovery Project',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(
                              top: 19,
                            ),
                            child: Center(
                              child: Text(
                                textAlign: TextAlign.center,
                                'SHRP is inspired by mordern design to bring the newest design to the native TWRP. SHRP provides much more along side of it\'s rich UI experience. New dashboard makes it very easy to interact with TWRP.',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]));
  }
}

class CustomSearchDelegate extends SearchDelegate {
  List<String> searchTerms = [
    'Red Wolf Recover',
    'TWRP (Team Win Recovery Project)',
    'OrangeFox Recovery',
    'PitchBlack Recovery',
    'Skyhawk Recovery',
  ];
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    List<String> matchQuery = [];
    for (var device in searchTerms) {
      if (device.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(device);
      }
    }
    return ListView.builder(
      itemCount: matchQuery.length,
      itemBuilder: (context, index) {
        var result = matchQuery[index];
        return ListTile(
          title: Text(result),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<String> matchQuery = [];
    for (var device in searchTerms) {
      if (device.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(device);
      }
    }
    return ListView.builder(
      itemCount: matchQuery.length,
      itemBuilder: (context, index) {
        var result = matchQuery[index];
        return ListTile(
          title: Text(result),
          onTap: () {
            query = result;
          },
        );
      },
    );
  }
}
