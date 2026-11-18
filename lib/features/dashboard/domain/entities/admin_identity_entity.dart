class AdminIdentityEntity {
  final String id;
  final String fullName;
  final String email;
  final String roleLabel;
  final String organizationLabel;

  const AdminIdentityEntity({
    required this.id,
    required this.fullName,
    required this.email,
    this.roleLabel = 'Super Admin',
    this.organizationLabel = 'ShiftEx Central Control',
  });

  String get firstName {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) {
      if (email.trim().isNotEmpty) {
        final prefix = email.trim().split('@').first.trim();
        if (prefix.isNotEmpty) {
          return prefix[0].toUpperCase() + prefix.substring(1);
        }
      }
      return 'Admin';
    }
    final firstToken = trimmed.split(RegExp(r'\s+')).first;
    if (firstToken.isEmpty) return 'Admin';
    return firstToken[0].toUpperCase() + firstToken.substring(1);
  }

  String greetingPrefix([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String greetingWithName([DateTime? now]) {
    return '${greetingPrefix(now)}, $firstName';
  }

  String get subtitleText => '$roleLabel • $organizationLabel';

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'AD';
    if (parts.length == 1) {
      return parts.first.length >= 2
          ? parts.first.substring(0, 2).toUpperCase()
          : parts.first.toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
