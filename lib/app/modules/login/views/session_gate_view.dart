import 'package:budget_book_2026/app/core/services/api_services.dart';
import 'package:budget_book_2026/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class SessionGateView extends StatefulWidget {
  const SessionGateView({super.key});

  @override
  State<SessionGateView> createState() => _SessionGateViewState();
}

class _SessionGateViewState extends State<SessionGateView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSession());
  }

  Future<void> _restoreSession() async {
    var hasSession = false;
    try {
      hasSession = await ApiService().restoreSession();
    } catch (_) {
      hasSession = false;
    }

    if (!mounted) return;
    Get.offAllNamed(hasSession ? Routes.HOME : Routes.LOGIN);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),
      body: Center(
        child: SizedBox(
          width: 28.w,
          height: 28.w,
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
