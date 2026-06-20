enum ServiceStatus { stopped, starting, running, error }

class HomeState {
  final ServiceStatus status;
  final double sensitivity;
  final String? errorMessage;
  final int detectionCount;
  final bool isModelLoading;

  const HomeState({
    this.status = ServiceStatus.stopped,
    this.sensitivity = 0.6,
    this.errorMessage,
    this.detectionCount = 0,
    this.isModelLoading = false,
  });

  HomeState copyWith({
    ServiceStatus? status,
    double? sensitivity,
    String? errorMessage,
    bool clearError = false,
    int? detectionCount,
    bool? isModelLoading,
  }) {
    return HomeState(
      status: status ?? this.status,
      sensitivity: sensitivity ?? this.sensitivity,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      detectionCount: detectionCount ?? this.detectionCount,
      isModelLoading: isModelLoading ?? this.isModelLoading,
    );
  }
}
