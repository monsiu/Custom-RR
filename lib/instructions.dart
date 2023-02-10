// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, deprecated_member_use, avoid_print, avoid_unnecessary_containers

import 'package:flutter/material.dart';
import 'package:custom_rr/custom_roms.dart';
import 'package:custom_rr/custom_rec.dart';
import 'package:custom_rr/home.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:custom_rr/devices.dart';

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
          padding: EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
          child: Text(
            'Android being an operating system made by Google is open source. This means its (source) code is available to the public to use and modify. This is commonly known as the Android Open Source Project (AOSP). \n\nThe source code is modified by the public and this lead to the creation of custom ROMS, which are operating systems made by people outside of Google.\n\n The Custom ROMs are often Android in its purest form (vanilla) while others simply port operating systems from one phone to another, often for phones with a manufacturer skin on them that changes the look of Android like Samsung while others are Android modified however they see fit be it in theme and functionality.\n\nSome ROMS offer Google Apps(gapps) while vanilla ROMS do not and they come with and are instead replaced with open source dialer app, camera app, messaging app and etc with no Google apps or play store but rather apps developed to be open source meaning they are open for the public to review the source code or even modify.',
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
            'Every Phone has a recovery mode and this is where you find advanced settings such as rebooting, factory reset, erase cache and other advanced system settings. \n\nThe recovery mode is often found when you turn off your phone and hold some buttons on your device and the phone boots into recovery...these buttons are specific to device and manufacturer so its best to read on how to do that on your device but i will put a list to get an idea on what to try. \n\nThe custom recoveries basically replace this stock (original) recovery with an advanced one with menus and more that you can use to install Custom ROMS by flashing(basically installing) the ZIP files which is something you can not do on stock recovery, hence having a Custom Recovery is ESSENTIAL AND A MUST!',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
            textAlign: TextAlign.center,
          ),
        ),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'How To Enter Recovery Mode',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'Samsung Phone With A Home Button',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
                decoration: TextDecoration.underline,
              ),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'Step 1: Power off Device·\n\nStep 2: Hold volume up button, Home button, then power button together·\n\nStep 3: Release all buttons when the SAMSUNG logo appears on the screen.\n\nYour device will boot into recovery where you can use the volume keys to navigate and power button to select a highlighted option.',
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
              'Samsung Phone Without A Home Button',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
                decoration: TextDecoration.underline,
              ),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'Step 1: Power off Device·\n\nStep 2: Hold volume up button, then power button together·\n\nStep 3: Release all buttons when the SAMSUNG logo appears on the screen.\n\nStep 4: If the Android logo with "No command" pops up tap on the screen.\n\nYour device will go into recovery  where you can use the volume keys to navigate and power button to select a highlighted option.',
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
              'Samsung Phone Without A Home Button(ALT OPTION)',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
                decoration: TextDecoration.underline,
              ),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'Step 1: Connect the Type C cable from the computer to your mobile and hold down Volume Down + Power key for a few moments to  power off Device·\n\nStep 2: Hold volume up button then power button together·\n\nStep 3: Release all buttons when the SAMSUNG logo appears on the screen.\n\nYour device will boot into recovery where you can use the volume keys to navigate and power button to select a highlighted option.',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            )),
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
              'This are the files that contain everything needed to return the phone back to its original state(Stock) as it was directly from the manufacturers.\n\nWe need this in case things go wrong be it flashing the wrong ROM or anything really.\n\nThe files revert back the Recovery and Operating System to its original state thus clearing any problems encountered.',
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
              'This is the bridge between your phone and computer used to flash our stock firmware. You need it to back to stock as it is what you will use to flash stock firmware files...custom recovery can not do this sadly as each manufacturer has different files and software that are in obscure file formats requiring the special firmware distributed by the manufacturer.\n\nSamsung for example uses ODIN as the firmware to flash your phone.\n\nYou will also need a system flash tool to flash Custom Recovery on your phone.',
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
              'As previously stated this is the hub where we flash our custom ROMS as we can not do this on the Stock Recovery. In the Custom Recovery is where we will flash everything and we can even flash custom recoveries to switch up on the fly.\n\nI have a page of custom recoveries where you can have your pick.',
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
              'These are the files you flash in the custom recovery to get the custom recovery. Flashing (Installing)is as simple as swiping as a swipe on a button. You will usually find the files that can be flashed are usually image files(.img file) or ZIP files and can range from custom ROMS and Recoveries to even phone software like Magisk which is our modern day rooting software.',
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
              'This is where you should keep all files and it where the Stock flash tool will be installed which you will need to flash the custom recovery. You will also use the laptop to transfer files from laptop to phone when needed.',
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
              'A set of files that you will need to communicate with your device directly through the terminal. IT IS REQUIRED FOR YOUR DEVICE TO BE DETECTED BY THE COMPUTER. Alsc, if you can not install custom recovery through the system flash tool you will have to push it and flash it through the terminal.',
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
              'Makes sure your Device is seen by the computer. Make sure to check you have installed the right drivers for your device. Windows tends to do this automatically so you need to check for optional updates and install them. You can also download the drivers specific to your device.',
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
              'Unlock the Bootloader',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'Open your phone’s app drawer, tap the Settings icon, and select “About Phone”. Scroll all the way down and tap the “Build Number” item seven times. You should get a message saying you are now a developer.\n\nHead back to the main Settings page, and you should see a new option near the bottom called “Developer Options”. Open that, and enable “OEM Unlocking”, if the option exists (if it doesn’t, no worries–it’s only necessary on some phones).\n\nOnce that’s done, connect your phone to your computer. You should see a popup entitled “Allow USB Debugging?” on your phone. Check the “Always allow from this computer” box and tap OK.',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'Boot into FASTBOOT mode/Download Mode for Samsung Devices',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'Turn off your device and wait until it vibrates to indicate a successful shutdown.\n\nPress the Power button and the Volume Down button(+home button if available) and hold them down for a few seconds.\n\nThe device will soon reboot into Fastboot Mode/Download mode. You can let go of the buttons now.',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'Continue unlocking bootloader',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )),
        Container(
            padding:
                EdgeInsets.only(bottom: 19, top: 12.0, left: 15, right: 15),
            child: Text(
              'In the previous unlocking bootloader step you had allowed your phone to be able to unlock bootloader as the bootloader is always locked, now at this step its the final step to unlock bootloader.\n\nYou need to open the terminal on your computer and while your phone is in fastboot mode you need to connect it via USB and type some code namely \n\n<fastboot flashing unlock> \n\nor\n\n<fastboot oem unlock>\n\n This will require confirmation on your phone using the volume button and upon accepting you will have fully unlocked bootloader.\n\nPlease note that some devices have special processes to unlock bootloader and so you can check the Devices page in this app to get info as per your device.',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
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
              'Test the files by flashing your stock ROM to see if it works and that it is the correct one. You need to be in fastboot mode/download mode to flash the stock firmware or custom recovery(both of these need the flashing tool provided by your manufacturer). \n\nOn the Download Page you will get instructions on how to flash the files in the Flashing tool. \n\nPlease check the Device section in the app drawer to get detailed info on how to flash your official firmware files.',
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
              'In your system Flash tool you may see a recovery section which you can place your custom recovery file(.img file) to flash the phone’s new recovery and the phone will boot into the new recovery you flashed once completed(if not just reboot by holding down the volume down button and power button). \n\n Otherwise flash the recovery through the terminal by booting your phone into fastboot mode as stated above and connect it to your pc and run \n\n<fastboot flash recovery (recovery file name).img> \n\n(brackets and chevrons not added) \n\nThen running \n\n<fastboot reboot> to restart device\n\n then you hold the device specific button combination to boot into recovery. And thats it!',
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
              'Once in the Custom recovery page. \n\nYou need to take the downloaded custom ROM zip file from your laptop and move it into your phone storage.\n\nOnce done, head in the custom recovery in your phone and choose install and you navigate to where you saved the file and you pick the custom ROM zip file(or image file) and you swipe to flash it and upon completion click the wipe cache and then click reboot.',
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
              'Google apps are not installed natively in custom roms (except some which come natively installed) so you may need to flash a zip file of the Google Apps called Gapps to get the Google Play Store as well as some Google Apps that are specified in the Gapps package you chose.\n\nPlease note there are alternative App Stores that you can use to get your favourite apps, Google or otherwise, that do not need GAPPS as some users do not want Google installed on their devices for security purposes . \n\nA good example is the Aurora Store that allows install without a Google Account and you can spoof your device to get device specific apps. \n\nThere is also MicroG which works as a gapps alternative for when you need a Google functionality in a bite sized format that is not systemwide like flashing gapps.',
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
              'Magisk is our modern day rooter. It allows us to get root access systemlessly unlike the traditional and old root methods that actively changed the system partition in our device. \n\nMagisk gives us root and it installs to give us a wide range of features and one that is popular is Viper4Android that takes audio in your device to a whole new but please note that install of magisk may lead to device being detected as having root and banking apps may not work and Netflix will be hidden in the play store. \n\nThere are workarounds in magisk to hide magisk from the troublesome apps so that is not much of an issue.\n\nEnable Denylist and add the troublesome apps to hide root from them and reopen them to see changes. \n\nMagisk also used to offer modules that you can flash within the app to get a wide range of features but that has been removed and so you can use Foxs Magisk Module Manager to find all these modules and you can also flash them in the Fox app too and they will also appear in your Magisk App as an installed module.',
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
              'You have Installed A Custom Recovery And A Custom ROM with Gapps. \n\nThat is all there is to do and you are set.\n\nThe Magisk Root may cause problem in some Apps so its best to check the magisk settings and look for the Denylist and add the troublesome apps to hide root from them ',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
              textAlign: TextAlign.center,
            )),
      ]),
    );
  }
}
