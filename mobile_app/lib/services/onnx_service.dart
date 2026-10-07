import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:path_provider/path_provider.dart';
import '../models/prediction_result.dart';

class OnnxService {
  static final OnnxService _instance = OnnxService._internal();
  factory OnnxService() => _instance;
  OnnxService._internal();

  OrtSession? _session;
  bool _isInitialized = false;

  final List<String> _customBlocklist = ['mahabk', 'mahabank'];
  List<String> get customBlocklist => List.unmodifiable(_customBlocklist);

  void addBlockedKeyword(String keyword) {
    final clean = keyword.trim().toLowerCase();
    if (clean.isNotEmpty && !_customBlocklist.contains(clean)) {
      _customBlocklist.add(clean);
    }
  }

  void removeBlockedKeyword(String keyword) {
    _customBlocklist.remove(keyword.trim().toLowerCase());
  }

  bool get isInitialized => _isInitialized;

  /// Initialize ONNX Runtime engine & load model from Flutter assets
  Future<bool> initModel() async {
    if (_isInitialized) return true;
    if (kIsWeb) {
      _isInitialized = true;
      return true;
    }

    try {
      OrtEnv.instance.init();

      final byteData =
          await rootBundle.load('assets/models/sms_spam_pipeline.onnx');
      final bytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final modelFile = File('${tempDir.path}/sms_spam_pipeline.onnx');
      await modelFile.writeAsBytes(bytes, flush: true);

      final sessionOptions = OrtSessionOptions();
      _session = OrtSession.fromFile(modelFile, sessionOptions);
      _isInitialized = true;
      if (kDebugMode) {
        print('ONNX Engine initialized successfully!');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('ONNX Native Initialization error: $e');
      }
      _isInitialized = false;
      return false;
    }
  }

  /// Run local prediction checking Blocked Rules (MAHABK) first, then ONNX Model
  Future<PredictionResult> predict(String message, {String sender = ''}) async {
    final keywords = PredictionResult.extractKeywords(message);

    // 1. Rule Engine: Check MAHABK & custom blocklist
    final isBlocked = PredictionResult.checkBlockedKeywords(
      message,
      sender,
      _customBlocklist,
    );

    if (isBlocked) {
      final matchedTerm = _customBlocklist.firstWhere(
        (term) =>
            sender.toLowerCase().contains(term) ||
            message.toLowerCase().contains(term),
        orElse: () => 'MAHABK',
      );

      return PredictionResult(
        message: message,
        prediction: 'spam',
        spamProbability: 1.0,
        hamProbability: 0.0,
        suspiciousKeywords: keywords,
        isBlockedRule: true,
        blockedRuleReason: 'Blocked Sender Rule: "$matchedTerm"',
      );
    }

    // 2. Web or fallback heuristic
    if (kIsWeb || !_isInitialized || _session == null) {
      final success = await initModel();
      if (!success || kIsWeb || _session == null) {
        final isSpam = keywords.length >= 2 ||
            keywords.contains('http://') ||
            keywords.contains('https://') ||
            keywords.contains('www.');

        final double spamProb = isSpam ? 0.94 : 0.06;
        return PredictionResult(
          message: message,
          prediction: isSpam ? 'spam' : 'ham',
          spamProbability: spamProb,
          hamProbability: 1.0 - spamProb,
          suspiciousKeywords: keywords,
          isOfflineFallback: true,
        );
      }
    }

    // 3. ONNX Model Inference
    try {
      final runOptions = OrtRunOptions();
      final inputShape = [1, 1];
      final inputTensor = OrtValueTensor.createTensorWithDataList(
        [message],
        inputShape,
      );

      final inputs = {'input_text': inputTensor};
      final outputs = _session!.run(runOptions, inputs);

      final labelOutput = outputs[0]?.value;
      int label = 0;

      if (labelOutput is List && labelOutput.isNotEmpty) {
        if (labelOutput[0] is List) {
          label = (labelOutput[0][0] as num).toInt();
        } else {
          label = (labelOutput[0] as num).toInt();
        }
      }

      inputTensor.release();
      runOptions.release();
      for (var element in outputs) {
        element?.release();
      }

      final isSpam = label == 1;
      final double spamProb = isSpam ? 0.99 : 0.01;

      return PredictionResult(
        message: message,
        prediction: isSpam ? 'spam' : 'ham',
        spamProbability: spamProb,
        hamProbability: 1.0 - spamProb,
        suspiciousKeywords: keywords,
        isOfflineFallback: false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error during ONNX execution: $e');
      }
      final isSpam = keywords.length >= 2;
      return PredictionResult(
        message: message,
        prediction: isSpam ? 'spam' : 'ham',
        spamProbability: isSpam ? 0.90 : 0.10,
        hamProbability: isSpam ? 0.10 : 0.90,
        suspiciousKeywords: keywords,
        isOfflineFallback: true,
      );
    }
  }

  void release() {
    _session?.release();
    OrtEnv.instance.release();
    _isInitialized = false;
  }
}
