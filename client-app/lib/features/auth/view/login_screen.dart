import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:plan_sync/core/services/theme_service.dart';
import 'package:plan_sync/features/auth/viewmodel/login_view_model.dart';
import 'package:plan_sync/util/enums.dart';
import 'package:plan_sync/util/external_links.dart';
import 'package:plan_sync/util/snackbar.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final appTheme = context.watch<ThemeService>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: appTheme.isDarkMode ? 1.0 : 0.24,
              child: SvgPicture.asset(
                appTheme.isDarkMode
                    ? 'assets/login/background-dark.svg'
                    : 'assets/login/background-light.svg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              const Spacer(flex: 7),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    "Synchronize,\nCollaborate,\nElevate.",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                      letterSpacing: 0.2,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 64),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ButtonStyle(
                          elevation: const WidgetStatePropertyAll(0),
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          ),
                          enableFeedback: true,
                          backgroundColor:
                              WidgetStatePropertyAll(colorScheme.primary),
                        ),
                        onPressed: () async {
                          await vm.login(LoginProvider.google);
                          if (!context.mounted) return;
                          if (vm.errorMessage != null) {
                            CustomSnackbar.error(
                                'Authentication Error', vm.errorMessage!, context);
                          }
                        },
                        icon: Icon(
                          FontAwesomeIcons.google,
                          color: colorScheme.onPrimary,
                        ),
                        label: vm.isLoading
                            ? Semantics(
                                value: 'Loading',
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32.0),
                                  child: LoadingAnimationWidget.progressiveDots(
                                    color: colorScheme.onPrimary,
                                    size: 24,
                                  ),
                                ),
                              )
                            : Text(
                                "Continue with Google",
                                style: TextStyle(color: colorScheme.onPrimary),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ButtonStyle(
                          elevation: const WidgetStatePropertyAll(0),
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          ),
                          enableFeedback: true,
                          side: WidgetStatePropertyAll(
                            BorderSide(color: colorScheme.onSurface),
                          ),
                          backgroundColor: WidgetStatePropertyAll(
                            Colors.transparent.withValues(alpha: 0.04),
                          ),
                        ),
                        onPressed: () async {
                          await vm.login(LoginProvider.apple);
                          if (!context.mounted) return;
                          if (vm.errorMessage != null) {
                            CustomSnackbar.error(
                                'Authentication Error', vm.errorMessage!, context);
                          }
                        },
                        icon: Icon(
                          FontAwesomeIcons.apple,
                          color: colorScheme.onSurface,
                        ),
                        label: vm.isLoading
                            ? Semantics(
                                value: 'Loading',
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32.0),
                                  child: LoadingAnimationWidget.progressiveDots(
                                    color: colorScheme.onSurface,
                                    size: 24,
                                  ),
                                ),
                              )
                            : Text(
                                "Continue with Apple",
                                style: TextStyle(color: colorScheme.onSurface),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              Column(
                children: [
                  Text(
                    "Associate Tech Partner",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    enableFeedback: true,
                    onTap: () async {
                      try {
                        await ExternalLinks.cardlink();
                      } catch (e) {
                        if (!context.mounted) return;
                        CustomSnackbar.error(
                          'Failed to open link',
                          'Could not open the link. Please try again.',
                          context,
                        );
                      }
                    },
                    child: SizedBox(
                      height: 48,
                      child: Image.asset(
                        appTheme.isDarkMode
                            ? 'assets/logo-no-background-dark.png'
                            : 'assets/logo-no-background-light.png',
                        semanticLabel: 'Cardlink',
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.16),
                child: Text(
                  "By continuing you agree Plan Sync's Terms of Service and Privacy Policy.",
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }
}
