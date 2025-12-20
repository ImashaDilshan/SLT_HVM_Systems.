import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slt_hire_log/blocks/SharedData/shared_data_state.dart';
import 'package:slt_hire_log/constants/app_colors.dart';
import 'package:slt_hire_log/models/user_model.dart';
import 'package:slt_hire_log/ui_compo/logo.dart';
import 'package:slt_hire_log/ui_compo/mode_select.dart';
import 'package:slt_hire_log/widgets/cost_center_cards.dart';
import 'package:slt_hire_log/widgets/month_box.dart';
import 'package:slt_hire_log/widgets/naviation_bar.dart';

class MonthlyReports extends StatefulWidget {
  final UserModel user;
  const MonthlyReports({super.key, required this.user});

  @override
  State<MonthlyReports> createState() => _MonthlyReportsState();
}

class _MonthlyReportsState extends State<MonthlyReports> {
  @override
  Widget build(BuildContext context) {
     final sharedData = context.read<SharedDataCubit>().state;
   
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            
                left: 0,
                top:200,
                child: Opacity(
                            opacity: 0.1, // 👈 Adjust the opacity here (0.0 - 1.0)
                            child: Container(
                width: 600,
                height: 700,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/btn_Logo.png'), // 👈 Your image path
                    fit: BoxFit.cover,
                  ),
                ),
                            ),
                          ),
              ),
          SingleChildScrollView(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 400,
                      height: 200,
                      child: Row(children: [Logo()]),
                    ),

                    Container(
                      constraints: const BoxConstraints(minHeight: 550),
                      height: MediaQuery.of(context).size.height - 200,
                      width: widget.user.role == "Moderetor" ? 300 : 425,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 30, bottom: 20),
                          child: Row(
                            children: [
                              NaviationBar(),
                              Container(
                                constraints: const BoxConstraints(
                                  minHeight: 500,
                                ),
                                height:
                                    MediaQuery.of(context).size.height - 200,
                                width: 245,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: SizedBox(
                                        width: 200,
                                        height: 200,
                                        child: MonthPickerContainer(),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 20),
                                      child: ModeSelect(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Stack(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width - 425,
                      constraints: const BoxConstraints(minHeight: 500),
                      height: MediaQuery.of(context).size.height,
                      child: Column(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width - 425,
                            height: MediaQuery.of(context).size.height,
                            constraints: const BoxConstraints(minHeight: 360),
                            child: Align(
                              alignment: Alignment.center,
                              child: Container(
                                width: MediaQuery.of(context).size.width - 475,
                                height:
                                    MediaQuery.of(context).size.height - 450,
                                constraints: const BoxConstraints(
                                  minHeight: 700,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  color: const Color.fromARGB(
                                    255,
                                    255,
                                    255,
                                    255,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromARGB(55, 0, 0, 0),
                                      spreadRadius: 6,
                                      blurRadius: 6,
                                      offset: Offset(0, 0),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 15),
                                  
                                  child: CostCenterCards(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 120,
                      left: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,

                          borderRadius: BorderRadius.all(
                            Radius.circular(100),
                          
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: "Refresh",
                          onPressed: () {
                            
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
