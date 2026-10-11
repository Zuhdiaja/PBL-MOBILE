/// A signed-in user.
///
/// Presentation concerns such as avatars, colors, and icons stay outside the
/// domain; only values the whole feature needs are exposed here.
class UserAccount {
  const UserAccount({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

  /// Up to two uppercase initials, used by the profile avatar.
  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Name up to the first space, used by the home greeting.
  String get firstName {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    return parts.isEmpty ? name : parts.first;
  }
}

/// Aggregate numbers shown on the profile screen.
class AccountStats {
  const AccountStats({
    required this.totalScans,
    required this.submittedReports,
    required this.pendingReports,
  });

  const AccountStats.empty()
    : totalScans = 0,
      submittedReports = 0,
      pendingReports = 0;

  final int totalScans;
  final int submittedReports;
  final int pendingReports;
}
