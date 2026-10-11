import '../../domain/entities/user_account.dart';

/// Account payload the data sources hand back to the repositories.
class UserAccountModel {
  const UserAccountModel({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

  UserAccount toEntity() => UserAccount(id: id, name: name, email: email);
}
