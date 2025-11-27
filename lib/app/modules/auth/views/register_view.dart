import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/values/app_strings.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _obscurePassword = true.obs;
  final _obscureConfirmPassword = true.obs;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon
                  Image.asset(
                    'assets/logo_laundry.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 12),

                  

                  // Subtitle
                  Text(
                    AppStrings.registerToGetStarted,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),

                  // Email Field
                  Obx(
                    () => TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: AppStrings.email,
                        hintText: 'name@example.com',
                        prefixIcon: Icon(Icons.email_outlined,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      validator: controller.validateEmail,
                      enabled: !controller.isLoading.value,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  Obx(
                    () => TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword.value,
                      decoration: InputDecoration(
                        labelText: AppStrings.password,
                        hintText: '••••••••',
                        prefixIcon: Icon(Icons.lock_outline,
                            color: Theme.of(context).colorScheme.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword.value
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () => _obscurePassword.value = !_obscurePassword.value,
                        ),
                      ),
                      validator: controller.validatePassword,
                      enabled: !controller.isLoading.value,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  Obx(
                    () => TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword.value,
                      decoration: InputDecoration(
                        labelText: AppStrings.confirmPassword,
                        hintText: '••••••••',
                        prefixIcon: Icon(Icons.lock_outline,
                            color: Theme.of(context).colorScheme.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword.value
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () =>
                              _obscureConfirmPassword.value = !_obscureConfirmPassword.value,
                        ),
                      ),
                      validator: (value) =>
                          controller.validateConfirmPassword(value, _passwordController.text),
                      enabled: !controller.isLoading.value,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Register Button
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  controller.register(
                                    _emailController.text,
                                    _passwordController.text,
                                  );
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Theme.of(context).colorScheme.primary, width: 2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: controller.isLoading.value
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.primary),
                                ),
                              )
                            : Text(
                                AppStrings.register,
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.alreadyHaveAccount,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: controller.isLoading.value ? null : controller.goToLogin,
                        child: Text(
                          AppStrings.login,
                          style: TextStyle(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
