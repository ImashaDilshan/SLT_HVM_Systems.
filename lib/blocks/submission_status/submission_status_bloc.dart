abstract class SubmissionStatusState {}

class SubmissionStatusInitial extends SubmissionStatusState {}

class SubmissionStatusLoading extends SubmissionStatusState {}

class SubmissionStatusLoaded extends SubmissionStatusState {
  final String? role; // Change from bool to String?
  
  SubmissionStatusLoaded(this.role);
}

class SubmissionStatusError extends SubmissionStatusState {
  final String message;
  SubmissionStatusError(this.message);
}