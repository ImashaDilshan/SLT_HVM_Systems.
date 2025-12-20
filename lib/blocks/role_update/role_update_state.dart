abstract class RoleUpdateState {}

class RoleUpdateInitial extends RoleUpdateState {}

class RoleUpdateLoading extends RoleUpdateState {}

class RoleUpdateSuccess extends RoleUpdateState {
  final String message;
  RoleUpdateSuccess(this.message);
}

class RoleUpdateFailure extends RoleUpdateState {
  final String error;
  RoleUpdateFailure(this.error);
}
