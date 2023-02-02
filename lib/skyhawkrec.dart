// ignore_for_file: prefer_const_constructors, deprecated_member_use, avoid_print
import 'package:carousel_images/carousel_images.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

final List<String> imgList = [
  'https://skyhawkrecovery.github.io/img/screenshot/1.png',
  'https://skyhawkrecovery.github.io/img/screenshot/2.png',
  'https://skyhawkrecovery.github.io/img/screenshot/3.png',
  'https://skyhawkrecovery.github.io/img/screenshot/4.png',
  'https://skyhawkrecovery.github.io/img/screenshot/5.png',
  'https://skyhawkrecovery.github.io/img/screenshot/6.png',
  'https://skyhawkrecovery.github.io/img/screenshot/7.png',
  'https://skyhawkrecovery.github.io/img/screenshot/8.png',
  'https://skyhawkrecovery.github.io/img/screenshot/9.png',
  'https://skyhawkrecovery.github.io/img/screenshot/10.png',
  'https://skyhawkrecovery.github.io/img/screenshot/11.png',
  'https://skyhawkrecovery.github.io/img/screenshot/12.png',
];

class SkyhawkrecPage extends StatelessWidget {
  const SkyhawkrecPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Sky Hawk Recovery Project'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl:
                  "https://forum.xda-developers.com/proxy.php?image=https%3A%2F%2Fgithub.com%2FDNI9%2FSHRP_%2Fraw%2Fmaster%2Fimg%2Fshrp3_banner_xda.png&hash=64337414359ef1feb6f4de18c17c665b",
            ),
            Center(
                child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text('Sky Hawk Recovery Project',
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
            Center( child: Padding(
                    padding:
                        const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
              'SHRP is inspired by mordern design to bring the newest design to the native TWRP. SHRP provides much more along side of it\'s rich UI experience. New dashboard makes it very easy to interact with TWRP. SHRP got some cool features like Whole new theming section ,Flash Magisk (root or unroot), Camera2api enabler Directly from dashboard, Password protection etc. It\'s all started , lot more to come.',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
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
                  'Designed with latest Material design 2 guidelines',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'Password lock protection available to lock your TWRP :D',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'Modified file manager, added features like storage info drawer, zip etc.',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'All new Dashboard with more options added, Now quickly access from dashboard.',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'Inbuilt patches, like Magisk and password reset patch',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'SHRP has theming support to change theme to black, Dark or to Pure white.',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'Added some cool extra stuff to enhance the ultimate user experience.',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'Fully open-source',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                               padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),

                child: Text(
                  'Frequently updated',
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
                  padding: const EdgeInsets.only(top: 10.0, bottom: 73),
                  child: ElevatedButton(
                      child: Text(
                        'Official Builds',
                      ),
                      onPressed: () async {
                        String url = 'https://skyhawkrecovery.github.io/Devices.html';
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
