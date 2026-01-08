


import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slt_hire_log/blocks/user/user_event.dart';
import 'package:slt_hire_log/blocks/user/user_state.dart';
import 'package:slt_hire_log/core/user_network.dart';
import 'package:slt_hire_log/models/user_model.dart';


class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc() : super(UserInitial()) {
    on<FetchUserEvent>(_onFetchUser);
  }

  void _onFetchUser(FetchUserEvent event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      final response = await UserNetwork.instance.get('/user/${event.uid}');
      final user = UserModel.fromJson(response.data);

     

      emit(UserLoaded(user));
    } catch (e) {
      emit(UserError('Failed to fetch user: $e'));
    }
  }
}
