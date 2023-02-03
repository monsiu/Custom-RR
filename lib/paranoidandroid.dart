// ignore_for_file: prefer_const_constructors, deprecated_member_use, avoid_print
import 'package:carousel_images/carousel_images.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final List<String> imgList = [
  'https://xiaomiui.net/wp-content/uploads/2022/04/Paranoid-Android-Sound-Panel.jpg',
  'https://xiaomiui.net/wp-content/uploads/2022/04/Paranoid-Android-App-Drawer.jpg',
  'https://xiaomiui.net/wp-content/uploads/2022/04/Paranoid-Android-Sound-Panel.jpg',
  'https://xiaomiui.net/wp-content/uploads/2022/04/Paranoid-Android-Lockscreen.jpg',
  'https://xiaomiui.net/wp-content/uploads/2022/04/Paranoid-Android-Quick-Settings.png',
  'https://community.myteracube.com/uploads/db0118/original/2X/9/93e11378bd14ded3566868a3fd39ba49334bc4a7.jpeg',
  'https://community.myteracube.com/uploads/db0118/original/2X/9/93e11378bd14ded3566868a3fd39ba49334bc4a7.jpeg',
  'https://pbs.twimg.com/media/FUpeN6BWUAAI0kt.jpg',
];

class ParanoidandroidPage extends StatelessWidget {
  const ParanoidandroidPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Paranoid Android'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(tag: 'img', child: Image.asset('images/paranoidandroid.png')),
            Center(
                child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                'Paranoid Android OS',
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline),
              ),
            )),
            SizedBox(
              height: 20.0,
            ),
            Center(
              child: Padding(
                  padding:
                      const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                  child: Text(
                    'Paranoid Android is a custom ROM aiming to extend the system, working on enhancing the already existing beauty of Android and following the same design philosophies that were set forward by Google for Android Open Source Project.',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                    textAlign: TextAlign.center,
                  )),
            ),
            Center(
              child: Padding(
                  padding:
                      const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                  child: Text(
                    'This custom ROM  brands itself as a minimalist\'s ROM that provide a fluid experience, with enhancements, rather than features',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                    textAlign: TextAlign.center,
                  )),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 73.0),
                child: Text(
                  'Screenshots',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            CarouselImages(
              scaleFactor: 0.6,
              listImages: imgList,
              height: 700,
              borderRadius: 20,
              cachedNetworkImage: true,
            ),
            SizedBox(
              height: 200,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: Text(
                  'Download',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Container(
                  padding: const EdgeInsets.only(top: 10.0, bottom: 73),
                  child: ElevatedButton(
                      child: Text(
                        'Official Builds',
                      ),
                      onPressed: () async {
                        String url =
                            'https://paranoidandroid.co/';
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
                      })),
            ),
          ],
        ),
      ),
    );
  }
}
