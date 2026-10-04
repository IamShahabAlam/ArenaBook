import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_fontweights.dart';
import '../../../../app/config/app_paddings.dart';
import '../../../../app/config/app_size_config.dart';
import '../../../../app/config/app_strings.dart';
import '../../../../app/service/getx_service/app_dev_mode_service.dart';
import '../../../../app/utils/custom_widgets/arena_logo.dart';
import '../../../../app/utils/custom_widgets/common_text.dart';
import '../../../../app/utils/custom_widgets/custom_textfield.dart';
import '../../../../app/utils/custom_widgets/gradient_button.dart';
import 'login_controller.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = context.theme.colorScheme;
    HeightWidth(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppPaddings.appMainBodyHorizontalPadding),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hidden gesture (double tap, swipe up, swipe right) on the logo toggles Developer Mode
                  DevGestureDetector(child: const Center(child: ArenaLogo(size: 90))),
                  0.02.ph,
                  CommonText(
                    text: AppStrings.appName.isEmpty ? 'Welcome' : AppStrings.appName,
                    fontSize: 24,
                    weight: AppFontWeights.appTextFontWeightBold,
                    textAlign: TextAlign.center,
                    color: theme.onPrimary,
                  ),
                  0.04.ph,
                  CustomTextField(
                    textEditingController: controller.usernameController,
                    hintText: 'Username',
                    preIcon: const Icon(Icons.person_outline),
                    validator: (v) => controller.requiredValidator(v, 'Username'),
                  ),
                  0.015.ph,
                  Obx(
                    () => CustomTextField(
                      textEditingController: controller.passwordController,
                      hintText: 'Password',
                      obscureText: controller.isPasswordHidden.value,
                      preIcon: const Icon(Icons.lock_outline),
                      sufixIcon: Icon(controller.isPasswordHidden.value ? Icons.visibility_off : Icons.visibility),
                      onTapSuff: controller.togglePasswordVisibility,
                      validator: (v) => controller.requiredValidator(v, 'Password'),
                      onFieldSubmitted: (_) => controller.login(),
                    ),
                  ),
                  0.03.ph,
                  GradeBtn(
                    name: 'Login',
                    marginAll: 0,
                    heightB: 0.06,
                    widthB: 1,
                    circularBorder: 8.0,
                    firstClr: theme.onPrimary,
                    lastClr: theme.primaryFixed,
                    textColor: Colors.white,
                    onpressed: controller.login,
                  ),
                  0.03.ph,
                  CommonText(text: AppStrings.kappVersionWithDate, textAlign: TextAlign.center, color: theme.outline),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
