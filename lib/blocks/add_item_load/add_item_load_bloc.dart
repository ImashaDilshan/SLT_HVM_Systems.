
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slt_hire_log/core/add_item_repository.dart';
import 'add_item_load_event.dart';
import 'add_item_load_state.dart';

class AddItemLoadBloc extends Bloc<AddItemLoadEvent, AddItemLoadState> {
  final AddItemRepository repository;

  AddItemLoadBloc(this.repository) : super(AddItemInitial()) {
    on<FetchAddItemData>(_onFetch);
  }

  Future<void> _onFetch(FetchAddItemData event, Emitter<AddItemLoadState> emit) async {
    emit(AddItemLoading());
    try {
      final data = await repository.fetchVehicleData(event.costCenter);
      emit(AddItemLoaded(
        refNos: data['refNos']!,
        gms: data['gms']!,
        dgms: data['dgms']!,
        districts: data['districts']!,
      ));
    } catch (e) {
      emit(AddItemError(e.toString()));
    }
  }
}
