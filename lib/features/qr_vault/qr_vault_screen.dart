import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/security_colors.dart';
import '../../core/services/export_service.dart';
import '../../shared/widgets/step_header.dart';
import '../../data/models/history_entry.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/grid_painter.dart';
import '../../shared/widgets/result_sheet.dart';
import '../../shared/widgets/safetext_app_bar.dart';
import '../../shared/dialogs/security_gate_dialog.dart';

const _uuid = Uuid();

class QRVaultScreen extends ConsumerStatefulWidget {
  const QRVaultScreen({super.key});

  @override
  ConsumerState<QRVaultScreen> createState() => _QRVaultScreenState();
}

class _QRVaultScreenState extends ConsumerState<QRVaultScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAuthenticated = false;
  bool _isAuthenticating = true;

  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  
  final _textController = TextEditingController();
  final _keyController = TextEditingController();
  final _screenshotController = ScreenshotController();
  
  bool _isSecure = false;
  String _generatedData = '';
  bool _isGenerating = false;

  QrEyeShape _eyeShape = QrEyeShape.square;
  QrDataModuleShape _dataModuleShape = QrDataModuleShape.square;
  Color _qrColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() => _isAuthenticating = true);
    final success = await SecurityGateDialog.show(context);
    if (mounted) {
      setState(() {
        _isAuthenticated = success;
        _isAuthenticating = false;
      });
    }
  }

  void _handleTabChange() {
    if (_tabController.index == 1) {
      _scannerController.start();
    } else {
      _scannerController.stop();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _textController.dispose();
    _keyController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _generateQR() async {
    if (_textController.text.isEmpty) return;
    
    setState(() => _isGenerating = true);
    HapticFeedback.mediumImpact();

    try {
      String dataToEncode = _textController.text;
      String? cipherAlgo;

      if (_isSecure && _keyController.text.isNotEmpty) {
        final crypto = ref.read(cryptoServiceProvider);
        final result = await crypto.encrypt(_textController.text, _keyController.text);
        
        // Pack: salt(16) + nonce(12) + mac(16) + ciphertext
        final payload = BytesBuilder();
        payload.add(result.salt);
        payload.add(result.nonce);
        payload.add(result.mac);
        payload.add(result.cipherText);
        
        dataToEncode = 'STXQ:${base64Encode(payload.toBytes())}';
        cipherAlgo = 'AES-256-GCM';
      }

      setState(() {
        _generatedData = dataToEncode;
        _isGenerating = false;
      });

      // Trigger glitch/success haptics
      HapticFeedback.heavyImpact();

      // Add to history
      final entry = HistoryEntry(
        id: _uuid.v4(),
        operation: HistoryOperation.generated,
        imageName: 'QR Code',
        mode: _isSecure ? 'Encrypted' : 'Direct',
        timestamp: DateTime.now(),
        status: HistoryStatus.success,
        cipherAlgorithm: cipherAlgo,
        toolId: HistoryTool.qrGenerate,
      );
      ref.read(historyProvider.notifier).add(entry);
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GENERATION FAILED: $e')),
        );
      }
    }
  }

  void _handleScan(String data) async {
    HapticFeedback.heavyImpact();
    
    if (data.startsWith('STXQ:')) {
      final base64Part = data.substring(5);
      _showDecryptionDialog(base64Part);
    } else {
      _showResult('QR DATA EXTRACTED', 'DIRECT MESSAGE DECODED FROM QR.', data);
    }
  }

  void _showDecryptionDialog(String base64Data) {
    final scanKeyController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: Theme.of(context).colorScheme.onSurface, width: 2)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SECURE QR DETECTED',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              const Text(
                'THIS QR CODE IS ENCRYPTED. ENTER THE PASSPHRASE TO DECODE.',
                style: TextStyle(fontFamily: 'Roboto Mono', fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: scanKeyController,
                obscureText: true,
                style: const TextStyle(fontFamily: 'Roboto Mono', fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'PASSPHRASE',
                  hintText: 'ENTER KEY...',
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'DECRYPT & REVEAL',
                onPressed: () async {
                  final key = scanKeyController.text;
                  Navigator.pop(context);
                  _decryptQR(base64Data, key);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _decryptQR(String base64Data, String key) async {
    try {
      final bytes = base64Decode(base64Data);
      if (bytes.length < 44) throw Exception('Invalid payload');

      final salt = bytes.sublist(0, 16);
      final nonce = bytes.sublist(16, 28);
      final mac = bytes.sublist(28, 44);
      final cipherText = bytes.sublist(44);

      final crypto = ref.read(cryptoServiceProvider);
      final decrypted = await crypto.decrypt(
        salt: salt,
        nonce: nonce,
        cipherText: cipherText,
        mac: mac,
        passphrase: key,
      );

      _showResult('DECRYPTION SUCCESS', 'SECURE MESSAGE REVEALED.', decrypted, isSecure: true);
      
      // Add to history
      final entry = HistoryEntry(
        id: _uuid.v4(),
        operation: HistoryOperation.decoded,
        imageName: 'Secure QR',
        mode: 'Encrypted',
        timestamp: DateTime.now(),
        status: HistoryStatus.success,
        cipherAlgorithm: 'AES-256-GCM',
        toolId: HistoryTool.qrScan,
      );
      ref.read(historyProvider.notifier).add(entry);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DECRYPTION FAILED: WRONG KEY OR CORRUPT DATA')),
        );
      }
    }
  }

  void _showResult(String title, String desc, String content, {bool isSecure = false}) {
    final securityColors = Theme.of(context).securityColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ResultSheet(
        title: title,
        description: desc,
        shareText: content,
        icon: isSecure ? Icons.lock_open_rounded : Icons.qr_code_scanner_rounded,
        iconColor: isSecure ? securityColors.success : securityColors.info,
        onDone: () {},
        content: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DECODED_CONTENT',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white70,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              _TypingText(
                text: content,
                color: Colors.white,
                style: const TextStyle(fontFamily: 'Roboto Mono', fontSize: 14, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_isAuthenticating) {
      return Scaffold(
        backgroundColor: scheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuthenticated) {
      return Scaffold(
        appBar: SafeTextAppBar(
          title: 'QR VAULT',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: GridBackground(
          child: Center(
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
                    child: Icon(Icons.lock_outline_rounded, size: 36, color: scheme.primary),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'PIN REQUIRED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'SECURITY VERIFICATION IS REQUIRED TO ACCESS THE SECURE QR VAULT.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'AUTHENTICATE',
                    onPressed: _authenticate,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: SafeTextAppBar(
        title: 'QR VAULT',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: scheme.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 12),
          tabs: const [
            Tab(text: 'GENERATE'),
            Tab(text: 'SCAN'),
          ],
        ),
      ),
      body: GridBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildGenerator(scheme),
            _buildScanner(scheme),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerator(ColorScheme scheme) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.margin),
      children: [
        StepHeader(number: 1, title: 'INPUT DATA', isDone: _textController.text.isNotEmpty),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _textController,
          maxLines: 4,
          style: const TextStyle(fontFamily: 'Roboto Mono', fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: 'ENTER MESSAGE TO ENCODE...',
            suffixIcon: _textController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () => setState(() => _textController.clear()),
                  )
                : null,
            counterText: '${_textController.text.length} / 2000 CHARACTERS',
            counterStyle: const TextStyle(fontFamily: 'Roboto Mono', fontSize: 10, fontWeight: FontWeight.bold),
          ),
          onChanged: (v) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),
        StepHeader(number: 2, title: 'SECURITY OPTIONS', isDone: _isSecure),
        const SizedBox(height: AppSpacing.md),
        SwitchListTile(
          value: _isSecure,
          onChanged: (v) => setState(() => _isSecure = v),
          title: const Text('ENCRYPT QR CODE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          subtitle: const Text('REQUIRES PASSPHRASE TO SCAN', style: TextStyle(fontSize: 11)),
          tileColor: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            side: BorderSide(color: scheme.outline, width: 2),
          ),
        ),
        if (_isSecure) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _keyController,
            obscureText: true,
            style: const TextStyle(fontFamily: 'Roboto Mono', fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              labelText: 'PASSPHRASE',
              hintText: 'ENTER SECURE KEY...',
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        const StepHeader(number: 3, title: 'CUSTOMIZE QR', isDone: true),
        const SizedBox(height: AppSpacing.md),
        _buildCustomizer(scheme),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'GENERATE VAULT QR',
          loading: _isGenerating,
          onPressed: _generateQR,
        ),
        if (_generatedData.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Column(
              children: [
                Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: scheme.onSurface, width: 3),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: QrImageView(
                      data: _generatedData,
                      version: QrVersions.auto,
                      size: 200.0,
                      eyeStyle: QrEyeStyle(eyeShape: _eyeShape, color: _qrColor),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: _dataModuleShape,
                        color: _qrColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    SecondaryButton(
                      label: 'SHARE PNG',
                      icon: Icons.share_rounded,
                      onPressed: () async {
                        final image = await _screenshotController.capture();
                        if (image != null) {
                          final directory = await getTemporaryDirectory();
                          final imagePath = '${directory.path}/qr_vault_${DateTime.now().millisecondsSinceEpoch}.png';
                          final imageFile = await File(imagePath).create();
                          await imageFile.writeAsBytes(image);
                          Share.shareXFiles([XFile(imagePath)], text: 'SAFE-TEXT SECURE QR');
                        }
                      },
                    ),
                    SecondaryButton(
                      label: 'SHARE SVG',
                      icon: Icons.polyline_rounded,
                      onPressed: () {
                        ref.read(exportServiceProvider).shareQrSvg(
                          data: _generatedData,
                          color: _qrColor,
                          fileName: 'qr_vault_${DateTime.now().millisecondsSinceEpoch}',
                        );
                      },
                    ),
                    SecondaryButton(
                      label: 'SAVE',
                      icon: Icons.save_alt_rounded,
                      onPressed: () async {
                        final image = await _screenshotController.capture();
                        if (image != null) {
                          await ref.read(storageServiceProvider).saveToGallery(image, fileName: 'QR_VAULT');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('SAVED TO GALLERY')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCustomizer(ColorScheme scheme) {
    final securityColors = Theme.of(context).securityColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TEMPLATE PRESETS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _PresetOption(
                label: 'BRUTALIST',
                isSelected: _qrColor == Colors.black && _eyeShape == QrEyeShape.square && _dataModuleShape == QrDataModuleShape.square,
                onTap: () => setState(() {
                  _qrColor = Colors.black;
                  _eyeShape = QrEyeShape.square;
                  _dataModuleShape = QrDataModuleShape.square;
                }),
              ),
              const SizedBox(width: 8),
              _PresetOption(
                label: 'INDUSTRIAL',
                isSelected: _qrColor == securityColors.danger && _eyeShape == QrEyeShape.square && _dataModuleShape == QrDataModuleShape.square,
                onTap: () => setState(() {
                  _qrColor = securityColors.danger;
                  _eyeShape = QrEyeShape.square;
                  _dataModuleShape = QrDataModuleShape.square;
                }),
              ),
              const SizedBox(width: 8),
              _PresetOption(
                label: 'MATRIX',
                isSelected: _qrColor == securityColors.success && _eyeShape == QrEyeShape.square && _dataModuleShape == QrDataModuleShape.square,
                onTap: () => setState(() {
                  _qrColor = securityColors.success;
                  _eyeShape = QrEyeShape.square;
                  _dataModuleShape = QrDataModuleShape.square;
                }),
              ),
              const SizedBox(width: 8),
              _PresetOption(
                label: 'BLOODLINE',
                isSelected: _qrColor == securityColors.danger && _eyeShape == QrEyeShape.circle && _dataModuleShape == QrDataModuleShape.circle,
                onTap: () => setState(() {
                  _qrColor = securityColors.danger;
                  _eyeShape = QrEyeShape.circle;
                  _dataModuleShape = QrDataModuleShape.circle;
                }),
              ),
              const SizedBox(width: 8),
              _PresetOption(
                label: 'CYBER',
                isSelected: _qrColor == securityColors.info && _eyeShape == QrEyeShape.square && _dataModuleShape == QrDataModuleShape.circle,
                onTap: () => setState(() {
                  _qrColor = securityColors.info;
                  _eyeShape = QrEyeShape.square;
                  _dataModuleShape = QrDataModuleShape.circle;
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('QR COLOR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Row(
          children: [
            _ColorOption(
              color: Colors.black,
              isSelected: _qrColor == Colors.black,
              onTap: () => setState(() => _qrColor = Colors.black),
            ),
            const SizedBox(width: 8),
            _ColorOption(
              color: securityColors.danger,
              isSelected: _qrColor == securityColors.danger,
              onTap: () => setState(() => _qrColor = securityColors.danger),
            ),
            const SizedBox(width: 8),
            _ColorOption(
              color: securityColors.success,
              isSelected: _qrColor == securityColors.success,
              onTap: () => setState(() => _qrColor = securityColors.success),
            ),
            const SizedBox(width: 8),
            _ColorOption(
              color: securityColors.info,
              isSelected: _qrColor == securityColors.info,
              onTap: () => setState(() => _qrColor = securityColors.info),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('EYE SHAPE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Row(
          children: [
            _ShapeOption(
              label: 'SQUARE',
              isSelected: _eyeShape == QrEyeShape.square,
              onTap: () => setState(() => _eyeShape = QrEyeShape.square),
            ),
            const SizedBox(width: 8),
            _ShapeOption(
              label: 'CIRCLE',
              isSelected: _eyeShape == QrEyeShape.circle,
              onTap: () => setState(() => _eyeShape = QrEyeShape.circle),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('DATA MODULE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Row(
          children: [
            _ShapeOption(
              label: 'SQUARE',
              isSelected: _dataModuleShape == QrDataModuleShape.square,
              onTap: () => setState(() => _dataModuleShape = QrDataModuleShape.square),
            ),
            const SizedBox(width: 8),
            _ShapeOption(
              label: 'CIRCLE',
              isSelected: _dataModuleShape == QrDataModuleShape.circle,
              onTap: () => setState(() => _dataModuleShape = QrDataModuleShape.circle),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScanner(ColorScheme scheme) {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                _handleScan(barcode.rawValue!);
                break;
              }
            }
          },
        ),
        // Scanner Overlay
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: scheme.primary, width: 4),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Stack(
              children: [
                _ScanningLine(color: Colors.white),
              ],
            ),
          ),
        ),
        Positioned(
          top: 20,
          right: 20,
          child: Column(
            children: [
              _ScannerActionIcon(
                icon: Icons.flash_on_rounded,
                onTap: () => _scannerController.toggleTorch(),
              ),
              const SizedBox(height: 12),
              _ScannerActionIcon(
                icon: Icons.flip_camera_ios_rounded,
                onTap: () => _scannerController.switchCamera(),
              ),
              const SizedBox(height: 12),
              _ScannerActionIcon(
                icon: Icons.photo_library_rounded,
                onTap: () async {
                  try {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      final BarcodeCapture? capture = await _scannerController.analyzeImage(image.path);
                      if (capture != null && capture.barcodes.isNotEmpty) {
                        final data = capture.barcodes.first.rawValue;
                        if (data != null) {
                          _handleScan(data);
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('NO QR CODE FOUND IN IMAGE')),
                          );
                        }
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('ERROR SCANNING IMAGE: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'ALIGN QR CODE WITHIN FRAME',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorOption({required this.color, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: isSelected ? Icon(Icons.check, color: color == Colors.white ? Colors.black : Colors.white, size: 20) : null,
      ),
    );
  }
}

class _PresetOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary : scheme.surface,
          border: Border.all(color: scheme.outline, width: 2),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? scheme.onPrimary : scheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 10,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

class _ShapeOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ShapeOption({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.black : Colors.transparent,
            border: Border.all(color: AppColors.black, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.black,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScannerActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ScannerActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24, width: 1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _ScanningLine extends StatefulWidget {
  final Color color;
  const _ScanningLine({required this.color});

  @override
  State<_ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: _controller.value * 256,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}

class _TypingText extends StatefulWidget {
  final String text;
  final Color color;
  final TextStyle? style;

  const _TypingText({required this.text, required this.color, this.style});

  @override
  State<_TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<_TypingText> with SingleTickerProviderStateMixin {
  late String _displayText;
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _displayText = '';
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animateText();
  }

  @override
  void didUpdateWidget(_TypingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _animateText();
    }
  }

  void _animateText() {
    _displayText = '';
    if (widget.text.isEmpty) {
      setState(() {});
      return;
    }
    
    int charIndex = 0;
    _controller.repeat();
    
    Future.doWhile(() async {
      if (!mounted) return false;
      if (charIndex >= widget.text.length) {
        _controller.stop();
        return false;
      }
      
      setState(() {
        _displayText = widget.text.substring(0, charIndex + 1);
        charIndex++;
      });
      
      await Future.delayed(const Duration(milliseconds: 10));
      return true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: widget.style ?? TextStyle(
        fontFamily: 'Roboto Mono',
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: widget.color,
        height: 1.4,
      ),
    );
  }
}
