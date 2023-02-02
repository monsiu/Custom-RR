// ignore_for_file: prefer_const_constructors, deprecated_member_use
import 'package:carousel_images/carousel_images.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final List<String> imgList = [
  'https://www.notebookcheck.net/fileadmin/_processed_/d/5/csm_Android_11_on_Xiaomi_Mi_A1_crDroid_Home_30ad4bfde8.png',
  'https://imag.malavida.com/mvimgbig/download-fs/crdroid-34836-1.jpg',
  'https://crdroid.net/img/gallery/gallery-1.webp',
  'https://crdroid.net/img/gallery/gallery-2.webp',
  'https://crdroid.net/img/gallery/gallery-3.webp',
  'https://crdroid.net/img/gallery/gallery-4.webp',
  'https://crdroid.net/img/gallery/gallery-5.webp',
  'https://crdroid.net/img/gallery/gallery-6.webp',
  'https://crdroid.net/img/gallery/gallery-7.webp',
  'https://crdroid.net/img/gallery/gallery-8.webp',
  'https://crdroid.net/img/gallery/gallery-9.webp',
  
];

class CrdroidPage extends StatelessWidget {
  const CrdroidPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('crDroid'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(tag: 'img', child: Image.asset('images/crdroid hori.png')),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  'crDroid',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      decoration: TextDecoration.underline),
                ),
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            Center( child: Padding(
                  padding: const EdgeInsets.only(top:12.0, left: 15, right: 15),
                child: Text(
                  
              'crDroid, another well known Custom OS that is known for speed and functionality. ',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
              textAlign: TextAlign.center,
            ))),
            Center(
                child: Padding(
                  padding: const EdgeInsets.only(top:12.0, left: 15, right: 15),
              child: Text(
                'Also coming from the AOSP project, crDroid offers wide number of settings and cutomizations which are really impressive. It also offers unlimited google photos backups, which is a feature commonly found in Google Pixels. ',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w300),
                textAlign: TextAlign.center,
              ),
            )),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top:73.0),
                  child: Text(
'Screenshots',              style: TextStyle(fontSize: 32,fontWeight: FontWeight.bold),
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
                padding: const EdgeInsets.only(top:10.0, bottom:73),
                child: ElevatedButton(
          child:
              Text(
                'Official Builds',
              
              ),
          onPressed: () async {
              String  url = 'https://crdroid.net/downloads';
              if (await canLaunch(url)) {
                await launch(
                  url,
                  forceSafariVC: true,
                  forceWebView: true,
                  enableJavaScript: true,
                  enableDomStorage: true,
                  webOnlyWindowName: '_self',

                );
                }
              }
                
          )),
            ),
              
            
          ],
        ),
      ),
    );
  }
}
