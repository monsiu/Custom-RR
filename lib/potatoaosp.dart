// ignore_for_file: prefer_const_constructors, deprecated_member_use, avoid_print

import 'package:carousel_images/carousel_images.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final List<String> imgList = [
  'https://pbs.twimg.com/media/EMeVB9WUYAA_3g_?format=jpg&name=4096x4096',
  'https://i0.wp.com/theunlockr.com/wp-content/uploads/2020/07/Potato-Open-Sauce-Project.jpg?fit=1079%2C2158&ssl=1',
  'https://images.fonearena.com/blog/wp-content/uploads/2021/01/POCO-F1-Android-11-FoneArena-POSP-Fries-2.jpg',
  'https://pbs.twimg.com/media/EgLi5-9U8AckkMf?format=jpg&name=large',
  'https://pbs.twimg.com/media/EgLi6WIVAAgND_V?format=jpg&name=large',
];

class PotatoaospPage extends StatelessWidget {
  const PotatoaospPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Potato OSP'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(tag: 'img', child: Image.asset('images/potatoaosp.png')),
            Center(
                child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                'Potato OSP',
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
            Center( child: Padding(
                  padding: const EdgeInsets.only(top:12.0, left: 15, right: 15),
              child: Text(
                'Potato Open Sauce Project (POSP) defines itself as a buttery smooth aftermarket Android™ firmware. ',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                textAlign: TextAlign.center,
              ),
            )),
            Center( child: Padding(
                  padding: const EdgeInsets.only(top:12.0, left: 15, right: 15),
              child: Text(
                'Combining newest security patches, original features and wide device support, POSP is a product created to make your life easier and breathe some fresh air into the custom ROM scene.',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                textAlign: TextAlign.center,
             ) ),
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
                            'https://download.pixelexperience.org/devices';
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
                      })),
            ),
          ],
        ),
      ),
    );
  }
}
