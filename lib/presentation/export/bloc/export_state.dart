import 'package:equatable/equatable.dart';

sealed class ExportState extends Equatable {
  const ExportState();
  @override
  List<Object?> get props => [];
}

class ExportInitial extends ExportState {}

class ExportReady extends ExportState {
  final String selectedFormat;
  final String selectedResolution;
  final bool aiCaptionsEnabled;
  final bool bgRemovalEnabled;
  final bool isPro;

  const ExportReady({
    required this.selectedFormat,
    required this.selectedResolution,
    required this.aiCaptionsEnabled,
    required this.bgRemovalEnabled,
    required this.isPro,
  });

  ExportReady copyWith({
    String? selectedFormat,
    String? selectedResolution,
    bool? aiCaptionsEnabled,
    bool? bgRemovalEnabled,
    bool? isPro,
  }) {
    return ExportReady(
      selectedFormat: selectedFormat ?? this.selectedFormat,
      selectedResolution: selectedResolution ?? this.selectedResolution,
      aiCaptionsEnabled: aiCaptionsEnabled ?? this.aiCaptionsEnabled,
      bgRemovalEnabled: bgRemovalEnabled ?? this.bgRemovalEnabled,
      isPro: isPro ?? this.isPro,
    );
  }

  @override
  List<Object?> get props => [
        selectedFormat,
        selectedResolution,
        aiCaptionsEnabled,
        bgRemovalEnabled,
        isPro,
      ];
}

class ExportInProgress extends ExportState {
  final double progress;
  const ExportInProgress({this.progress = 0.0});
  @override
  List<Object?> get props => [progress];
}

class ExportSuccess extends ExportState {
  final String? savedPath;
  const ExportSuccess({this.savedPath});
  @override
  List<Object?> get props => [savedPath];
}

class ExportFailure extends ExportState {
  final String message;
  const ExportFailure(this.message);
  @override
  List<Object?> get props => [message];
}
