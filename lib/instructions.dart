// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, deprecated_member_use, avoid_print, avoid_unnecessary_containers

import 'package:flutter/material.dart';
import 'package:android/custom_roms.dart';
import 'package:android/custom_rec.dart';
import 'package:android/home.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class InstructionsPage extends StatelessWidget {
  const InstructionsPage({Key? key}) : super(key: key);

  static const appTitle = 'Instructions';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      home: const MyInstPage(title: appTitle),
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

class MyInstPage extends StatelessWidget {
  const MyInstPage({super.key, required this.title});

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
                );
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
                      applicationVersion: "v0.2",
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
          ],
        ),
      ),
      body: ListView(children: <Widget>[
        Container(
            padding: EdgeInsets.only(top: 12.0, left: 15, right: 15),
            child: Text(
              '0: The Warnings',
              style: TextStyle(
                color: Colors.red,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            )),
        Container(
          padding: EdgeInsets.only(top: 12.0, left: 15, right: 15),
          child: Text(
            'Some device manufacturers like Samsung have security features like Knox that may cause issues and so it is good before starting you ensure your device has no security locks as these as they need manuevering to not trigger it but there are guides to help and it is possible. Some devices do not have TWRP or any custom recovery built for them so you can always build them on your own (automatically) using Android image kitchen. ',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w300,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Container(
          padding: EdgeInsets.only(
            bottom: 19,
            right: 19,
            left: 19,
          ),
          child: Text(
            'NO CUSTOM ROM AND CUSTOM RECOVERY MAINTAINER AND MAKER IS LIABLE FOR ANY DAMAGES DONE TO YOUR PHONE, SD CARD OR ANY OTHER DAMAGE OF YOUR PHONE. PLEASE FLASH AT YOUR OWN RISK. I AM ALSO NOT LIABLE TO SUCH DAMAGES AS WELL AND BY YOU PROCEEDING YOU ACCEPT THESE TERMS.',
            style: TextStyle(
              color: Colors.red,
              fontSize: 23,
              fontWeight: FontWeight.w300,
              fontStyle: FontStyle.italic,
              height: 2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Container(
            padding: EdgeInsets.only(top: 12.0, left: 15, right: 15),
            child: Text(
              '1: The Basics',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            )),
        Container(
          padding: EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
          child: Text(
            'What is a custom ROM?',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Container(
          padding: EdgeInsets.only(top: 12.0, left: 15, right: 15),
          child: Text(
            'Android being an operating system made by Google is open source. This means its (source) code is available to the public to use and modify. This is commonly known as the Android Open Source Project (AOSP). \n\nThe source code is modified by the public and this lead to the creation of custom ROMS, which are operating systems made by people outside of Google.\n\n The Custom ROMs are often Android in its purest form (vanilla) while others simply port operating systems from one phone to another, often for phones with a manufacturer skin on them that changes the look of Android like Samsung.\n\nSome ROMS offer Google Apps(gapps) while vanilla ROMS do not and they come with and are instead replaced with open source dialer app, camera app, messaging app and etc with no google apps or play store.',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'What is a custom Recovery?',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            )),
        Container(
          padding: EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
          child: Text(
            'Every Phone has a recovery and this is where you find settings such as rebooting, factory reset, erase cache and other system settings. \n\nThe recovery mode is often found when you turn off your phone and hold some buttons on your device and the phone boots into recovery...these buttons are specific to device and manufacturer so its best to read on how to do that on your device. \n\nThe custom recoveries basically replace this stock (original) recovery with an advanced one with menus and more that you can use to install Custom ROMS by flashing the ZIP files which is something you can not do on stock recovery, hence having a Custom Recovery is ESSENTIAL AND A MUST!',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
            textAlign: TextAlign.center,
          ),
        ),
        Container(
            padding: EdgeInsets.only(top: 12.0, left: 15, right: 15),
            child: Text(
              '2: The Intermediate',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'What do i need?',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              '1: Stock Firmware files',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            )),
        Container(
            padding: EdgeInsets.only(bottom: 19),
            child: Text(
              'This is our contigency plan when all things go wrong and it is what we will use to fix any mistakes.',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              '2: A System flash tool',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'This is the bridge between our phone to flash our stock firmware. You need it to back to stock as it is what you will use to flash stock firmware...custom recovery can not do this',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              '3: A Custom Recovery',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'As previously stated this is the hub where we flash our custom rom as we can not do this through the flash tool,',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              '4: A Custom ROM ZIP File/IMG file',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'These are the files you flash in the custom recovery to get the custom recovery. Flashing is as simple as swiping as a swipe on a button.',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              '5: The Chosen Phone/ Tablet',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'The one to ascend ',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              '6: A Laptop',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'This is where you should keep all files and it where the system flash tool is installed.',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              '7: ADB Platform Tools',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'A set of files that you will need to communicate with your device directly through the terminal. If you can not install custom recovery through the system flash tool you will have to push it and flash it through this way ',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              '8: Device Drivers',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'Makes sure your Device is seen by the computer. Make sure to check you have installed the right drivers for your device.',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              '2: The Advanced',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'Lets START',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'Step 0: Confirm that the Firmware files Work',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'Test the files by flashing your stock ROM to see if it works and that it is the correct one. Please research on how to flash your stock ROM as it is dependant on phone type and chip manufacturer',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'Step 1: Flash a custom Recovery',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'In your system Flash tool you may see a recovery section which you can place your custom recovery file to flash as the phones new recovery and the phone will boot into the new recovery you flashed. \n\nOdin (Samsung flash tool) does this. Otherwise flash the recovery through the terminal by booting your phone into fastboot mode and connect it to your pc and running fastboot flash recovery <recovery file name>.img Then running <fastboot reboot> to restart device then you hold the device specific button combination to boot into recovery. And thats it!',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'Step 2: Flash a Custom ROM',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'Once in the Custom recovery page. \n\nYou need to take the custom rom zip file and move it into your phone download page and in the recovery page you choose install and you navigate to where you saved the file and you pick the custom ROM zip file and you swipe to flash it and upon completion click the wipe cache and then click reboot.',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'Step 3 (Optional): Flash Gapps (Google Apps)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'Google apps are not installed natively in custom roms (unless specified) so you may need to flash a zip file of the Google Apps called Gapps to get the Google Play Store as well as some Google Apps that are specified in the Gapps package you chose...but note there are alternative app stores that you can use to get your favourite apps. \n\nA good example is the Aurora Store that allows install without a Google Account and you can spoof your device to get device specific apps. \n\nThere is also MicroG which works as a gapps alternative for when you need a google functionality in a bite sized format that is not systemwide like flashing gapps.',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'Step 3 (Optional): Flash Magisk',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'Magisk is our modern day rooter. It allows us to get root access systemlessly unlike the traditional and old root methods that actively changed the system partition in our device. \n\nMagisk gives us root and it installs to give us a wide range of features but please note that install of magisk may lead to device being detected as having root and banking apps may not work and Netflix will be hidden in the play store. \n\nThere are workarounds in magisk to hide magisk from the troublesome apps so that is not much of an issue. Enable Denylist and add the troublesome apps to hide root from them and reopen them to see changes. \n\nMagisk also used to offer modules that you can flash within the app to get a wide range of features but that has been removed and so you can use Foxs Magisk Module Manager to find all these modules and you can also flash them in the Fox app too and they will also appear in your Magisk App as an installed module.',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'You Are Done!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'You have Installed A Custom Recovery And A Custom ROM with Gapps. \n\nThat is all there is to do and you are set. The Magisk Root may cause problem in some Apps so its best to check the magisk settings and look for the Denylist and add the troublesome apps to hide root from them ',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
              textAlign: TextAlign.center,
            )),
      ]),
    );
  }
}
