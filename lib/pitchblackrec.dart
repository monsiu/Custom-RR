// ignore_for_file: prefer_const_constructors, deprecated_member_use, avoid_print
import 'package:carousel_images/carousel_images.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

final List<String> imgList = [
  'https://forum.xda-developers.com/attachments/img_20200802_022925_994-jpg.5072355/',
  'https://forum.xda-developers.com/attachments/img_20200802_022931_937-jpg.5072359/',
  'https://pitchblackrecovery.com/wp-content/uploads/2020/07/Screenshot_PBRP_2020-07-26-01-31-15-576x1024.png',
  'https://pitchblackrecovery.com/wp-content/uploads/2020/07/Screenshot_PBRP_2020-07-26-01-31-15-576x1024.png',
  'https://pitchblackrecovery.com/wp-content/uploads/2020/07/Screenshot_PBRP_2020-07-26-01-31-02-1-576x1024.png',
  'https://pitchblackrecovery.com/wp-content/uploads/2020/07/Screenshot_PBRP_2020-07-26-01-31-07-576x1024.png',
];

class PitchblackrecPage extends StatelessWidget {
  const PitchblackrecPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Pitch Black Recovery'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl:
                  "https://techsphinx.com/wp-content/uploads/2020/09/PBRP.png",
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
            Center(
                child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text('Pitch Black Recovery Project',
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
              'Pitch Black Recovery is a fork of TWRP with many improvements to make your experience better. It\'s more flexible & easy to use.',
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
                  'PBRP provides 10+ tools that comes handly when playing with your device. This includes Magisk Manager, etc.',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'Supports wide range of devices with Treble, ARB Support, Force Encryption and much more.',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'Customize PBRP according to your needs using PBRP Theme Engine™',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'Best in class material design for the latest android addicts.',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'Always up-to-date with the latest TWRP 3.5.2 Sources with support for legacy devices.',
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
                  'PBRP provides official support for 10+ languages that are updated and improved regularly!',
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
                padding: const EdgeInsets.only(top: 60.0, bottom: 30),
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
                        String url = 'https://www.droidontime.com/devices';
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
