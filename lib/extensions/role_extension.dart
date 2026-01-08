extension StepDownRole on String? {
  String get stepDown {
    switch (this) {
      case "level01":
        return "Moderetor";
      case "level02":
        return "level01";
      case "admin":
        return "level02";
      default:
        return "Moderetor";
    }
  }
String get stepUp {
    switch (this) {
      case 'level01':
        return 'level02';
      case 'level02':
        return 'admin';
      case 'Moderetor':
        return 'Moderetor';
      default:
        return 'Moderetor'; 
    }
  }
}