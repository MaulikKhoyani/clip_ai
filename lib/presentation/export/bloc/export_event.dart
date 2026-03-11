import 'package:equatable/equatable.dart';

sealed class ExportEvent extends Equatable {
  const ExportEvent();
  @override
  List<Object?> get props => [];
}

class ExportInitializeRequested extends ExportEvent {
  const ExportInitializeRequested();
}

class ExportFormatChanged extends ExportEvent {
  final String format;
  const ExportFormatChanged(this.format);
  @override
  List<Object?> get props => [format];
}

class ExportResolutionChanged extends ExportEvent {
  final String resolution;
  const ExportResolutionChanged(this.resolution);
  @override
  List<Object?> get props => [resolution];
}

class ExportAiCaptionsToggled extends ExportEvent {
  final bool enabled;
  const ExportAiCaptionsToggled(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class ExportBgRemovalToggled extends ExportEvent {
  final bool enabled;
  const ExportBgRemovalToggled(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class ExportStarted extends ExportEvent {
  final String? projectId;
  final String? videoPath;

  const ExportStarted({this.projectId, this.videoPath});

  @override
  List<Object?> get props => [projectId, videoPath];
}
