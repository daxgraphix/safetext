import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/export_service.dart';
import '../../core/security/device_integrity_service.dart';
import '../../data/models/history_entry.dart';
import '../widgets/app_buttons.dart';
import '../../features/security_center/providers/integrity_provider.dart';

class ExportReportSheet extends ConsumerWidget {
  final List<HistoryEntry> history;
  final DeviceIntegrityResult integrity;

  const ExportReportSheet({
    super.key,
    required this.history,
    required this.integrity,
  });

  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    List<HistoryEntry> history,
  ) async {
    final integrity = await ref.read(integrityProvider.future);
    if (!context.mounted) return;

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ExportReportSheet(
        history: history,
        integrity: integrity,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final exportService = ref.read(exportServiceProvider);

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.onSurface, width: 2)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EXPORT SECURITY AUDIT',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'SELECT A FORMAT FOR YOUR SECURE REPORT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'TEXT FILE',
                      icon: Icons.description_rounded,
                      onPressed: () {
                        Navigator.pop(context);
                        exportService.shareTextReport(
                          history: history,
                          integrity: integrity,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SecondaryButton(
                      label: 'PDF SHARE',
                      icon: Icons.share_rounded,
                      onPressed: () {
                        Navigator.pop(context);
                        exportService.sharePdfReport(
                          history: history,
                          integrity: integrity,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'SAVE PDF',
                      icon: Icons.save_alt_rounded,
                      onPressed: () async {
                        Navigator.pop(context);
                        await exportService.savePdfToFile(
                          history: history,
                          integrity: integrity,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('REPORT SAVED TO FILES')),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SecondaryButton(
                      label: 'PRINT',
                      icon: Icons.print_rounded,
                      onPressed: () {
                        Navigator.pop(context);
                        exportService.printReport(
                          history: history,
                          integrity: integrity,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'REPORTS CONTAIN HARDWARE METADATA & CRYPTO AUDIT LOGS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface.withValues(alpha: 0.4),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
