import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/history_entry.dart';
import '../../shared/dialogs/confirm_dialog.dart';
import '../../shared/widgets/activity_tile.dart';
import '../../shared/widgets/status_chip.dart';
import '../../shared/widgets/grid_painter.dart';
import '../../shared/widgets/safetext_app_bar.dart';

enum _Filter { all, encoded, decoded, tools }

class _EntryMeta {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String trailingText;
  const _EntryMeta({required this.icon, required this.color, required this.title, required this.subtitle, required this.trailingText});
}

_EntryMeta _metaFor(HistoryEntry entry, ColorScheme scheme) {
  switch (entry.toolId) {
    case HistoryTool.lsbText:
      return _EntryMeta(
        icon: entry.operation == HistoryOperation.encoded ? Icons.image_search_rounded : Icons.visibility_rounded,
        color: AppColors.green,
        title: 'LSB ON TEXT · ${entry.imageName.toUpperCase()}',
        subtitle: '${Formatters.timestamp(entry.timestamp)}  ·  PLAIN LSB',
        trailingText: entry.operation == HistoryOperation.encoded ? 'HIDDEN' : 'REVEALED',
      );
    case HistoryTool.lsbDes:
      return _EntryMeta(
        icon: entry.operation == HistoryOperation.encoded ? Icons.enhanced_encryption_rounded : Icons.no_encryption_rounded,
        color: AppColors.red,
        title: 'LSB WITH DES · ${entry.imageName.toUpperCase()}',
        subtitle: '${Formatters.timestamp(entry.timestamp)}  ·  DES-CBC',
        trailingText: entry.operation == HistoryOperation.encoded ? 'ENCRYPTED' : 'DECRYPTED',
      );
    case HistoryTool.passwordGenerator:
      return _EntryMeta(
        icon: Icons.password_rounded,
        color: AppColors.green,
        title: 'PASSWORD GENERATED',
        subtitle: '${Formatters.timestamp(entry.timestamp)}  ·  ${entry.imageName.toUpperCase()}',
        trailingText: 'NOT STORED',
      );
    case HistoryTool.caesarEncrypt:
    case HistoryTool.caesarDecrypt:
      return _EntryMeta(
        icon: Icons.abc_rounded,
        color: scheme.primary,
        title: entry.operation == HistoryOperation.encoded ? 'CAESAR ENCRYPTED' : 'CAESAR DECRYPTED',
        subtitle: '${Formatters.timestamp(entry.timestamp)}  ·  ${entry.imageName.toUpperCase()}',
        trailingText: 'CIPHER',
      );
    case HistoryTool.safetext:
    default:
      return _EntryMeta(
        icon: entry.operation == HistoryOperation.encoded ? Icons.lock_rounded : Icons.lock_open_rounded,
        color: entry.operation == HistoryOperation.encoded ? scheme.primary : AppColors.red,
        title: entry.imageName.toUpperCase(),
        subtitle: '${Formatters.timestamp(entry.timestamp)}  ·  ${(entry.cipherAlgorithm ?? entry.mode).toUpperCase()}',
        trailingText: entry.operation == HistoryOperation.encoded ? 'ENCODED' : 'DECODED',
      );
  }
}

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _Filter _filter = _Filter.all;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final history = ref.watch(historyProvider);

    final filtered = history.where((e) {
      switch (_filter) {
        case _Filter.encoded:
          if (e.operation != HistoryOperation.encoded) return false;
          break;
        case _Filter.decoded:
          if (e.operation != HistoryOperation.decoded) return false;
          break;
        case _Filter.tools:
          if (e.toolId == HistoryTool.safetext) return false;
          break;
        case _Filter.all:
          break;
      }
      if (_query.isNotEmpty && !e.imageName.toLowerCase().contains(_query.toLowerCase())) return false;
      return true;
    }).toList();

    final grouped = <String, List<HistoryEntry>>{};
    for (final entry in filtered) {
      final label = Formatters.dateLabel(entry.timestamp);
      grouped.putIfAbsent(label, () => []).add(entry);
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: SafeTextAppBar(
        scrollController: _scrollController,
        trailing: IconButton(
          icon: const Icon(Icons.delete_sweep_outlined, size: 20),
          tooltip: 'Clear history',
          onPressed: history.isEmpty
              ? null
              : () async {
                  await HapticFeedback.lightImpact();
                  if (!context.mounted) return;
                  final confirmed = await showConfirmDialog(
                    context,
                    title: 'Clear History',
                    message: 'This permanently deletes all secure history metadata. Action history cannot be recovered once cleared.',
                    confirmLabel: 'Clear All',
                    danger: true,
                  );
                  if (confirmed != true) return;
                  if (!context.mounted) return;
                  ref.read(historyProvider.notifier).clearAllWithUndo();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: scheme.onSurface,
                      content: Text('HISTORY CLEARED', style: TextStyle(color: scheme.surface, fontWeight: FontWeight.w900, fontSize: 11)),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        side: BorderSide(color: scheme.outline, width: 2.0),
                      ),
                      action: SnackBarAction(
                        label: 'UNDO',
                        textColor: AppColors.green,
                        onPressed: () => ref.read(historyProvider.notifier).restoreLastCleared(),
                      ),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                },
        ),
      ),
      body: GridBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.margin, 18, AppSpacing.margin, 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: scheme.outline, width: 2.0),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0, fontFamily: 'Roboto Mono'),
                      decoration: InputDecoration(
                        filled: false,
                        hintText: 'SEARCH SECURE LOGS...',
                        hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w700, letterSpacing: 1.0),
                        prefixIcon: Icon(Icons.search_rounded, color: scheme.onSurface, size: 20),
                        prefixIconConstraints: const BoxConstraints(minWidth: 40),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(label: 'All Activity', selected: _filter == _Filter.all, onTap: () => setState(() => _filter = _Filter.all)),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Encoded', selected: _filter == _Filter.encoded, onTap: () => setState(() => _filter = _Filter.encoded)),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Decoded', selected: _filter == _Filter.decoded, onTap: () => setState(() => _filter = _Filter.decoded)),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Utilities', selected: _filter == _Filter.tools, onTap: () => setState(() => _filter = _Filter.tools)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: scheme.surface,
                                border: Border.all(color: scheme.outline, width: 2),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Icon(Icons.history_rounded, size: 36, color: scheme.primary),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              (_query.isEmpty ? 'No History Yet' : 'No Results Found').toUpperCase(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              (_query.isEmpty
                                  ? 'Your secure operations will appear here as you use the app.'
                                  : 'Try adjusting your search or filters to find what you\'re looking for.').toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface.withValues(alpha: 0.85),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(AppSpacing.margin, 0, AppSpacing.margin, 110),
                      itemCount: grouped.length,
                      itemBuilder: (context, index) {
                        final section = grouped.entries.elementAt(index);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 12, 0, 12),
                              child: Text(
                                section.key.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                            ...section.value.map((entry) {
                              final meta = _metaFor(entry, scheme);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Dismissible(
                                  key: ValueKey(entry.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: AppColors.red,
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                      border: Border.all(color: scheme.outline, width: 2),
                                    ),
                                    child: Icon(Icons.delete_outline_rounded, color: scheme.onError),
                                  ),
                                  onDismissed: (_) {
                                    ref.read(historyProvider.notifier).delete(entry.id);
                                    HapticFeedback.lightImpact();
                                  },
                                  child: ActivityTile(
                                    icon: meta.icon,
                                    iconColor: meta.color,
                                    title: meta.title,
                                    subtitle: meta.subtitle,
                                    trailingText: meta.trailingText,
                                    statusLabel: entry.status == HistoryStatus.success ? 'SECURE' : 'FAILED',
                                    statusTone: entry.status == HistoryStatus.success ? StatusTone.success : StatusTone.danger,
                                    onTap: () => _showEntryDetails(context, entry, meta),
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEntryDetails(BuildContext context, HistoryEntry entry, _EntryMeta meta) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
        side: BorderSide(color: AppColors.black, width: 2),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(top: BorderSide(color: scheme.outline, width: 2)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outline.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.margin, 24, AppSpacing.margin, 40),
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(color: meta.color, width: 2),
                          ),
                          child: Icon(meta.icon, color: meta.color, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meta.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                Formatters.timestamp(entry.timestamp).toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: scheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'TECHNICAL METADATA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(label: 'OPERATION ID', value: entry.id, useMono: true),
                    _DetailRow(label: 'TOOL SIGNATURE', value: entry.toolId.toUpperCase()),
                    _DetailRow(label: 'SECURITY MODE', value: entry.mode.toUpperCase(), useMono: true),
                    if (entry.cipherAlgorithm != null)
                      _DetailRow(label: 'CIPHER', value: entry.cipherAlgorithm!.toUpperCase(), useMono: true),
                    if (entry.sizeBytes != null)
                      _DetailRow(label: 'PAYLOAD SIZE', value: Formatters.bytes(entry.sizeBytes!).toUpperCase()),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: scheme.outline, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.privacy_tip_rounded, color: AppColors.red, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                'PRIVACY ENFORCEMENT',
                                style: TextStyle(fontWeight: FontWeight.w900, color: scheme.onSurface),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'THIS LOG CONTAINS ONLY CRYPTOGRAPHIC METADATA. SAFETEXT DOES NOT PERSIST THE ORIGINAL MESSAGE, PASSPHRASES, OR THE FINAL MEDIA ASSETS TO LOCAL STORAGE.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                              color: scheme.onSurface.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool useMono;
  const _DetailRow({required this.label, required this.value, this.useMono = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onSurface)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
              fontFamily: 'Roboto Mono',
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: scheme.outline,
              width: 2.0,
            ),
          ),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: selected ? scheme.onPrimary : scheme.onSurface,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

