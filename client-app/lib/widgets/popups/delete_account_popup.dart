import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:plan_sync/features/auth/repository/auth_repository.dart';
import 'package:plan_sync/util/snackbar.dart';
import 'package:provider/provider.dart';

class DeleteAccountPopup extends StatefulWidget {
  const DeleteAccountPopup({super.key});

  @override
  State<DeleteAccountPopup> createState() => _DeleteAccountPopupState();
}

class _DeleteAccountPopupState extends State<DeleteAccountPopup> {
  bool isWorking = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.topCenter,
              child: Text(
                "Delete your account?",
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Oops! We're sad to see you go, but we understand."
              "\n\nJust so you know, deleting your account will remove all your data from our servers within 7 working days. "
              "This action can't be undone. We will ask you to sign in again."
              "\n\nBefore you go, is there anything we can help with? "
              "Sometimes a quick chat can solve things easier than starting over.",
              style: TextStyle(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isWorking
                        ? () {}
                        : () async {
                            setState(() => isWorking = true);
                            try {
                              await context
                                  .read<AuthRepository>()
                                  .deleteCurrentUser();
                              if (!context.mounted) return;
                              CustomSnackbar.info(
                                'Account Deleted',
                                "We have sent delete request, it'll be done shortly!",
                                context,
                              );
                              Navigator.of(context).pop();
                            } on DeleteAccountException catch (e) {
                              if (!context.mounted) return;
                              CustomSnackbar.error(
                                  'Operation Failed', e.message, context);
                            } catch (_) {
                              if (!context.mounted) return;
                              CustomSnackbar.error(
                                'Operation Failed',
                                'We faced some error. Please try again later.',
                                context,
                              );
                            } finally {
                              if (mounted) setState(() => isWorking = false);
                            }
                          },
                    style: ButtonStyle(
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      backgroundColor: WidgetStatePropertyAll(
                        colorScheme.error,
                      ),
                      foregroundColor: WidgetStatePropertyAll(
                        colorScheme.onError,
                      ),
                    ),
                    child: isWorking
                        ? LoadingAnimationWidget.progressiveDots(
                            color: colorScheme.onError,
                            size: 24,
                          )
                        : const Text("Delete Account"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        isWorking ? {} : Navigator.of(context).pop(),
                    style: ButtonStyle(
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      backgroundColor: WidgetStatePropertyAll(
                        colorScheme.primary,
                      ),
                      foregroundColor: WidgetStatePropertyAll(
                        colorScheme.onPrimary,
                      ),
                    ),
                    child: isWorking
                        ? LoadingAnimationWidget.progressiveDots(
                            color: colorScheme.onPrimary,
                            size: 24,
                          )
                        : const Text("Cancel"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
