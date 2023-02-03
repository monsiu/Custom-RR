// ignore_for_file: prefer_const_constructors, deprecated_member_use, avoid_print
import 'package:carousel_images/carousel_images.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final List<String> imgList = [
  'https://pbs.twimg.com/media/Fdz5bl-UoAAPtj2?format=jpg&name=large',
  'https://pbs.twimg.com/media/FfCdMA1UoAEDg1Q?format=jpg&name=small',
  'https://pbs.twimg.com/media/Fdz5b5KUAAADNCn?format=jpg&name=large',
  'https://pbs.twimg.com/media/Fdz5cICVEAATQrj?format=jpg&name=large',
];

class BlissromPage extends StatelessWidget {
  const BlissromPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text('Bliss ROM')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(tag: 'img', child: Image.asset('images/blissrom.png')),
            Center(
                child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                'Bliss ROM OS',
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
                      'An Open Source OS, based on Android, that incorporates many optimizations, features, and expanded device support. And it is available for just about any Chromebook, Windows/Linux PC or tablet released in the last 4 years',
                      style:
                          TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
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
            )),
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
                            'https://downloads.blissroms.org/';
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
