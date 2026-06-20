import 'dart:typed_data';
import '../../features/home/model/detection_result.dart';

abstract class IMLService {
  bool get isLoaded;

  Future<void> loadModel();
  Future<List<DetectionResult>> detect(Uint8List frameBytes, int width, int height);
  void dispose();
}
