import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

part 'cost_center_search_event.dart';
part 'cost_center_search_state.dart';

class CostCenterSearchBloc extends Bloc<CostCenterSearchEvent, CostCenterSearchState> {
  final Dio dio;
  CostCenterSearchBloc(this.dio) : super(SearchEmpty()) {
    on<SearchCostCenter>((event, emit) async {
      if (event.query.isEmpty) return emit(SearchEmpty());
      emit(SearchLoading());
      try {
        final res = await dio.get('/api/costcenters', queryParameters: {'q': event.query});
        emit(SearchLoaded(res.data['data']));
      } catch (e) {
        emit(SearchError(e.toString()));
      }
    });
  }
}