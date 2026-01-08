abstract class AddItemLoadEvent {}

class FetchAddItemData extends AddItemLoadEvent {
  final int costCenter;
  FetchAddItemData(this.costCenter);
}