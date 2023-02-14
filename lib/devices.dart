// ignore_for_file: prefer_const_constructors, avoid_unnecessary_containers, prefer_const_literals_to_create_immutables, unused_import, deprecated_member_use, avoid_print
import 'package:custom_rr/custom_rec.dart';
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

class DevicesPage extends StatelessWidget {
  const DevicesPage({Key? key}) : super(key: key);

  static const appTitle = 'Devices';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      home: const MyDevicesPage(title: appTitle),
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

class MyDevicesPage extends StatelessWidget {
  const MyDevicesPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(title),
          actions: <Widget>[
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
                height: 380.0,
                child: Card(
                  elevation: 2.0,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HavocPage(),
                          ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Hero(
                                tag: 'img',
                                child: Image.asset(
                                  'images/samsung.png',
                                  width: 500,
                                  height: 300,
                                )),
                          ),
                          SizedBox(
                            height: 10.0,
                          ),
                          Center(
                            child: Text(
                              'Samsung Devices',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
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
                height: 480,
                child: Card(
                  elevation: 2.0,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LineagePage(),
                          ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Hero(
                                tag: 'img',
                                child: Image.asset(
                                  'images/sony.png',
                                  width: 600,
                                  height: 400,
                                )),
                          ),
                          SizedBox(
                            height: 10.0,
                          ),
                          Center(
                            child: Text(
                              'Sony Devices',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
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
                height: 434.0,
                child: Card(
                  elevation: 2.0,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CrdroidPage(),
                          ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Hero(
                                tag: 'img',
                                child: Image.asset(
                                  'images/huawei.png',
                                  width: 450,
                                  height: 320,
                                )),
                          ),
                          SizedBox(
                            height: 43.0,
                          ),
                          Center(
                            child: Text(
                              'Huawei Devices',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
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
                height: 473.0,
                child: Card(
                  elevation: 2.0,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PixelexperiencePage(),
                          ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Hero(
                                tag: 'img',
                                child: Image.asset(
                                  'images/lg.png',
                                  width: 500,
                                  height: 400,
                                )),
                          ),
                          SizedBox(
                            height: 1.0,
                          ),
                          Center(
                            child: Text(
                              'LG Devices',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
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
                            builder: (context) => ArrowosPage(),
                          ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Hero(
                                tag: 'img',
                                child: Image.asset(
                                  'images/nokia.png',
                                  width: 400,
                                  height: 300,
                                )),
                          ),
                          SizedBox(
                            height: 35.0,
                          ),
                          Center(
                            child: Text(
                              'Nokia Devices',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
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
                height: 380.0,
                child: Card(
                  elevation: 2.0,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EvolutionxPage(),
                          ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Hero(
                                tag: 'img',
                                child: Image.asset(
                                  'images/motorola.png',
                                  width: 500,
                                  height: 300,
                                )),
                          ),
                          SizedBox(
                            height: 10.0,
                          ),
                          Center(
                            child: Text(
                              'Motorola Devices',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
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
                height: 470.0,
                child: Card(
                  elevation: 2.0,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ParanoidandroidPage(),
                          ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Hero(
                                tag: 'img',
                                child: Image.asset(
                                  'images/lenovo.png',
                                  width: 500,
                                  height: 400,
                                )),
                          ),
                          SizedBox(
                            height: 0.1,
                          ),
                          Center(
                            child: Text(
                              'Lenovo Devices',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
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
                height: 500.0,
                child: Card(
                  elevation: 2.0,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DotosPage(),
                          ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Hero(
                                tag: 'img',
                                child: Image.asset(
                                  'images/google.png',
                                  width: 500,
                                  height: 400,
                                )),
                          ),
                          SizedBox(
                            height: 26.0,
                          ),
                          Center(
                            child: Text(
                              'Google Pixel Devices',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
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
                height: 510.0,
                child: Card(
                  elevation: 2.0,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlissromPage(),
                          ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Hero(
                                tag: 'img',
                                child: Image.asset(
                                  'images/oneplus.png',
                                  width: 500,
                                  height: 400,
                                )),
                          ),
                          SizedBox(
                            height: 35.0,
                          ),
                          Center(
                            child: Text(
                              'Oneplus Devices',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
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
                height: 489.0,
                child: Card(
                  elevation: 2.0,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PotatoaospPage(),
                          ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Hero(
                                tag: 'img',
                                child: Image.asset(
                                  'images/xiaomi.png',
                                  width: 500,
                                  height: 400,
                                )),
                          ),
                          SizedBox(
                            height: 22.0,
                          ),
                          Center(
                            child: Text(
                              'Xiaomi Devices',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
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
                height: 500.0,
                child: Card(
                  elevation: 2.0,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DotosPage(),
                          ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Hero(
                                tag: 'img',
                                child: Image.asset(
                                  'images/treble.png',
                                  width: 500,
                                  height: 400,
                                )),
                          ),
                          SizedBox(
                            height: 26.0,
                          ),
                          Center(
                            child: Text(
                              'Project Treble Devices',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
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
