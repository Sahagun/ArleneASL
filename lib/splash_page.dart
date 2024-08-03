import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'new_home_page.dart';
import 'tf_helper.dart';

class SplashPage extends StatefulWidget{
  const SplashPage({super.key});

  @override
  State createState() => _State();
}

class _State extends State<SplashPage>{
  static const modelPath = 'assets/Sign-Language-Recognition-App-using-Flutter-and-ML/model_unquant.tflite';
  static const labelsPath = 'assets/Sign-Language-Recognition-App-using-Flutter-and-ML/labels.txt';

  late List<CameraDescription>? cameras;
  late CameraController? controller;

  TfHelper tfHelper = TfHelper();


  Future<void> initTensorModel() async {
    await tfHelper.initHelper(modelPath, labelsPath);
  }

  Future<void> initCameras() async {
    cameras = await availableCameras();
  }


  Future<void> initModelAndCamera() async {
    await initTensorModel();
    await initCameras();
    await Future.delayed(Duration(seconds: 6));
  }



  @override
  Widget build(context){

    initModelAndCamera().then(
      (_){
        Navigator.pushReplacement(
          context,
            MaterialPageRoute(builder: (builder) => HomePage(cameras: cameras, tfHelper: tfHelper,))
            // MaterialPageRoute(builder: (builder) => HomePage(cameras: null, tfHelper: tfHelper,))
        );
      }
    );

    return Scaffold(

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text("SignSync"),
            Image.asset("assets/logo.png"),

          ],
        ),
      ),
    );
  }
}