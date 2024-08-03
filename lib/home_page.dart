
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'tf_helper.dart';

class HomePage extends StatefulWidget {

  @override
  State createState() => HomePageState();

}

class HomePageState extends State<HomePage>{

  // static const modelPath = 'assets/classify/mobilenet_quant.tflite';
  // static const labelsPath = 'assets/classify/labels.txt';

  static const modelPath = 'assets/Sign-Language-Recognition-App-using-Flutter-and-ML/model_unquant.tflite';
  static const labelsPath = 'assets/Sign-Language-Recognition-App-using-Flutter-and-ML/labels.txt';


  static const modelDetectPath = 'assets/detection/custom_ssd_mobilenet_v2.tflite';
  static const labelsDetectPath = 'assets/detection/labels.txt';


  late List<CameraDescription> _cameras;
  late CameraController controller;

  TfHelper tfHelper = TfHelper();

  void initCamera() async{
    controller = CameraController(_cameras[0], ResolutionPreset.max);
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

  @override
  void initState() {
    super.initState();
    tfHelper.initHelper(modelPath, labelsPath);
    availableCameras().then(
      (cam) {
        _cameras = cam;
        initCamera();
      }
    );

  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }


  Widget cameraBody(){
    if (!controller.value.isInitialized) {
      return const Center(child: Text("Camera Not Initialized"));
    }
    return CameraPreview(controller);
  }


  void switchCamera(){
    controller = CameraController(_cameras[1], ResolutionPreset.max);
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
    await tfHelper.initHelper(modelDetectPath, labelsDetectPath);

    takePicture().then((XFile? file) {
      if (mounted) {
        setState(() {
          imageFile = file;

          tfHelper.detectObject(file!.path).then(
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
    await tfHelper.initHelper(modelPath, labelsPath);
    takePicture().then((XFile? file) {
      if (mounted) {
        setState(() {
          imageFile = file;

          tfHelper.classifyImage(file!.path).then(
                  (val){ print("Success classying"); }
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

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      final XFile file = await cameraController.takePicture();
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }



  @override
  Widget build(context){
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            cameraBody(),

            Text("${_cameras.length}"),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: onTakePictureClassifyButtonPressed, child: const Text("Classify")),
                ElevatedButton(onPressed: onTakePictureDetectObjectButtonPressed, child: const Text("Detection")),
              ],

            ),
            ElevatedButton(onPressed: switchCamera, child: const Text("Switch Camera"))
          ],
        ),
      ),
    );
  }
}