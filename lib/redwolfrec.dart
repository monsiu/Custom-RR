// ignore_for_file: prefer_const_constructors, deprecated_member_use, avoid_print
import 'package:carousel_images/carousel_images.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

final List<String> imgList = [
  'https://forum.xda-developers.com/attachments/screenshot_2018-09-23-13-57-32-png.4603055/',
  'https://forum.xda-developers.com/attachments/screenshot_2018-09-23-13-57-50-png.4603057/',
  'https://forum.xda-developers.com/attachments/screenshot_2018-09-23-13-57-38-png.4603067/',
  'https://forum.xda-developers.com/attachments/screenshot_2018-09-23-13-57-55-png.4603068/',
  'https://forum.xda-developers.com/attachments/screenshot_2018-09-23-13-57-57-png.4603069/',
  'https://forum.xda-developers.com/attachments/screenshot_2018-09-23-13-57-45-png.4603042/',
];

class RedwolfrecPage extends StatelessWidget {
  const RedwolfrecPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Red Wolf Recovery Project'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl:
                  "https://forum.xda-developers.com/proxy.php?image=https%3A%2F%2Fpreview.ibb.co%2FdEEWNk%2F1495640672222.png&hash=39f616ef3fe8296072c24e0f4585d3c9",
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
            Center(
                child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text('Red Wolf Recovery Project',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      decoration: TextDecoration.underline)),
            )),
            SizedBox(
              height: 20.0,
            ),
            Center(
                child: Padding(
                    padding:
                        const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                    child: Text(
                      'Red Wolf Recovery is custom recovery based on TWRP source code, however some things are working here slightly different then you might expected. The main objective of this project is to provide stable recovery with features which you have never seen before in a recovery and which have not been accepted for adding to the official source code of TWRP. This recovery is also first recovery on the world with password protection.​',
                      style:
                          TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                      textAlign: TextAlign.center,
                    ))),
            Center(
                child: Padding(
              padding: const EdgeInsets.only(top: 60.0),
              child: Text(
                'Features',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            )),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'Making TWRP better than ever with new themes, clean and modern design.',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'Always up-to-date',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'Easy and simple to use',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'MIUI OTA support',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'Password protection',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'Disable DM-Verity & Forced encryption',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'Backup all partitions',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 60.0,
                  bottom: 30,
                ),
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
              height: 600,
              cachedNetworkImage: true,
              borderRadius: 20,
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
padding: const EdgeInsets.only(top: 10.0, bottom: 73),                  child: ElevatedButton(
                      child: Text(
                        'Official Builds',
                      ),
                      onPressed: () async {
                        String url = 'https://redwolfrecovery.github.io/devices.html';
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
