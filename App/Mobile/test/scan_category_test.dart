import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/features/scan_results/domain/entities/scan_category.dart';
import 'package:pbl_semester5/widgets/scan_components.dart';

void main() {
  group('categoryLabel', () {
    test('shows legitimate as Aman, the same wording as benign', () {
      expect(categoryLabel('Legitimate'), 'Aman');
      expect(categoryLabel('Benign'), 'Aman');
    });

    test('keeps dangerous classes readable', () {
      expect(categoryLabel('Phishing'), 'Phishing');
      expect(categoryLabel('Malware'), 'Malware');
      expect(categoryLabel('Spam'), 'Spam');
    });
  });
  group('ScanCategory', () {
    test('maps every label the model can return', () {
      expect(ScanCategory.fromRaw('benign'), ScanCategory.benign);
      expect(ScanCategory.fromRaw('legitimate'), ScanCategory.legitimate);
      expect(ScanCategory.fromRaw('phishing'), ScanCategory.phishing);
      expect(ScanCategory.fromRaw('malware'), ScanCategory.malware);
      expect(ScanCategory.fromRaw('spam'), ScanCategory.spam);
      expect(ScanCategory.fromRaw('defacement'), ScanCategory.defacement);
      expect(ScanCategory.fromRaw('exploit'), ScanCategory.exploit);
    });

    test('ignores case and surrounding spaces', () {
      expect(ScanCategory.fromRaw('  PHISHING '), ScanCategory.phishing);
    });

    test('keeps unknown labels out of the safe group', () {
      expect(ScanCategory.fromRaw('lainnya'), ScanCategory.unknown);
      expect(ScanCategory.isSafe(ScanCategory.unknown), isFalse);
    });

    test('treats benign and legitimate as safe but distinct', () {
      expect(ScanCategory.isSafe(ScanCategory.benign), isTrue);
      expect(ScanCategory.isSafe(ScanCategory.legitimate), isTrue);
      expect(ScanCategory.benign, isNot(ScanCategory.legitimate));
      expect(
        ScanCategory.recommendation(ScanCategory.benign),
        isNot(ScanCategory.recommendation(ScanCategory.legitimate)),
      );
    });

    test('grades risk by class', () {
      expect(ScanCategory.riskLevel(ScanCategory.benign), 'Low Risk');
      expect(ScanCategory.riskLevel(ScanCategory.legitimate), 'Low Risk');
      expect(ScanCategory.riskLevel(ScanCategory.spam), 'Medium Risk');
      expect(ScanCategory.riskLevel(ScanCategory.phishing), 'High Risk');
      expect(ScanCategory.riskLevel(ScanCategory.malware), 'High Risk');
    });

    test('marks dangerous classes as unsafe', () {
      for (final category in [
        ScanCategory.phishing,
        ScanCategory.malware,
        ScanCategory.spam,
        ScanCategory.defacement,
        ScanCategory.exploit,
      ]) {
        expect(ScanCategory.isSafe(category), isFalse);
      }
    });
  });
}
