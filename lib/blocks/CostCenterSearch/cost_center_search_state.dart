part of 'cost_center_search_bloc.dart';

@immutable
abstract class CostCenterSearchState {}

class SearchEmpty extends CostCenterSearchState {}
class SearchLoading extends CostCenterSearchState {}
class SearchLoaded extends CostCenterSearchState {
  final List data;
  SearchLoaded(this.data);
}
class SearchError extends CostCenterSearchState {
  final String error;
  SearchError(this.error);}