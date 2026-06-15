import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/widgets/iphone_frame.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/element_widget.dart';
import '../../../providers/ai_provider.dart';
import '../preset/preset_thumbnail.dart';

// Phone thumbnail display constants
const _frameW = AppConstants.screenWidth + 26;
const _frameH = AppConstants.screenHeight + 16;
const _displayW = 110.0;
const _displayH = _frameH * _displayW / _frameW;
const _frameScale = _displayW / _frameW;

/// Three-phase dialog: input → loading → pick variant.
class AiGenerateDialog extends ConsumerStatefulWidget {
  const AiGenerateDialog({super.key});

  @override
  ConsumerState<AiGenerateDialog> createState() => _AiGenerateDialogState();
}

class _AiGenerateDialogState extends ConsumerState<AiGenerateDialog> {
  final _ctrl = TextEditingController();
  int _variantCount = 3;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _generate() {
    final prompt = _ctrl.text.trim();
    if (prompt.isEmpty) return;
    ref.read(aiProvider.notifier).generateVariants(prompt, _variantCount);
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiProvider);

    return PopScope(
      onPopInvokedWithResult: (_, __) =>
          ref.read(aiProvider.notifier).clearVariants(),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _buildPhase(context, aiState),
        ),
      ),
    );
  }

  Widget _buildPhase(BuildContext context, AiState state) {
    if (state.isLoading) return _LoadingPhase(count: _variantCount);
    if (state.hasVariants) {
      return _VariantsPhase(
        variants: state.variants,
        onApply: (v) {
          ref.read(aiProvider.notifier).applyVariant(v);
          Navigator.of(context).pop();
        },
        onRegenerate: () => ref
            .read(aiProvider.notifier)
            .generateVariants(_ctrl.text.trim(), _variantCount),
        onCancel: () {
          ref.read(aiProvider.notifier).clearVariants();
          Navigator.of(context).pop();
        },
      );
    }
    return _InputPhase(
      ctrl: _ctrl,
      variantCount: _variantCount,
      error: state.lastError,
      onCountChanged: (v) => setState(() => _variantCount = v),
      onGenerate: _generate,
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}

// ── Phase 1: Input ─────────────────────────────────────────────────────────────

class _InputPhase extends StatelessWidget {
  const _InputPhase({
    required this.ctrl,
    required this.variantCount,
    required this.error,
    required this.onCountChanged,
    required this.onGenerate,
    required this.onCancel,
  });

  final TextEditingController ctrl;
  final int variantCount;
  final String? error;
  final ValueChanged<int> onCountChanged;
  final VoidCallback onGenerate;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.tertiary],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  'AI Lockscreen Generator',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Prompt input
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Describe your lockscreen…\ne.g. "Minimal dark glass clock with weather"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onSubmitted: (_) => onGenerate(),
            ),

            const SizedBox(height: 16),

            // Variant count selector
            Row(
              children: [
                Text(
                  'Variants',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                ...List.generate(4, (i) {
                  final n = i + 1;
                  final selected = variantCount == n;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => onCountChanged(n),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? scheme.primary
                              : scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$n',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? scheme.onPrimary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),

            // Error
            if (error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        size: 14, color: scheme.onErrorContainer),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        error!,
                        style: TextStyle(
                            fontSize: 11, color: scheme.onErrorContainer),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                  label: const Text('Generate'),
                  onPressed: onGenerate,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Phase 2: Loading ───────────────────────────────────────────────────────────

class _LoadingPhase extends StatelessWidget {
  const _LoadingPhase({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 420,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Generating $count layout${count > 1 ? 's' : ''}…',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'AI is designing your lockscreen',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Phase 3: Variants picker ──────────────────────────────────────────────────

class _VariantsPhase extends StatelessWidget {
  const _VariantsPhase({
    required this.variants,
    required this.onApply,
    required this.onRegenerate,
    required this.onCancel,
  });

  final List<List<LockElement>> variants;
  final ValueChanged<List<LockElement>> onApply;
  final VoidCallback onRegenerate;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 180.0 + variants.length * (_displayW + 32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.tertiary],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${variants.length} Layout${variants.length > 1 ? 's' : ''} Generated',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    Text(
                      'Tap a layout to apply it to your canvas',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Phone thumbnails row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: variants.asMap().entries.map((entry) {
                  final i = entry.key;
                  final variant = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                        right: i < variants.length - 1 ? 16 : 0),
                    child: _VariantCard(
                      index: i + 1,
                      elements: variant,
                      onApply: () => onApply(variant),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Footer actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text('Regenerate'),
                  onPressed: onRegenerate,
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onCancel,
                  child: Text('Cancel',
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Variant card ───────────────────────────────────────────────────────────────

class _VariantCard extends StatefulWidget {
  const _VariantCard({
    required this.index,
    required this.elements,
    required this.onApply,
  });

  final int index;
  final List<LockElement> elements;
  final VoidCallback onApply;

  @override
  State<_VariantCard> createState() => _VariantCardState();
}

class _VariantCardState extends State<_VariantCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final phone = SizedBox(
      width: _displayW,
      height: _displayH,
      child: OverflowBox(
        alignment: Alignment.topLeft,
        maxWidth: _frameW,
        maxHeight: _frameH,
        child: Transform.scale(
          scale: _frameScale,
          alignment: Alignment.topLeft,
          child: IPhoneFrame(
            child: PresetThumbnail(
              elements: widget.elements,
              thumbnailWidth: AppConstants.screenWidth,
            ),
          ),
        ),
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onApply,
        child: AnimatedScale(
          scale: _hovering ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _hovering
                        ? scheme.primary
                        : scheme.outlineVariant.withAlpha(60),
                    width: _hovering ? 2 : 1,
                  ),
                  boxShadow: _hovering
                      ? [
                          BoxShadow(
                            color: scheme.primary.withAlpha(40),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: phone,
                ),
              ),
              const SizedBox(height: 10),
              AnimatedOpacity(
                opacity: _hovering ? 1.0 : 0.7,
                duration: const Duration(milliseconds: 150),
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 13),
                  label: Text('Use #${widget.index}'),
                  style: FilledButton.styleFrom(
                    textStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: const Size(_displayW, 32),
                    backgroundColor:
                        _hovering ? scheme.primary : scheme.primaryContainer,
                    foregroundColor: _hovering
                        ? scheme.onPrimary
                        : scheme.onPrimaryContainer,
                  ),
                  onPressed: widget.onApply,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
