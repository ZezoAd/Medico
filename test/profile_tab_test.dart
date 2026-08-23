/// Layout and fallback checks for the Profile tab and the Home top bar.
///
/// Both are pumped at 360x800 — the narrowest device the app targets — so a
/// RenderFlex overflow in the banner or the top bar fails here rather than
/// on the Small Phone emulator.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medico/models/onboarding_data.dart';
import 'package:medico/screens/home_tab.dart';
import 'package:medico/screens/profile_tab.dart';
import 'package:medico/theme/aurora_tokens.dart';

/// The narrowest supported width.
const _narrow = Size(360, 800);

void _sizeTo(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget _host(Widget child) {
  return MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(backgroundColor: AuroraColors.background, body: child),
    ),
  );
}

Widget _profile({
  bool isSignedIn = true,
  Gender? gender,
  String? fullName,
  String? phone,
  String? email,
  Future<void> Function()? onSignOut,
}) {
  return _host(
    ProfileTab(
      isSignedIn: isSignedIn,
      gender: gender,
      fullName: fullName,
      phone: phone,
      email: email,
      onSignOut: onSignOut ?? () async {},
    ),
  );
}

void main() {
  group('ProfileTab fallbacks', () {
    testWidgets('null full_name falls back to مستخدم', (tester) async {
      _sizeTo(tester, _narrow);
      await tester.pumpWidget(_profile(phone: '٠٧٧٠١٢٣٤٥٦٧'));

      expect(find.text('مستخدم'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('blank full_name falls back to مستخدم', (tester) async {
      _sizeTo(tester, _narrow);
      await tester.pumpWidget(_profile(fullName: '   '));

      expect(find.text('مستخدم'), findsOneWidget);
    });

    testWidgets('null phone falls back to the session email', (tester) async {
      _sizeTo(tester, _narrow);
      await tester.pumpWidget(_profile(email: 'patient@example.com'));

      expect(find.text('patient@example.com'), findsOneWidget);
    });

    testWidgets('phone wins over email when both exist', (tester) async {
      _sizeTo(tester, _narrow);
      await tester.pumpWidget(
        _profile(phone: '07701234567', email: 'patient@example.com'),
      );

      expect(find.text('07701234567'), findsOneWidget);
      expect(find.text('patient@example.com'), findsNothing);
    });

    testWidgets('no phone and no email shows غير متوفر', (tester) async {
      _sizeTo(tester, _narrow);
      await tester.pumpWidget(_profile(fullName: 'سارة'));

      expect(find.text('غير متوفر'), findsOneWidget);
    });

    testWidgets('signed out shows غير مسجل', (tester) async {
      _sizeTo(tester, _narrow);
      await tester.pumpWidget(_profile(isSignedIn: false));

      expect(find.text('غير مسجل'), findsOneWidget);
    });
  });

  group('ProfileTab settings list', () {
    testWidgets('renders the five rows in order', (tester) async {
      _sizeTo(tester, _narrow);
      await tester.pumpWidget(_profile(fullName: 'سارة'));

      const expected = [
        'إشعاراتي',
        'الأرقام',
        'تواصل معنا',
        'الشروط والأحكام',
        'تسجيل الخروج',
      ];
      for (final label in expected) {
        expect(find.text(label), findsOneWidget);
      }

      double top(String label) => tester.getTopLeft(find.text(label)).dy;
      for (var i = 1; i < expected.length; i++) {
        expect(top(expected[i]), greaterThan(top(expected[i - 1])));
      }
    });

    testWidgets('only تسجيل الخروج is tappable', (tester) async {
      _sizeTo(tester, _narrow);
      var signOuts = 0;
      await tester.pumpWidget(
        _profile(fullName: 'سارة', onSignOut: () async => signOuts++),
      );

      for (final label in const [
        'إشعاراتي',
        'الأرقام',
        'تواصل معنا',
        'الشروط والأحكام',
      ]) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      // The edit affordance on the banner is inert too.
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(signOuts, 0);
      expect(find.byType(SnackBar), findsNothing);

      await tester.tap(find.text('تسجيل الخروج'));
      await tester.pumpAndSettle();
      expect(signOuts, 1);
    });
  });

  group('RTL layout at 360px', () {
    testWidgets('banner puts the avatar right of the name', (tester) async {
      _sizeTo(tester, _narrow);
      await tester.pumpWidget(
        _profile(
          gender: Gender.female,
          fullName: 'اسم طويل جدا لمستخدم التطبيق للتحقق من الفيض',
          phone: '٠٧٧٠١٢٣٤٥٦٧',
        ),
      );

      final avatarX = tester
          .getCenter(find.byIcon(Icons.person_outline_rounded))
          .dx;
      final nameX = tester
          .getCenter(find.text('اسم طويل جدا لمستخدم التطبيق للتحقق من الفيض'))
          .dx;
      final pencilX = tester.getCenter(find.byIcon(Icons.edit_outlined)).dx;

      expect(avatarX, greaterThan(nameX));
      expect(nameX, greaterThan(pencilX));
      expect(tester.takeException(), isNull);
    });

    testWidgets('home top bar puts the bell left of the search bar', (
      tester,
    ) async {
      _sizeTo(tester, _narrow);
      await tester.pumpWidget(_host(const HomeTab()));
      await tester.pump();

      final bellX = tester
          .getCenter(find.byIcon(Icons.notifications_none_rounded))
          .dx;
      final placeholder = find.text('ابحث عن طبيب أو تخصص');
      expect(placeholder, findsOneWidget);

      final searchIconX = tester
          .getCenter(find.byIcon(Icons.search_rounded))
          .dx;
      final placeholderRight = tester.getBottomRight(placeholder).dx;

      // Bell on the visual left, search filling the rest to the right.
      expect(bellX, lessThan(searchIconX));
      // Placeholder pinned to the pill's own right-hand edge, past the
      // magnifier rather than beside it.
      expect(placeholderRight, greaterThan(searchIconX));
      expect(tester.takeException(), isNull);
    });
  });
}
