import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:slt_hire_log/blocks/AdminCalcBloc/admin_calc_bloc_bloc.dart';
import 'package:slt_hire_log/blocks/CostCenterSearch/cost_center_search_bloc.dart';
import 'package:slt_hire_log/blocks/Dashboard/dashboard_bloc.dart';
import 'package:slt_hire_log/blocks/SharedData/shared_data_state.dart';
import 'package:slt_hire_log/blocks/add_item_load/add_item_load_bloc.dart';
import 'package:slt_hire_log/blocks/add_item_submit/add_item_submit_bloc.dart';
import 'package:slt_hire_log/blocks/map_district_cubit.dart';
import 'package:slt_hire_log/blocks/navigation/navigation_cubit.dart';
import 'package:slt_hire_log/blocks/overlay/overlay_cubit.dart';
import 'package:slt_hire_log/blocks/ratecard/ratecard_bloc.dart';
import 'package:slt_hire_log/blocks/remove/remove_bloc.dart';
import 'package:slt_hire_log/blocks/role/user_role_cubit.dart';
import 'package:slt_hire_log/blocks/role_update/role_update_bloc.dart';
// <-- Import your cubit
import 'package:slt_hire_log/blocks/user/user_bloc.dart';
import 'package:slt_hire_log/constants/app_colors.dart';
import 'package:slt_hire_log/core/add_item_repository.dart';
import 'package:slt_hire_log/core/add_item_submit_model.dart';
import 'package:slt_hire_log/core/api_service.dart';
import 'package:slt_hire_log/fetch_user.dart';
import 'package:toastification/toastification.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ToastificationWrapper(
      child: MyApp(), // or MaterialApp, if not separated
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => UserBloc()),
        BlocProvider(create: (_) => SharedDataCubit()),
        BlocProvider(create: (_) => DashboardBloc()),
        BlocProvider(create: (_) => OverlayCubit()),
        BlocProvider(create: (_) => NavigationCubit()),
        BlocProvider(create: (_) => MapDistrictCubit()),
        BlocProvider(create: (_) => CostCenterSearchBloc(Dio(BaseOptions(baseUrl: 'http://localhost:3000')))),
        BlocProvider(create: (_) => AddItemLoadBloc(AddItemRepository(Dio()))),
        BlocProvider<AdminCalcBloc>(
          create: (_) => AdminCalcBloc(),),
        BlocProvider(
          create: (_) => AddItemSubmitBloc(AddItemSubmitRepository(Dio())),
        ),
        BlocProvider(create: (_) => UserInfoCubit()),
        BlocProvider(create: (_) => RemoveBloc(dio: Dio())),
        BlocProvider(create: (_) => RoleUpdateBloc(Dio())),
         BlocProvider(create: (_) => RateCardBloc(apiService: ApiService())),
        // <-- Add this line
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.scaffoldBackgroundColor,
        ),
        themeMode: ThemeMode.system,
        home: FetchUser(),
      ),
    );
  }
}
