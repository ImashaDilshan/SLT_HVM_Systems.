abstract class SubmissionStatusEvent {}

class CheckSubmissionStatus extends SubmissionStatusEvent {
  final int costCenterId;
  final String month;
  final String mode;

  CheckSubmissionStatus({
    required this.costCenterId,
    required this.month,
    required this.mode,
  });
}
