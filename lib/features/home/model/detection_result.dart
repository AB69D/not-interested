class DetectionResult {
  final double left;
  final double top;
  final double right;
  final double bottom;
  final double confidence;
  final String label;

  const DetectionResult({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.confidence,
    required this.label,
  });

  Map<String, double> toRegionMap() => {
    'left': left,
    'top': top,
    'right': right,
    'bottom': bottom,
  };
}
