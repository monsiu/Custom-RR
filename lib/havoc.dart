// ignore_for_file: prefer_const_constructors, deprecated_member_use, avoid_print
import 'package:carousel_images/carousel_images.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final List<String> imgList = [
  'https://havoc-os.com/src/img/screenshots/Screenshot_1.png',
  'https://havoc-os.com/src/img/screenshots/Screenshot_2.png',
  'https://havoc-os.com/src/img/screenshots/Screenshot_3.png',
  'https://havoc-os.com/src/img/screenshots/Screenshot_4.png',
  'https://havoc-os.com/src/img/screenshots/Screenshot_5.png',
  'https://havoc-os.com/src/img/screenshots/Screenshot_6.png',
  'https://havoc-os.com/src/img/screenshots/Screenshot_7.png',
  'https://havoc-os.com/src/img/screenshots/Screenshot_8.png',
  'https://havoc-os.com/src/img/screenshots/Screenshot_10.png',
];

class HavocPage extends StatelessWidget {
  const HavocPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Havoc OS'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(tag: 'img', child: Image.asset('images/havoc.png')),
            Center(
                child: Padding(
              padding: const EdgeInsets.only(
                top: 12.0,
              ),
              child: Text(
                'HAVOC OS',
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
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  ' Havoc-OS is an after-market firmware based on Android Open Source Project, inspired by Google Pixel with a refined Material Design UI.',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
                child: Padding(
              padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
              child: Text(
                'They offer a smooth and stable experience for your device with a selected set of amazing features that provide an exceptional user experience. ',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                textAlign: TextAlign.center,
              ),
            )),
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
                        String url = 'https://havoc-os.com/download';
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
