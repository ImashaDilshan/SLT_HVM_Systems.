import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slt_hire_log/blocks/SharedData/shared_data_state.dart';
import 'package:slt_hire_log/screens/add_user_page.dart';
import 'package:slt_hire_log/ui_compo/logo.dart';
import 'package:slt_hire_log/widgets/naviation_bar.dart';

class Userauthpage extends StatefulWidget {

  const Userauthpage({super.key});

  @override
  State<Userauthpage> createState() => _UserauthpageState();
}

class _UserauthpageState extends State<Userauthpage> {
  @override
  Widget build(BuildContext context) {
    final sharedData = context.read<SharedDataCubit>().state;
   
    return Scaffold(
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
                      width: 300,
                      height: 200,
                      child: Row(children: [Logo()]),
                    ),

                    Container(
                      constraints: const BoxConstraints(minHeight: 550),
                      height: MediaQuery.of(context).size.height - 200,
                      width:  225,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 30, bottom: 20),
                          child: Row(
                            children: [
                              NaviationBar(),
                              
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Stack(
                  children: [
                    Column(
                      children: [
                        SizedBox(height: 50,),
                        Container(
                          width: MediaQuery.of(context).size.width - 325,
                          constraints: const BoxConstraints(minHeight: 850),
                          height: MediaQuery.of(context).size.height-200,
                          child: AddUserPage()
                        ),
                      ],
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
