import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../app_state.dart';
import '../theme/neo_brutalist_theme.dart';
import 'neo_button.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: nbBlock(
          color: NB.white,
          radius: NB.radiusChunky,
          shadow: NB.hardShadowLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: nbBlock(
                    color: NB.hotRed,
                    radius: 6,
                    shadow: NB.hardShadowSm,
                    borderWidth: NB.borderThin,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(LucideIcons.triangleAlert,
                      size: 22, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: NB.display(15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: NB.body(13, color: NB.mutedInk, weight: FontWeight.w600),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: NeoButton(
                    color: NB.white,
                    textColor: NB.ink,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Center(child: Text(t('cancel'))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeoButton(
                    color: NB.hotRed,
                    textColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.trash2, size: 14),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            confirmLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}