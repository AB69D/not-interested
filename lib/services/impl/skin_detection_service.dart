import 'dart:typed_data';
import '../../core/constants/app_constants.dart';
import '../abstract/i_skin_detection_service.dart';

class SkinDetectionService implements ISkinDetectionService {
  /// HSV skin tone ranges (H: 0–50, S: 0.23–0.68, V: 0.35–1.0)
  static const double _hMin = 0;
  static const double _hMax = 50;
  static const double _sMin = 0.23;
  static const double _sMax = 0.68;
  static const double _vMin = 0.35;

  @override
  Future<bool> hasSkinContent(Uint8List frameBytes, int width, int height) async {
    final regions = await getSkinRegions(frameBytes, width, height);
    return regions.isNotEmpty;
  }

  @override
  Future<List<List<double>>> getSkinRegions(Uint8List frameBytes, int width, int height) async {
    int skinPixels = 0;
    final total = width * height;

    // frameBytes expected as RGBA
    for (int i = 0; i < frameBytes.length - 3; i += 4) {
      final r = frameBytes[i] / 255.0;
      final g = frameBytes[i + 1] / 255.0;
      final b = frameBytes[i + 2] / 255.0;

      if (_isSkinPixel(r, g, b)) skinPixels++;
    }

    final ratio = skinPixels / total;
    if (ratio < AppConstants.skinDetectThreshold) return [];

    // Return full frame as region when skin detected (ML will refine)
    return [[0.0, 0.0, 1.0, 1.0]];
  }

  bool _isSkinPixel(double r, double g, double b) {
    final maxC = [r, g, b].reduce((a, b) => a > b ? a : b);
    final minC = [r, g, b].reduce((a, b) => a < b ? a : b);
    final delta = maxC - minC;

    if (maxC == 0 || delta == 0) return false;

    double h = 0;
    if (maxC == r) {
      h = 60 * (((g - b) / delta) % 6);
    } else if (maxC == g) {
      h = 60 * ((b - r) / delta + 2);
    } else {
      h = 60 * ((r - g) / delta + 4);
    }
    if (h < 0) h += 360;

    final s = delta / maxC;
    final v = maxC;

    return h >= _hMin && h <= _hMax && s >= _sMin && s <= _sMax && v >= _vMin;
  }
}
