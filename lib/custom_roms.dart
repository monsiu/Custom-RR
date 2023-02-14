// ignore_for_file: prefer_const_constructors, avoid_unnecessary_containers, prefer_const_literals_to_create_immutables, deprecated_member_use, avoid_print
import 'package:custom_rr/crdroid.dart';
import 'package:custom_rr/pixelexperience.dart';
import 'package:custom_rr/dotos.dart';
import 'package:custom_rr/arrowos.dart';
import 'package:custom_rr/bliss.dart';
import 'package:custom_rr/evolutionx.dart';
import 'package:custom_rr/paranoidandroid.dart';
import 'package:custom_rr/potatoaosp.dart';
import 'package:custom_rr/lineage.dart';
import 'package:custom_rr/devices.dart';
import 'package:custom_rr/havoc.dart';
import 'package:flutter/material.dart';
import 'package:custom_rr/custom_rec.dart';
import 'package:custom_rr/home.dart';
import 'package:custom_rr/instructions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class CustomromsPage extends StatelessWidget {
  const CustomromsPage({Key? key}) : super(key: key);

  static const appTitle = 'Custom ROMS';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      home: const MycustomromsPage(title: appTitle),
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

class MycustomromsPage extends StatelessWidget {
  const MycustomromsPage({super.key, required this.title});

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
                      "Custom RR is the home of Custom ROMS and Recoveries that are all sourced from the official websites. All found in one place! \n\n Download here: www.github.com/monsiu",
                      subject:
                          "Check out this cool app to get all your Custom Roms and Recoveries!");
                  Share.shareFiles(['images/launcher.png'], text: 'Custom RR');
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
                height: 550.0,
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
                                child: Image.asset('images/havoc.png')),
                          ),
                          SizedBox(
                            height: 20.0,
                          ),
                          Center(
                            child: Text(
                              'Havoc OS',
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
                                'Havoc-OS is an after-market firmware based on Android Open Source Project that brings a new take on the Android Experience with a good share of customization options.',
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
                height: 550,
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
                                child: Image.asset('images/lineageos.png')),
                          ),
                          SizedBox(
                            height: 20.0,
                          ),
                          Center(
                            child: Text(
                              'Lineage OS',
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
                                'The successor to CyanogenMod. Lineage ROM offers stability and reliability with little customization but makes up for it with its own feel of Android with its own Launcher. ',
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
                height: 550.0,
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
                                child: Image.asset('images/crdroid hori.png')),
                          ),
                          SizedBox(
                            height: 20.0,
                          ),
                          Center(
                            child: Text(
                              'crDroid OS',
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
                                'crDroid is a Custom Rom that offers wide number of settings and cutomizations which are really impressive all while being stable and functional.',
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
                height: 590.0,
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
                                child:
                                    Image.asset('images/pixelexperience.png')),
                          ),
                          SizedBox(
                            height: 20.0,
                          ),
                          Center(
                            child: Text(
                              'Pixel Experience OS',
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
                                'PixelExperience is an AOSP based ROM, with Google apps (gapps) included and all Pixel goodies and functionality. Including ROM, Launcher and exclusive pixel features. Giving you the true Pixel Experience on non-Pixel deices',
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
                height: 580.0,
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
                                child: Image.asset('images/arrowos.png')),
                          ),
                          SizedBox(
                            height: 20.0,
                          ),
                          Center(
                            child: Text(
                              'Arrow OS',
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
                                'Arrow OS, An AOSP project that takes pride in being a project started with the goal of keeping things simple, clean, and organized while adding features that will be helpful in the long run all while aiming to deliver smooth performance and longer battery life.',
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
                height: 550.0,
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
                                child: Image.asset('images/evolutionx.png')),
                          ),
                          SizedBox(
                            height: 20.0,
                          ),
                          Center(
                            child: Text(
                              'Evolution X OS',
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
                                'Evolution X Custom ROM allows users to experience Google\'s latest Pixel updates while integrating useful features from known custom ROMs.',
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
                height: 580.0,
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
                                child:
                                    Image.asset('images/paranoidandroid.png')),
                          ),
                          SizedBox(
                            height: 20.0,
                          ),
                          Center(
                            child: Text(
                              'Paranoid Android OS',
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
                                'Paranoid Android is a custom ROM aiming to extend the system, working on enhancing the already existing beauty of Android and following the same design philosophies that were set forward by Google.',
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
                height: 550.0,
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
                                child: Image.asset('images/dotos.png')),
                          ),
                          SizedBox(
                            height: 20.0,
                          ),
                          Center(
                            child: Text(
                              'Dot OS',
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
                                'DroidOnTime(DOT OS) is a custom Android firmware launched with an aim to provide Unique user interface and Optimum performance.',
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
                height: 570.0,
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
                                child: Image.asset('images/blissrom.png')),
                          ),
                          SizedBox(
                            height: 20.0,
                          ),
                          Center(
                            child: Text(
                              'Bliss ROM OS',
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
                                'An Open Source OS, based on Android, that incorporates many optimizations, features, and expanded device support. And it is available for just about any Chromebook, Windows/Linux PC or tablet released in the last 4 years',
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
                height: 500.0,
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
                                child: Image.asset('images/potatoaosp.png')),
                          ),
                          SizedBox(
                            height: 20.0,
                          ),
                          Center(
                            child: Text(
                              'Potato AOSP',
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
                                'Potato Open Sauce Project (POSP) defines itself as a buttery smooth aftermarket Android™ firmware.',
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
