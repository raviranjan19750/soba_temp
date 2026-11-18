/// Workspace role for a user linked to a company.
class CompanyRole {
  CompanyRole._();

  static const String owner = 'owner';
  static const String collaborator = 'collaborator';

  static bool isOwner(String? role) => role == owner;

  static String label(String? role) {
    switch (role) {
      case owner:
        return 'Primary owner';
      case collaborator:
        return 'Collaborator';
      default:
        return 'Team member';
    }
  }
}
