class SubmitBulkRoleUpdate {
  final String tableName;
  final String location;
  final String mode;
  final String role;
  final String newRole;

  SubmitBulkRoleUpdate({
    required this.tableName,
    required this.location,
    required this.mode,
    required this.role,
    required this.newRole,
  });
}
