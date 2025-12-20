abstract class UserEvent {}

class FetchUserEvent extends UserEvent {
  final String uid;
  FetchUserEvent(this.uid);
}
