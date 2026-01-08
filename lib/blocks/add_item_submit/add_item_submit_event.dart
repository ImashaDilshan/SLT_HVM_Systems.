abstract class AddItemSubmitEvent {}

class SubmitAddItem extends AddItemSubmitEvent {
  final Map<String, dynamic> formData;
  SubmitAddItem(this.formData);
}