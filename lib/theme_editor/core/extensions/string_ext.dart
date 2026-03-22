extension StringX on String {
  String capitalize() =>
      isEmpty ? this : '\${this[0].toUpperCase()}\${substring(1).toLowerCase()}';
  bool get isBlank => trim().isEmpty;
}
