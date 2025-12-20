import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';



class OverlayCubit extends Cubit<Map<String, dynamic>?> {
  OverlayCubit() : super(null);

  void show({Map<String, dynamic>? prefillData}) => emit(prefillData ?? {});
  void hide({VoidCallback? onClose}) {
    emit(null); 

  }

}
