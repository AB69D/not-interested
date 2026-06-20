import 'dart:typed_data';

abstract class ISkinDetectionService {
  /// Fast HSV-based skin detection. Returns true if skin % exceeds threshold.
  Future<bool> hasSkinContent(Uint8List frameBytes, int width, int height);

  /// Returns skin region bounds as [left, top, right, bottom] normalized 0.0–1.0
  Future<List<List<double>>> getSkinRegions(Uint8List frameBytes, int width, int height);
}
