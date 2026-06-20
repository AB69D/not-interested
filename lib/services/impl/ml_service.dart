import 'dart:typed_data';
import '../abstract/i_ml_service.dart';
import '../../features/home/model/detection_result.dart';

// ML inference is handled entirely in Kotlin via ONNX Runtime (NotInterestedService.kt).
// This stub satisfies the interface but is not registered in DI or used at runtime.
class MLService implements IMLService {
  @override
  bool get isLoaded => false;

  @override
  Future<void> loadModel() async {}

  @override
  Future<List<DetectionResult>> detect(Uint8List frameBytes, int width, int height) async => [];

  @override
  void dispose() {}
}
