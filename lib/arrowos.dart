// ignore_for_file: prefer_const_constructors, deprecated_member_use, avoid_print

import 'package:carousel_images/carousel_images.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final List<String> imgList = [
  'https://arrowos.net/img/screen1.png',
  'https://arrowos.net/img/screen2.png',
  'https://arrowos.net/img/screen3.png',
  'https://arrowos.net/img/screen4.png',
  'https://arrowos.net/img/screen5.png',
  'https://arrowos.net/img/screen6.png',
  'https://arrowos.net/img/screen7.png',
  'https://arrowos.net/img/screen8.png',
];

class ArrowosPage extends StatelessWidget {
  const ArrowosPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text('Arrow OS')),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Hero(tag: 'img', child: Image.asset('images/arrowos.png')),
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Center(
                child: Text(
              'Arrow OS',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  decoration: TextDecoration.underline),
            )),
          ),
          SizedBox(
            height: 20.0,
          ),
          Center(
              child: Padding(
                  padding:
                      const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                  child: Text(
                    'Arrow OS, An AOSP project that takes pride in being a project started with the goal of keeping things simple, clean, and organized while adding features that will be helpful in the long run all while aiming to deliver smooth performance and longer battery life.',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                    textAlign: TextAlign.center,
                  ))),
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
                      String url = 'https://arrowos.net/download';
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
        ]),
      ),
    );
  }
}
