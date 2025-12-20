 part of 'cost_center_search_bloc.dart';

@immutable
abstract class CostCenterSearchEvent {}

class SearchCostCenter extends CostCenterSearchEvent {
  final String query;
  SearchCostCenter(this.query);
}