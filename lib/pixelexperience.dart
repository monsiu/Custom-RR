// ignore_for_file: prefer_const_constructors, deprecated_member_use, avoid_print

import 'package:carousel_images/carousel_images.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final List<String> imgList = [
  'https://static.c.realme.com/IN/wm-thread/1485160028611551232.png',
  'https://forum.fairphone.com/uploads/default/original/3X/4/c/4c255078503a1b60884172eaa39ad43a7af22bd8.jpeg',
  'https://i.redd.it/o81r265axjq21.png',
  'https://progsoft.net/images/pixel-experience-57995a9ddc10c69b97d33b89d2b777ccb4ce6ae9.jpg',
  'https://images.fonearena.com/blog/wp-content/uploads/2020/12/POCO-F1-Android-11-FoneArena-Pixel-Experience-Settings-1.jpg',
];

class PixelexperiencePage extends StatelessWidget {
  const PixelexperiencePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Pixel Experience'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(tag: 'img', child: Image.asset('images/pixelexperience.png')),
            Center(
                child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                'Pixel Experience OS',
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
                  'PixelExperience is an AOSP based ROM, with Google apps (gapps) included and all Pixel goodies (its in the name).   ',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
                child: Padding(
                    padding:
                        const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                    child: Text(
                      'Get Pixel features including launcher, wallpapers, icons, fonts, bootanimation and more in the form of a Custom Operating System. Truly a fan favourite for those looking for a Pixel Experience in a non-Pixel Device . ',
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
