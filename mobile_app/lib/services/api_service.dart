import '../models/prediction_result.dart';
import 'onnx_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // 100% On-Device ONNX Prediction
  Future<PredictionResult> predictSMS(String message) async {
    return await OnnxService().predict(message);
  }
}
