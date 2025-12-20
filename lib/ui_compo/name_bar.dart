import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:slt_hire_log/auth_gate.dart';
import 'package:slt_hire_log/constants/app_colors.dart';
import 'package:slt_hire_log/constants/app_styles.dart';

class NameBar extends StatelessWidget {
  final String name;
  final String position;
  final String role;
  const NameBar({super.key, required this.name, required this.position, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 200,
      alignment: Alignment.center,
      child: Row(
        children: [
          Icon(CupertinoIcons.person, size: 50, color: AppColors.primary),
          Container(
            alignment: Alignment.centerLeft,
            height: 200,
            width: 300,
            padding: const EdgeInsets.only(left: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  name,
                  style: AppStyles.subheading,
                ),
                Text(
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  position,
                  style: AppStyles.normal,
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0, left: 10),
                      child: Container(
                        width: 80,
                        height: 25,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.role,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(role, style: AppStyles.role),
                      ),
                    ),
                    SizedBox(width: 10,),
                    Container(
                  child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 0, 43, 185), // Dark blue
        foregroundColor: const Color.fromARGB(221, 255, 17, 0), // Red text
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Rounded corners
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      ),
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AuthGate()),
          );
        });}
      },
      child: const Text('Logout'),
    ),
                )
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
