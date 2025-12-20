import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:slt_hire_log/blocks/user/user_bloc.dart';
import 'package:slt_hire_log/blocks/user/user_event.dart';
import 'package:slt_hire_log/loging_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show shimmer while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmer();
        }

        final user = snapshot.data;
        
        // If already logged in, go to dashboard
        if (user != null) {
          print("got this ");
          context.read<UserBloc>().add(FetchUserEvent(user.uid));
        }
        
        // Otherwise show login page
        return const SLTLoginPage();
      },
    );
  }

  Widget _buildShimmer() {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F3FE),
      body: Center(
        child: Shimmer.fromColors(
          baseColor: const Color.fromARGB(255, 0, 106, 255),
          highlightColor: const Color.fromARGB(255, 4, 190, 128),
          child: Image.asset(
            'assets/SLTMobitel_Logo.png',
            width: 200,
            height: 120,
          ),
        ),
      ),
    );
  }
}