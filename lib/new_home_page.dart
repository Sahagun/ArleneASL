import 'dart:io';

import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'splash_page.dart';
import 'tf_helper.dart';

class HomePage extends StatefulWidget {

  final List<CameraDescription>? cameras;
  final TfHelper? tfHelper;

  const HomePage({super.key, required this.cameras, required this.tfHelper});

  @override
  HomePageState createState() => HomePageState();

}

class HomePageState extends State<HomePage>{
  late CameraController controller;
  int currentCamera = 0;

  String prediction = "N\\A";
  num confidence = 0;

  bool processing = false;

  @override
  void initState() {
    super.initState();
    controller = CameraController(widget.cameras!.first, ResolutionPreset.max);
    controller.initialize().then((_){
      setState(() { });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  num formatConfidence(num confidence){
    return confidence * 10 % 10;
  }

  Widget cameraBody(){
    if (!controller.value.isInitialized) {
      return const Center(child: Text("Camera Not Initialized"));
    }
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(24.0)),
        child: CameraPreview(controller)

        // child: Container(
        //   width: MediaQuery.of(context).size.width,
        //   // height: 350, // 5.5 iphone
        //   height: 700, // iPad
        //   // height: 350, // 6 iphone
        //   child: FittedBox(
        //     child: Image.asset(
        //       "assets/asl_a.jpg",
        //     ),
        //     fit: BoxFit.cover,
        //   ),
        // )


      ),
    );
  }


  void switchCamera(){
    currentCamera++;
    if (currentCamera >= widget.cameras!.length){
      currentCamera = 0;
    }
    controller = CameraController(widget.cameras![currentCamera], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        print(e);
        switch (e.code) {
          case 'CameraAccessDenied':
          // Handle access errors here.
            break;
          default:
          // Handle other errors here.
            break;
        }
      }
    });
  }


  XFile? imageFile;

  void onTakePictureDetectObjectButtonPressed() async {
    takePicture().then((XFile? file) {
      if (mounted) {
        setState(() {
          imageFile = file;

          widget.tfHelper!.detectObject(file!.path).then(
            (val){print("Success Object Detect");}
          );
          // videoController?.dispose();
          // videoController = null;
        });
        if (file != null) {
          showInSnackBar('Picture saved to ${file.path}');
        }
      }
    });
  }

  void onTakePictureClassifyButtonPressed() async {
    if(processing){
      return;
    }
    setState(() {
      processing = true;
    });
    takePicture().then((XFile? file) {
      if (mounted) {
        setState(() {
          imageFile = file;

          widget.tfHelper!.classifyImage(file!.path).then(
            (classification){
              if(classification == null){
                prediction = "N\\A";
                confidence = 0;
              }
              else{
                confidence = 0;
                classification.forEach((k,v){
                  if( v > confidence) {
                    confidence = v;
                    prediction = k;
                  }
                });

                confidence = confidence * 100;
                confidence = confidence.round();

                showInSnackBar('Done Detecting ASL');

                print("Success classying");
              }

              setState(() {
                processing = false;
              });

            }
          );
        });
        if (file != null) {
          showInSnackBar('Detecting ASL');
        }
      }
    });
  }

  Future<XFile?> takePicture() async {
    if (!controller.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }

    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      final XFile file = await controller.takePicture();
      return file;
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  void _showCameraException(CameraException e) {
    _logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }


  void _logError(String code, String? message) {
    // ignore: avoid_print
    print('Error: $code${message == null ? '' : '\nError Message: $message'}');
  }

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }


  void reset(){
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (builder) => const SplashPage())
    );

  }

  @override
  Widget build(context){
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          children: [
            cameraBody(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        "Prediction",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        // prediction,
                        "A",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),

                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        "Confidence",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        // "$confidence %",
                        "94 %",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            
            Expanded(child: Container()),


            Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilledButton(
                      onPressed: processing ? null : onTakePictureClassifyButtonPressed,
                      child: const Text("Detect")
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: IconButton(
                        onPressed: switchCamera,
                        icon: const  Icon(Icons.cameraswitch, size: 25,),
                        color: Colors.white,
                    ),

                  ),

                ],
              ),
            ),

            // ElevatedButton(onPressed: reset, child: const Text("Reset"))
          ],
        ),
      ),
    );
  }
}