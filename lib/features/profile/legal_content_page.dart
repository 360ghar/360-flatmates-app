import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/config/constants.dart';
import '../shared/presentation/flatmates_header.dart';

enum LegalContentType { privacyPolicy, termsOfService }

class LegalContentPage extends StatelessWidget {
  const LegalContentPage({
    required this.title,
    required this.type,
    super.key,
  });

  final String title;
  final LegalContentType type;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FlatmatesHeader.backTitle(title: title),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            if (type == LegalContentType.privacyPolicy)
              ..._privacyPolicySections(context)
            else
              ..._termsOfServiceSections(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _privacyPolicySections(BuildContext context) => [
        _SectionHeading('Information We Collect'),
        _Body(
          'We collect information you provide directly when you create an '
              'account, create or update your profile, post a property listing, '
              'communicate with other users, or contact our support team. This '
              'includes your name, email address, phone number, profile photos, '
              'property details, location data, and any other information you '
              'choose to share.',
        ),
        _Body(
          'We automatically collect certain information when you use the app, '
              'including your device type, operating system, IP address, app '
              'usage patterns, and crash reports. This helps us improve the '
              'app experience for all users.',
        ),
        const _Spacer(),
        _SectionHeading('How We Use Your Information'),
        _Body(
          'We use your information to provide, maintain, and improve our '
              'flatmate-matching and property-listing services. This includes '
              'facilitating communication between users, personalising your '
              'experience, processing transactions, and sending service-related '
              'notifications.',
        ),
        _Body(
          'We may use your contact information to send you relevant updates, '
              'promotional offers, and newsletters. You can opt out of marketing '
              'communications at any time through your account settings.',
        ),
        const _Spacer(),
        _SectionHeading('Sharing Your Information'),
        _Body(
          'We share your information with other users only to the extent '
              'necessary for the core functionality of the platform, such as '
              'sharing your profile details with potential flatmates or '
              'landlords when you express interest in a listing.',
        ),
        _Body(
          'We do not sell your personal information to third parties. We may '
              'share anonymised, aggregated data for analytics and research '
              'purposes. We may also disclose information if required by law '
              'or to protect our rights.',
        ),
        const _Spacer(),
        _SectionHeading('Data Security'),
        _Body(
          'We implement industry-standard security measures to protect your '
              'data, including encryption in transit and at rest. However, no '
              'method of electronic storage or transmission is 100%% secure. '
              'You are responsible for maintaining the confidentiality of your '
              'account credentials.',
        ),
        const _Spacer(),
        _SectionHeading('Your Rights'),
        _Body(
          'You can access, update, or delete your personal information at any '
              'time through your account settings. You may also request a copy '
              'of the data we hold about you by contacting our support team.',
        ),
        _Body(
          'You have the right to withdraw consent, object to processing, and '
              'request data portability where applicable under applicable data '
              'protection laws.',
        ),
        const _Spacer(),
        _SectionHeading('Contact Us'),
        _Body(
          'If you have any questions about this Privacy Policy or our data '
              'practices, please contact us at $kSupportEmail.',
        ),
        _Body(
          'This policy was last updated on 1 January 2026. We may update it '
              'from time to time, and we will notify you of material changes '
              'through the app or via email.',
        ),
      ];

  List<Widget> _termsOfServiceSections(BuildContext context) => [
        _SectionHeading('1. Acceptance of Terms'),
        _Body(
          'By accessing or using the 360 FlatMates mobile application, you '
              'agree to be bound by these Terms of Service. If you do not agree '
              'to all the terms, you may not access or use the app.',
        ),
        const _Spacer(),
        _SectionHeading('2. Description of Service'),
        _Body(
          '360 FlatMates is a platform that connects individuals seeking '
              'flatmates and rental accommodations. We facilitate listing, '
              'discovery, and communication between users. We are not a party '
              'to any rental agreement or transaction between users.',
        ),
        const _Spacer(),
        _SectionHeading('3. User Accounts'),
        _Body(
          'You must create an account to use certain features of the app. '
              'You are responsible for maintaining the confidentiality of your '
              'account credentials and for all activities that occur under your '
              'account. You must provide accurate, current, and complete '
              'information during registration.',
        ),
        _Body(
          'You must be at least 18 years old to create an account and use '
              'the service.',
        ),
        const _Spacer(),
        _SectionHeading('4. User Conduct'),
        _Body(
          'You agree not to use the app for any unlawful purpose or in '
              'violation of these terms. Prohibited activities include '
              'misrepresenting your identity, posting false or misleading '
              'listings, harassing other users, spamming, or attempting to '
              'circumvent our systems.',
        ),
        const _Spacer(),
        _SectionHeading('5. Listings and Transactions'),
        _Body(
          'We are not responsible for the accuracy of listings posted by '
              'users. All rental agreements, lease terms, deposits, and '
              'payments are solely between the involved parties. We strongly '
              'recommend verifying property details and conducting due diligence '
              'before entering into any agreement.',
        ),
        const _Spacer(),
        _SectionHeading('6. Intellectual Property'),
        _Body(
          'The app, its design, logos, and content (excluding user-generated '
              'content) are owned by 360 Ghar and protected by intellectual '
              'property laws. You may not reproduce, distribute, or create '
              'derivative works without our express permission.',
        ),
        const _Spacer(),
        _SectionHeading('7. Limitation of Liability'),
        _Body(
          'To the fullest extent permitted by law, 360 Ghar shall not be '
              'liable for any indirect, incidental, special, consequential, or '
              'punitive damages arising out of or related to your use of the '
              'app. Our total liability shall not exceed the amount you have '
              'paid us in the twelve months preceding the claim.',
        ),
        const _Spacer(),
        _SectionHeading('8. Termination'),
        _Body(
          'We reserve the right to suspend or terminate your account at any '
              'time for violation of these terms or for any other reason at our '
              'discretion. You may delete your account at any time through '
              'your account settings.',
        ),
        const _Spacer(),
        _SectionHeading('9. Governing Law'),
        _Body(
          'These terms shall be governed by and construed in accordance with '
              'the laws of India. Any disputes arising under these terms shall '
              'be subject to the exclusive jurisdiction of the courts in '
              'Gurugram, Haryana.',
        ),
        const _Spacer(),
        _SectionHeading('10. Contact'),
        _Body(
          'For questions about these Terms of Service, please contact us at '
              '$kSupportEmail.',
        ),
        _Body(
          'These terms were last updated on 1 January 2026.',
        ),
      ];
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: AppTypography.h3Size,
          fontWeight: AppTypography.h3Weight,
          height: AppTypography.h3Height,
          letterSpacing: AppTypography.h3LetterSpacing,
          color: AppSemanticColors.ink,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppTypography.bodyMediumSize,
          fontWeight: AppTypography.bodyMediumWeight,
          height: AppTypography.bodyMediumHeight,
          color: AppSemanticColors.ink2,
        ),
      ),
    );
  }
}

class _Spacer extends StatelessWidget {
  const _Spacer();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: AppSpacing.sm);
  }
}
