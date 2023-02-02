// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import, deprecated_member_use, avoid_print, avoid_unnecessary_containers
import 'package:android/updatedialog.dart';
import 'package:new_version/new_version.dart';
import 'package:flutter/material.dart';
import 'package:android/custom_roms.dart';
import 'package:android/instructions.dart';
import 'package:android/custom_rec.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:share_plus/share_plus.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  static const appTitle = 'Home Page';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      home: const MyHomePage(title: appTitle),
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

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

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
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const HomePage()));
                // Update the state of the app
                // ...
                // Then close the drawer
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.phone_android,
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
                Icons.restore,
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
                Icons.file_copy,
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
                Icons.monetization_on_outlined,
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
                          String url = 'https://www.buymeacoffee.com/monsiuYT';
                          if (await canLaunch(url)) {
                            await launch(
                              url,
                              forceSafariVC: true,
                              forceWebView: true,
                              enableJavaScript: true,
                              enableDomStorage: true,
                              webOnlyWindowName: '_self',
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
                        height: 10,
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
                      applicationVersion: "v1.0",
                      applicationName: "Custom RR",
                      applicationLegalese: '\u{a9} 2022 Monsiu Tech',
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
          ],
        ),
      ),
      body: ListView(children: <Widget>[
        Container(
            padding: EdgeInsets.only(top: 19),
            child: Text(
              'WELCOME TO CUSTOM RR',
              style: TextStyle(
                color: Color(0xFF7ed957),
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            )),
        Container(
          padding: EdgeInsets.only(top: 19),
          child: Text(
            'Custom RR is the Home of ROMS and Recoveries(RR).',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Container(
          padding: EdgeInsets.only(
            top: 19,
            right: 19,
            left: 19,
          ),
          child: Text(
            'We list all ROMS and Recoveries for (almost) every device and for every obscure device, we offer guidance on what to do as I feel this is a hurdle an enthusiastic flasher may encounter.',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(30.0),
          child: Hero(
              tag: 'img',
              child: Image.asset(
                'images/splash_image.png',
              )),
        ),
      ]),
    );
  }
}
