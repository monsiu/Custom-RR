// ignore_for_file: prefer_const_constructors, deprecated_member_use, avoid_print
import 'package:carousel_images/carousel_images.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

final List<String> imgList = [
  'https://cyber4geeks.com/wp-content/uploads/2019/03/dolby-atmos-zip-file-free-download-576x1024.jpg',
  'https://upload.wikimedia.org/wikipedia/commons/c/c9/TWRP_3.6.2_custom_ROM_and_recovery_flashing_log_screenshot.png',
  'https://4.bp.blogspot.com/-SmWKDBJI_3A/WFl63FOC6FI/AAAAAAAAC_A/_re4joDBIXM6kTHS_wsJr0B9pq6_q61OwCLcB/s1600/Screenshot_2016-12-20-12-25-00.png',
  'https://2.bp.blogspot.com/-jZHMBhc1SuU/WFl63K3eEGI/AAAAAAAAC_I/PfTMLh5OJ5sdnfCydETHqd1SEL_5KiumgCLcB/s1600/Screenshot_2016-12-20-12-06-57.png',
];

class TwrpPage extends StatelessWidget {
  const TwrpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('TWRP'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl:
                  "https://i0.wp.com/www.androidsage.com/wp-content/uploads/2021/01/TWRP-recovery.jpg",
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
            Center(
                child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text('Team Win Recovery Project',
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
            Center(  child: Padding(
                    padding:
                        const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
              'Team Win Recovery Project, pronounced "twerp", is an open-source software custom recovery image for Android-based devices. It provides a touchscreen-enabled interface that allows users to install third-party firmware and back up the current system which are functions often unsupported by stock recovery images.',
                              style: TextStyle(fontSize: 23),

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
                  'Backups of partitions in TAR or raw Image format',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'Restore backups from internal storage, external SD storage or OTG devices',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'Custom Firmware installation',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'Partition wiping',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'File deletion',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'Terminal access',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'ADB Root Shell',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'Theme Support',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'Possible decryption support depending on device',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 15, right: 15),
                child: Text(
                  'Wide range of devices are supported.',
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
