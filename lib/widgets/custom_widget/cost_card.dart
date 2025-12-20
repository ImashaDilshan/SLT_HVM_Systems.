import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slt_hire_log/blocks/submission_status/submission_status_bloc.dart';
import 'package:slt_hire_log/blocks/submission_status/submission_status_event.dart';
import 'package:slt_hire_log/blocks/submission_status/submission_status_state.dart';

class CostCenterCard extends StatelessWidget {
  final int costCenterId;
  final String name;
  final String month;
  final String mode;

  CostCenterCard({
    required this.costCenterId,
    required this.name,
    required this.month,
    required this.mode,
  }) : super(key: ValueKey('$costCenterId-$month-$mode'));

  // CORRECTED: Gray default, Red only for "Remove"
  Color _getCardColor(String? role) {
    if (role == null) return Colors.grey.shade100; // No record = Gray
    switch (role) {
      case 'Remove':
        return Colors.red.shade50;
      case 'level01':
        return Colors.yellow.shade50;
      case 'level02':
        return Colors.green.shade50;
      default:
        return Colors.grey.shade100; // Other roles = Gray
    }
  }

  Color _getBorderColor(String? role) {
    if (role == null) return Colors.grey.shade300;
    switch (role) {
      case 'Remove':
        return Colors.red.shade400;
      case 'level01':
        return Colors.yellow.shade400;
      case 'level02':
        return Colors.green.shade400;
      default:
        return Colors.grey.shade300;
    }
  }

  Color _getIconColor(String? role) {
    if (role == null) return Colors.grey.shade400;
    switch (role) {
      case 'Remove':
        return Colors.red.shade400;
      case 'level01':
        return Colors.yellow.shade400;
      case 'level02':
        return Colors.green.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  IconData _getIcon(String? role) {
    if (role == null) return Icons.hourglass_empty; // Gray default icon
    switch (role) {
      case 'Remove':
        return Icons.delete_forever; // Red delete icon
      case 'level01':
        return Icons.warning_amber_rounded; // Yellow warning
      case 'level02':
        return Icons.check_circle; // Green check
      default:
        return Icons.help_outline; // Gray question
    }
  }

  String _getStatusText(String? role) {
    if (role == null) return 'Not Submitted';
    switch (role) {
      case 'Remove':
        return 'Marked for Removal';
      case 'level01':
        return 'Level 01 - Pending';
      case 'level02':
        return 'Level 02 - Approved';
      default:
        return 'Role: $role';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SubmissionStatusBloc(
        Dio(BaseOptions(baseUrl: 'http://localhost:3000')),
      )..add(CheckSubmissionStatus(
          costCenterId: costCenterId,
          month: month,
          mode: mode,
        )),
      child: BlocBuilder<SubmissionStatusBloc, SubmissionStatusState>(
        builder: (context, state) {
          final role = state is SubmissionStatusLoaded ? state.role : null;
          final isLoading = state is SubmissionStatusLoading;

          return AnimatedContainer(
            duration: Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getCardColor(role),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: _getBorderColor(role),
                width: 1.5,
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isLoading 
                  ? Colors.grey.shade400 
                  : _getIconColor(role),
                child: isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _getIcon(role),
                        color: Colors.white,
                        size: 20,
                      ),
              ),
              title: Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                'Cost Center ID: $costCenterId • ${_getStatusText(role)}',
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
              // Only show verified badge for level02
              trailing: role == 'level02'
                  ? Icon(Icons.verified, color: Colors.green.shade600)
                  : null,
            ),
          );
        },
      ),
    );
  }
}