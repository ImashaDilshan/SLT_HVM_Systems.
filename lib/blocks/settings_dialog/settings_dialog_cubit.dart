import 'package:flutter_bloc/flutter_bloc.dart';
import 'settings_dialog_state.dart';

class SettingsDialogCubit extends Cubit<SettingsDialogState> {
  SettingsDialogCubit() : super(SettingsDialogHidden());

  void show() => emit(SettingsDialogVisible());
  void hide() => emit(SettingsDialogHidden());
  void toggle() {
    if (state is SettingsDialogHidden) {
      emit(SettingsDialogVisible());
    } else {
      emit(SettingsDialogHidden());
    }
  }
}