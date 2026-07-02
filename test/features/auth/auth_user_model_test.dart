import 'package:flutter_test/flutter_test.dart';
import 'package:sic_mobile/features/auth/data/models/auth_user_model.dart';

void main() {
  group('AuthUserModel.fromJson', () {
    test('mappe correctement tous les champs de profil et KYC', () {
      final json = {
        'id': 'agent-123',
        'first_name': 'Jean',
        'last_name': 'Kaboré',
        'phone_number': '+22670123456',
        'email': 'jean.kabore@example.com',
        'kyc_status': 'APPROVED',
        'is_suspended': false,
        'account_type': 'AGENT',
        'kyc_tier': 2,
        'kyc_requested_tier': 2,
        'kyc_rejection_reason': '',
      };

      final user = AuthUserModel.fromJson(json);

      expect(user.id, 'agent-123');
      expect(user.firstName, 'Jean');
      expect(user.lastName, 'Kaboré');
      expect(user.phoneNumber, '+22670123456');
      expect(user.email, 'jean.kabore@example.com');
      expect(user.kycStatus, 'APPROVED');
      expect(user.isSuspended, isFalse);
      expect(user.accountType, 'AGENT');
      expect(user.kycTier, 2);
      expect(user.kycRequestedTier, 2);
      expect(user.kycRejectionReason, '');
      expect(user.isApproved, isTrue);
      expect(user.kycSubmitted, isFalse);
    });

    test('utilise des valeurs par défaut si certains champs sont absents', () {
      final json = {
        'id': 456,
      };

      final user = AuthUserModel.fromJson(json);

      expect(user.id, '456');
      expect(user.firstName, '');
      expect(user.lastName, '');
      expect(user.phoneNumber, '');
      expect(user.email, '');
      expect(user.kycStatus, 'PENDING');
      expect(user.isSuspended, isFalse);
      expect(user.accountType, 'AGENT');
      expect(user.kycTier, 0);
      expect(user.kycRequestedTier, isNull);
      expect(user.kycRejectionReason, '');
    });
  });
}
