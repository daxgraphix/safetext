import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/grid_painter.dart';
import '../../../shared/widgets/safetext_app_bar.dart';
import '../../../shared/widgets/step_header.dart';
import '../../../shared/widgets/result_sheet.dart';
import '../../../shared/widgets/app_buttons.dart';
import 'providers/lsb_text_provider.dart';

class LsbTextScreen extends ConsumerStatefulWidget {
  const LsbTextScreen({super.key});

  @override
  ConsumerState<LsbTextScreen> createState() => _LsbTextScreenState();
}

class _LsbTextScreenState extends ConsumerState<LsbTextScreen> with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showResultSheet(BuildContext context, LsbTextState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ResultSheet(
        title: 'MESSAGE EMBEDDED',
        description: 'THE SECRET MESSAGE HAS BEEN HIDDEN WITHIN THE PIXELS OF THE IMAGE.',
        sharePath: state.savedFile?.path,
        shareText: 'Encoded with SafeText',
        imageBytes: state.resultBytes,
        imageName: state.encodeImageName != null ? 'encoded_${state.encodeImageName}' : null,
        onDone: () {
          ref.read(lsbTextProvider.notifier).reset();
          _messageController.clear();
        },
        content: state.resultBytes != null
            ? Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.memory(state.resultBytes!, height: 200, width: double.infinity, fit: BoxFit.cover),
              )
            : null,
      ),
    );
  }

  void _showDecodeResultSheet(BuildContext context, LsbTextState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ResultSheet(
        title: 'MESSAGE DECODED',
        description: 'THE HIDDEN MESSAGE HAS BEEN EXTRACTED FROM THE CARRIER IMAGE.',
        shareText: state.decodedMessage,
        onDone: () => ref.read(lsbTextProvider.notifier).reset(),
        content: state.decodedMessage != null
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.black,
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  state.decodedMessage!,
                  style: const TextStyle(
                    fontFamily: 'Roboto Mono',
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    ref.listen(lsbTextProvider, (previous, next) {
      if (next.stage == LsbTextStage.done && previous?.stage != LsbTextStage.done) {
        _showResultSheet(context, next);
      }
      if (next.stage == LsbTextStage.decoded && previous?.stage != LsbTextStage.decoded) {
        _showDecodeResultSheet(context, next);
      }
      if (next.stage == LsbTextStage.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.errorMessage!.toUpperCase(), style: const TextStyle(fontFamily: 'Roboto Mono', fontSize: 12, fontWeight: FontWeight.bold)),
          backgroundColor: scheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm), side: BorderSide(color: scheme.onSurface, width: 2)),
        ));
      }
    });

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: SafeTextAppBar(
        title: 'LSB ON TEXT',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: GridBackground(
        child: Column(
          children: [
            Container(
              color: scheme.surface,
              child: TabBar(
                controller: _tabController,
                dividerColor: scheme.onSurface,
                dividerHeight: 2,
                indicator: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: scheme.onSurface, width: 4),
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 1.0),
                tabs: const [Tab(text: 'ENCODE'), Tab(text: 'DECODE')],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _EncodeTab(messageController: _messageController),
                  const _DecodeTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EncodeTab extends ConsumerStatefulWidget {
  final TextEditingController messageController;
  const _EncodeTab({required this.messageController});

  @override
  ConsumerState<_EncodeTab> createState() => _EncodeTabState();
}

class _EncodeTabState extends ConsumerState<_EncodeTab> {
  Future<void> _pickImage(WidgetRef ref) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    await ref.read(lsbTextProvider.notifier).setEncodeImage(Uint8List.fromList(bytes), picked.name);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(lsbTextProvider);
    final notifier = ref.read(lsbTextProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.margin),
      children: [
        StepHeader(number: 1, title: 'SELECT CARRIER IMAGE', isDone: state.encodeImageBytes != null),
        const SizedBox(height: AppSpacing.md),
        _ImagePreviewBox(
          imageBytes: state.encodeImageBytes,
          onTap: () => _pickImage(ref),
          onClear: state.encodeImageBytes != null ? () {
            notifier.reset();
            widget.messageController.clear();
          } : null,
          label: 'TAP TO SELECT IMAGE',
        ),
        if (state.capacityBytes != null) ...[
          const SizedBox(height: AppSpacing.md),
          _CapacityIndicator(capacity: state.capacityBytes!, used: state.message.length),
        ],
        const SizedBox(height: AppSpacing.xl),
        StepHeader(number: 2, title: 'ENTER SECRET MESSAGE', isDone: state.message.isNotEmpty),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: widget.messageController,
          maxLines: 5,
          onChanged: notifier.setMessage,
          style: const TextStyle(fontFamily: 'Roboto Mono', fontSize: 14),
          decoration: InputDecoration(
            hintText: 'TYPE YOUR MESSAGE HERE...',
            hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.5)),
            filled: true,
            fillColor: scheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(color: scheme.onSurface, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(color: scheme.onSurface, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(color: scheme.onSurface, width: 2),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: state.isBusy ? _stageLabel(state.stage).toUpperCase() : 'ENCODE & SAVE',
          icon: Icons.lock_rounded,
          loading: state.isBusy,
          onPressed: state.canEncode ? () {
            notifier.encode();
          } : null,
        ),
      ],
    );
  }

  String _stageLabel(LsbTextStage stage) {
    switch (stage) {
      case LsbTextStage.analyzing:
        return 'Analyzing...';
      case LsbTextStage.encoding:
        return 'Embedding...';
      case LsbTextStage.saving:
        return 'Saving...';
      default:
        return 'Processing...';
    }
  }
}

class _DecodeTab extends ConsumerWidget {
  const _DecodeTab();

  Future<void> _pickImage(WidgetRef ref) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    await ref.read(lsbTextProvider.notifier).setDecodeImageAndDecode(Uint8List.fromList(bytes), picked.name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(lsbTextProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        _ImagePreviewBox(
          imageBytes: state.decodeImageBytes,
          onTap: () => _pickImage(ref),
          label: 'SELECT IMAGE TO DECODE',
          icon: Icons.image_search_rounded,
        ),
        const SizedBox(height: 24),
        if (state.stage == LsbTextStage.decoding)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(strokeWidth: 4, valueColor: AlwaysStoppedAnimation(scheme.onSurface)),
            ),
          ),
        if (state.stage == LsbTextStage.error)
          Center(
            child: Column(
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: scheme.error),
                const SizedBox(height: 12),
                Text(
                  (state.errorMessage ?? 'NO HIDDEN MESSAGE FOUND.').toUpperCase(),
                  style: TextStyle(fontFamily: 'Roboto Mono', color: scheme.error, fontSize: 13, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ImagePreviewBox extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String label;
  final IconData icon;

  const _ImagePreviewBox({
    required this.imageBytes,
    required this.onTap,
    this.onClear,
    required this.label,
    this.icon = Icons.add_photo_alternate_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: imageBytes == null ? onTap : null,
      child: Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          color: scheme.surface,
          border: Border.all(color: scheme.onSurface, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: imageBytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(imageBytes!, fit: BoxFit.cover),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      children: [
                        if (onClear != null)
                          _CircleActionButton(
                            icon: Icons.close_rounded,
                            onTap: onClear!,
                            color: scheme.error,
                          ),
                        const SizedBox(width: 8),
                        _CircleActionButton(
                          icon: Icons.edit_rounded,
                          onTap: onTap,
                          color: scheme.onSurface,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: scheme.onSurface, width: 2),
                    ),
                    child: Icon(icon, size: 40, color: scheme.onSurface),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _CircleActionButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: scheme.onSurface, width: 2),
        ),
        child: Icon(icon, size: 20, color: scheme.surface),
      ),
    );
  }
}

class _CapacityIndicator extends StatelessWidget {
  final int capacity;
  final int used;

  const _CapacityIndicator({required this.capacity, required this.used});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = (used / capacity).clamp(0.0, 1.0);
    final isOver = used > capacity;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: scheme.onSurface, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STORAGE CAPACITY',
                style: TextStyle(
                  fontFamily: 'Roboto Mono',
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
              Text(
                '$used / $capacity BYTES',
                style: TextStyle(
                  fontFamily: 'Roboto Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isOver ? scheme.error : scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 12,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.onSurface, width: 2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              color: isOver ? scheme.error : (progress > 0.8 ? Colors.orange : scheme.secondary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
