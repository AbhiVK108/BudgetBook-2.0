import 'package:budget_book_2026/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(35),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(29),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sign up ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: controller.usernameController,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'manvitha20',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: '••••••',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: '••••••',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Obx(
                  () => InkWell(
                    onTap: controller.isLoading.value
                        ? null
                        : () => controller.registerUser(),
                    borderRadius: BorderRadius.circular(29),
                    child: Container(
                      height: 52,
                      width: 245,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(29),
                        gradient: const LinearGradient(
                          colors: [Color(0xffEA5D09), Color(0xffFD9430)],
                        ),
                      ),
                      child: Center(
                        child: controller.isLoading.value
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Get.toNamed(Routes.LOGIN);
                  },
                  child: Text("login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

