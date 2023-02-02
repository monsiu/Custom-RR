// ignore_for_file: prefer_const_constructors, deprecated_member_use, avoid_print
import 'package:carousel_images/carousel_images.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final List<String> imgList = [
  'https://upload.wikimedia.org/wikipedia/commons/8/87/LineageOS_Screenshot_New.png',
  'https://telegra.ph/file/b5d7a590025db6932e19a.png',
  'https://forum.xda-developers.com/proxy.php?image=https%3A%2F%2Fi.imgur.com%2FGScx1xm.png&hash=561a424f74a808c5bf9ecf95f5a64f97',
  'https://upload.wikimedia.org/wikipedia/commons/3/33/LineageOS_16.0_home_screen.png',
  'https://images.fonearena.com/blog/wp-content/uploads/2021/05/POCO-F1-Android-11-FoneArena-LineageOS-18-UI-2.jpg',
];

class LineagePage extends StatelessWidget {
  const LineagePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Lineage OS'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(tag: 'img', child: Image.asset('images/lineageos.png')),
            Center(
                child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                'Lineage OS',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  decoration: TextDecoration.underline,
                ),
              ),
            )),
            SizedBox(
              height: 20.0,
            ),
            Center(child: Padding(
                  padding: const EdgeInsets.only(top:12.0, left: 15, right: 15),
              child: Text(
                'Lineage OS, Known commonly as the CyanogenMod successor due to the main team from that project moving on to make Lineage OS.',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                textAlign: TextAlign.center,
              ),),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'Lineage OS is the most commonly known Custom Rom for its stability and reliablility as an Custom Operating System. These two things are this custom rom\'s strong suite.',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
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
                        String url = 'https://wiki.lineageos.org/devices/';
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
