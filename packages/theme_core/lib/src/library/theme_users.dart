/// The editor's user profiles (`UserProfileType`) a theme can be built for.
const themeUsers = ['suraj', 'subhangi', 'rajat', 'abhishek', 'annapurna'];

/// The profile name [input] stands for, ignoring case and spaces; null when
/// it is not one of [themeUsers].
String? themeUserOf(Object? input) {
  if (input is! String) return null;
  final name = input.trim().toLowerCase();
  return themeUsers.contains(name) ? name : null;
}
