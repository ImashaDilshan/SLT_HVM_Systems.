abstract class AddItemSubmitState {}

class AddItemSubmitInitial extends AddItemSubmitState {}

class AddItemSubmitLoading extends AddItemSubmitState {}

class AddItemSubmitSuccess extends AddItemSubmitState {
  final String message;
  AddItemSubmitSuccess(this.message);
}

class AddItemSubmitFailure extends AddItemSubmitState {
  final String error;
  AddItemSubmitFailure(this.error);
}