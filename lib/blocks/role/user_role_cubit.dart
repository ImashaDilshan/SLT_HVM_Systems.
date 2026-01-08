// lib/blocks/user_info/user_info_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:slt_hire_log/models/user_model.dart';

class UserInfoCubit extends Cubit<UserModel?> {
  UserInfoCubit() : super(null);

  void setUser(UserModel user) {
    emit(user);

  }

  void clearUser() {
    emit(null);
  }
}
