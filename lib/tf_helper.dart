import 'dart:developer';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as image_lib;

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'image_utils.dart';

class TfHelper{
  static const modelPath = 'assets/classify/mobilenet_quant.tflite';
  static const labelsPath = 'assets/classify/labels.txt';

  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;

  List<int>? inputShape;
  List<int>? outputShape;

  List<String>? labels;

  Future<void> initHelper(String modelAssetPath, String labelAssetPath) async {
    print("init helpper, $modelAssetPath, $labelAssetPath");

    await _loadModel(modelAssetPath);
    await _loadLabels(labelAssetPath);
  }

  Future<void> _loadModel(String modelAssetPath) async {
    print("loading model");
    final options = InterpreterOptions();

    // Use XNNPACK Delegate
    // if (Platform.isAndroid) {
    // options.addDelegate(XNNPackDelegate());
    // }

    // Use GPU Delegate
    // doesn't work on emulator
    // if (Platform.isAndroid) {
    //   options.addDelegate(GpuDelegateV2());
    // }

    // Use Metal Delegate
    if (Platform.isIOS) {
    options.addDelegate(GpuDelegate());
    }

    try {
      print("_interpreter");
      _interpreter = await Interpreter.fromAsset(modelAssetPath, options: options);
      print("_isolateInterpreter");
      _isolateInterpreter = await IsolateInterpreter.create(address: _interpreter!.address);


      // Get tensor input shape [1, 224, 224, 3]
      Tensor inputTensor = _interpreter!.getInputTensors().first;
      // Get tensor output shape [1, 1001]
      Tensor outputTensor = _interpreter!.getOutputTensors().first;


      inputShape = inputTensor.shape;
      outputShape = outputTensor.shape;

      log("$inputShape - $outputShape");

      print('Model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  // Load labels from assets
  Future<void> _loadLabels(String labelAssetPath) async {
    print("load labels");

    final labelTxt = await rootBundle.loadString(labelAssetPath);
    labels = labelTxt.split('\n');
  }


  // resizeImage(CameraImage cameraImage){
  //   image_lib.Image? img = ImageUtils.convertCameraImage(cameraImage);
  //
  //   image_lib.Image imageInput = image_lib.copyResize(
  //     img!,
  //     width: inputShape![1],
  //     height: inputShape![2],
  //   );
  //
  //   // //
  //   // if (Platform.isAndroid && isolateModel.isCameraFrame()) {
  //   //   imageInput = image_lib.copyRotate(imageInput, angle: 90);
  //   // }
  //   if (Platform.isAndroid) {
  //     imageInput = image_lib.copyRotate(imageInput, angle: 90);
  //   }
  //
  //   return imageInput;
  // }

  Future<Map<String, double>?> classifyImage(String imagePath) async {
    log('classify image...');

    if (_isolateInterpreter == null) {
      log('Interpreter is not initialized');
      return null;
    }

    log('Interpreter is initialized');

    // Read image from file as bytes
    final Uint8List imageData = File(imagePath).readAsBytesSync();
    // Decoding image
    final image = image_lib.decodeImage(imageData);

    // Resize Image to fit tensor input
    final inputImg = image_lib.copyResize(
      image!,
      width: inputShape![1],
      height: inputShape![2],
    );

    // Creating matrix representation
    final imageMatrix = List.generate(
      inputImg.height,
          (y) => List.generate(
            inputImg.width,
            (x) {
          final pixel = inputImg.getPixel(x, y);
          return [pixel.r, pixel.g, pixel.b];
        },
      ),
    );


    final input = [imageMatrix];
    // final output = [List<int>.filled(outputShape![1], 0)];
    final output = [List<double>.filled(outputShape![1], 0)];

    // Preprocessing and prediction logic goes here
    log('Preprocessing and prediction logic goes here');
    await Future.delayed(const Duration(seconds: 1));
    await _isolateInterpreter!.run(input, output);

    final result = output.first;
    num maxScore = result.reduce((a, b) => a + b);
    // Set classification map {label: points}
    Map<String, double> classification = <String, double>{};
    for (var i = 0; i < result.length; i++) {
      if (result[i] != 0) {
        // Set label: points
        classification[labels![i]] =
            result[i].toDouble() / maxScore.toDouble();
      }
    }

    double max_value = 0.0;
    String asl_letter = '';

    classification.forEach((k,v){
      if( v > max_value) {
        max_value = v;
        asl_letter = k;
      }
    });


    log("classify output:  $classification");
    log("classify best guess:  $asl_letter with $max_value");

    var outputResult = {
      "classification": asl_letter,
      "confidence": max_value,
    };

    return classification;
  }

  Future<dynamic?> detectObject(String imagePath) async {
    log('detect object image...');

    if (_isolateInterpreter == null) {
      log('Interpreter is not initialized');
      return null;
    }

    // Read image from file as bytes
    final Uint8List imageData = File(imagePath).readAsBytesSync();
    // Decoding image
    final image = image_lib.decodeImage(imageData);

    // Resize Image to fit tensor input
    final inputImg = image_lib.copyResize(
      image!,
      width: inputShape![1],
      height: inputShape![2],
    );

    // Creating matrix representation
    final imageMatrix = List.generate(
      inputImg.height,
          (y) => List.generate(
        inputImg.width,
            (x) {
          final pixel = inputImg.getPixel(x, y);
          return [pixel.r as int , pixel.g  as int, pixel.b  as int];
        },
      ),
    );


    final input = [imageMatrix];
    // final input = imageMatrix;
    log("input image shape ${input.shape}");

    //    final output = [List<int>.filled(outputShape![1], 0)];
    log("output shape ${outputShape}");

    final output = {
      0: [List<num>.filled(outputShape![1], 0)],
      1: [List<List<num>>.filled(outputShape![1], List<num>.filled(4, 0))],
      2: [0.0],
      3: [List<num>.filled(outputShape![1], 0)]
    };

    // log("$output");
    // Preprocessing and prediction logic goes here
    log('1 sec delay');
    await Future.delayed(const Duration(seconds: 1));
    log('running For Multiple Inputs');
    log("input size ${input.shape}; ${input.length};}");
    await _isolateInterpreter!.runForMultipleInputs([input], output);
    // await _isolateInterpreter!.run(input, output);


    log("detect output: $output ${output}" );


    var resultOutputs = output.values.toList();

    // Process Tensors from the output
    final scoresTensor = resultOutputs[0].first as List<double>;
    final boxesTensor = resultOutputs[1].first as List<List<double>>;
    final classesTensor = resultOutputs[3].first as List<double>;

    log('Processing outputs...');
    log("scoresTensor: $scoresTensor");
    log("boxesTensor: $boxesTensor");
    log("classesTensor: $classesTensor");

    // Convert class indices to int
    final classes = classesTensor.map((value) => value.toInt()).toList();

    // Number of detections
    final numberOfDetections = resultOutputs[2].first as double;
    log("numberOfDetections: $numberOfDetections");


    // Get classifcation with label
    final List<String> classification = [];
    for (int i = 0; i < numberOfDetections; i++) {
      classification.add(labels![classes[i]]);
    }
    log("classification: $classification");

    return output;


  }

  void dispose() {
    _interpreter?.close();
  }

}