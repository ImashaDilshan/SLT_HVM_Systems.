class SharedDataState {
  final String? location;
  final String? mode;
  final DateTime? date;
  final String? role;

  SharedDataState({
    this.location,
    this.mode,
    this.date,
    this.role,
  });

  bool get isReady =>
      location != null && mode != null && date != null && role != null;

  SharedDataState copyWith({
    String? location,
    String? mode,
    DateTime? date,
    String? role,
  }) {
    return SharedDataState(
      location: location ?? this.location,
      mode: mode ?? this.mode,
      date: date ?? this.date,
      role: role ?? this.role,
    );
  }
}
