import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/maintenance_controller.dart';

class MaintenanceView extends GetView<MaintenanceController> {
  const MaintenanceView({super.key});

  static const Color _background = Color(0xFFF5F9FB);
  static const Color _dark = Color(0xFF183746);
  static const Color _secondary = Color(0xFF718591);
  static const Color _tealLight = Color(0xFFE8F6F4);
  static const Color _border = Color(0xFFE7EFF2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // Brand / Status
                      _buildStatus(),

                      const SizedBox(height: 38),

                      // Maintenance Illustration
                      _buildIllustration(),

                      const SizedBox(height: 38),

                      // Dynamic Title
                      Obx(
                        () => Text(
                          controller.title.value,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'HankenGrotesk',
                            fontSize: 27,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                            color: _dark,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Dynamic Message
                      Obx(
                        () => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            controller.message.value,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'HankenGrotesk',
                              fontSize: 15,
                              height: 1.65,
                              fontWeight: FontWeight.w500,
                              color: _secondary,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Information Section
                      _buildInformation(),

                      const SizedBox(height: 30),

                      // Retry Button
                      Obx(() => _buildRetryButton()),

                      const SizedBox(height: 12),

                      // Error Message
                      Obx(() => _buildErrorMessage()),

                      const Spacer(flex: 2),

                      // Footer
                      _buildFooter(),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFE6A23C),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE6A23C).withValues(alpha: 0.25),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          const Text(
            'TEMPORARILY UNAVAILABLE',
            style: TextStyle(
              fontFamily: 'HankenGrotesk',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: _dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    return SizedBox(
      width: 230,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Circle
          Container(
            width: 190,
            height: 190,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF5F5),
              shape: BoxShape.circle,
            ),
          ),

          // Inner Circle
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFDCEEEB), width: 1.5),
            ),
          ),

          // Main Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _tealLight,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.home_repair_service_rounded,
              size: 53,
              color: AppColors.primaryTeal,
            ),
          ),

          // Floating Tool Icon
          Positioned(
            top: 15,
            right: 24,
            child: _floatingIcon(
              Icons.settings_rounded,
              const Color(0xFFFFF4E4),
              const Color(0xFFE5A03D),
            ),
          ),

          // Floating Check Icon
          Positioned(
            bottom: 17,
            left: 22,
            child: _floatingIcon(
              Icons.build_rounded,
              const Color(0xFFE8F4F1),
              AppColors.primaryTeal,
            ),
          ),

          // Small Decorative Dot
          Positioned(
            top: 55,
            left: 18,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: Color(0xFFE6B66D),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            bottom: 48,
            right: 16,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF91C9BE),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingIcon(IconData icon, Color background, Color foreground) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: _dark.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: 22, color: foreground),
    );
  }

  Widget _buildInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _tealLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: AppColors.primaryTeal,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We will be back shortly',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _dark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Our team is working behind the scenes to improve your experience. Thank you for bearing with us.',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 12.5,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: _secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    final isRetrying = controller.isRetrying.value;

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: FilledButton(
        onPressed: isRetrying ? null : controller.retry,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryTeal,
          disabledBackgroundColor: AppColors.primaryTeal.withValues(
            alpha: 0.65,
          ),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: isRetrying
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    controller.buttonText.value,
                    style: const TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.refresh_rounded, size: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    final error = controller.errorMessage.value;

    if (error.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF2E0BD)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFAA7628),
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              error,
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A5A00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          width: 35,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFFDCE8EB),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 14),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 14,
              color: Color(0xFF90A4AE),
            ),
            SizedBox(width: 6),
            Text(
              'Thank you for your patience',
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF90A4AE),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
      ],
    );
  }
}
