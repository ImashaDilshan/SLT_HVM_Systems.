

import 'package:flutter_bloc/flutter_bloc.dart';

class MapDistrictCubit extends Cubit<String?> {
  MapDistrictCubit() : super(null);

  void selectDistrict(String name) => emit(name);
}