abstract class AddItemLoadState {}

class AddItemInitial extends AddItemLoadState {}

class AddItemLoading extends AddItemLoadState {}

class AddItemLoaded extends AddItemLoadState {
  final List<String> refNos;
  final List<String> gms;
  final List<String> dgms;
  final List<String> districts;

  AddItemLoaded({
    required this.refNos,
    required this.gms,
    required this.dgms,
    required this.districts,
  });
}

class AddItemError extends AddItemLoadState {
  final String message;
  AddItemError(this.message);
}