// ignore_for_file: prefer_const_constructors, deprecated_member_use, avoid_print
import 'package:carousel_images/carousel_images.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final List<String> imgList = [
  'https://www.droidontime.com/assets/images/about.webp',
  'https://blog.droidontime.com/_next/image?url=%2Fstatic%2Fimages%2FMonetWannabeTwoPoint.png&w=3840&q=75',
  'https://blog.droidontime.com/_next/image?url=%2Fstatic%2Fimages%2Fsettings_dashboard_fivetwo.png&w=3840&q=75',
  'https://blog.droidontime.com/_next/image?url=%2Fstatic%2Fimages%2Fgaming_fivetwo.png&w=3840&q=75',
  'https://blog.droidontime.com/_next/image?url=%2Fstatic%2Fimages%2Fwidgets_fivetwo.png&w=3840&q=75',
];

class DotosPage extends StatelessWidget {
  const DotosPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Dot OS'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(tag: 'img', child: Image.asset('images/dotos.png')),
            Center(
                child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text('Dot OS',
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
                      'DroidOnTime(DOT OS) is a custom Android firmware launched with an aim to provide Unique user interface and Optimum performance and it keeps in mind the balance between performance and battery life.',
                      style:
                          TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                      textAlign: TextAlign.center,
                    ))),
            Center(
                child: Padding(
              padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
              child: Text(
                'DotOS is based on Google\'s Android Open Source Project with Hand-picked goodies, innovative ideas and creative things that are added in the rom to enhance user experience!',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                textAlign: TextAlign.center,
              ),
            )),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
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
