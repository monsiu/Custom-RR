// ignore_for_file: prefer_const_constructors, deprecated_member_use, avoid_print
import 'package:carousel_images/carousel_images.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final List<String> imgList = [
  'https://i0.wp.com/theunlockr.com/wp-content/uploads/2019/08/Evolution-X-2.png?fit=720%2C1280&ssl=1'
  'https://telegra.ph/file/101024a64669e063aec67.png',
  'https://telegra.ph/file/c31f20504a03127993e5f.png',
  
];

class EvolutionxPage extends StatelessWidget {
  const EvolutionxPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Evolution X'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(tag: 'img', child: Image.asset('images/evolutionx.png')),
            Center(
                child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                'Evolution X',
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
                'Evolution X allows users to experience Google\'s latest Pixel updates while integrating useful features from known custom ROMs.',
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
