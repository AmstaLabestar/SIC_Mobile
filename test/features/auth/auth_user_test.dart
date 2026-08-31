import 'package:flutter_test/flutter_test.dart';
import 'package:sic_mobile/features/auth/domain/entities/auth_user.dart';

AuthUser _user({
  String accountType = 'AGENT',
  String first = '',
  String last = '',
}) =>
    AuthUser(
      id: '1',
      firstName: first,
      lastName: last,
      phoneNumber: '70000000',
      email: 'a@b.c',
      kycStatus: 'APPROVED',
      isSuspended: false,
      accountType: accountType,
    );

void main() {
  group('AuthUser.roleLabel', () {
    test('agent -> Agent', () {
      expect(_user(accountType: 'AGENT').roleLabel, 'Agent');
    });

    test('client -> Client', () {
      expect(_user(accountType: 'CLIENT').roleLabel, 'Client');
    });

    test('isAgent / isClient insensibles a la casse', () {
      expect(_user(accountType: 'client').isClient, isTrue);
      expect(_user(accountType: 'agent').isAgent, isTrue);
    });
  });

  group('AuthUser.fullName', () {
    test('nom present', () {
      expect(_user(first: 'Awa', last: 'Traore').fullName, 'Awa Traore');
    });

    test('sans nom -> fallback role-neutre (ni Agent ni Client code en dur)', () {
      expect(_user(accountType: 'CLIENT').fullName, 'Utilisateur SIC');
      expect(_user(accountType: 'AGENT').fullName, 'Utilisateur SIC');
    });
  });
}
