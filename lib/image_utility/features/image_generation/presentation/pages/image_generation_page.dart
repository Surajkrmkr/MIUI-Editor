import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miui_icon_generator/image_utility/features/image_generation/data/generators/image_generator.dart';
import 'package:miui_icon_generator/image_utility/features/image_generation/presentation/providers/generation_provider.dart';

class ImageGenerationPage extends ConsumerStatefulWidget {
  const ImageGenerationPage({super.key});

  @override
  ConsumerState<ImageGenerationPage> createState() =>
      _ImageGenerationPageState();
}

class _ImageGenerationPageState extends ConsumerState<ImageGenerationPage> {
  final _promptController = TextEditingController();
  ImageGenerator? _selectedGenerator;
  String? _selectedStyle;
  bool _upscaleEnabled = true;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<ImageGenerator> get _generators =>
      ref.read(generationNotifierProvider.notifier).buildGenerators();

  void _selectGenerator(ImageGenerator g) {
    setState(() {
      _selectedGenerator = g;
      _selectedStyle = null;
    });
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _generatePreview() async {
    final gen = _selectedGenerator;
    if (gen == null) {
      _showSnack('Please select a generator first.');
      return;
    }
    if (!gen.isConfigured) {
      _showSnack('${gen.displayName} API key not configured. Go to Settings.');
      return;
    }
    await ref.read(generationNotifierProvider.notifier).generatePreview(
          generator: gen,
          prompt: _promptController.text,
          style: _selectedStyle,
        );
  }

  Future<void> _approveAndSave() async {
    await ref.read(generationNotifierProvider.notifier).approveAndSave(
          prompt: _promptController.text,
          upscale: _upscaleEnabled,
        );
  }

  void _retry() {
    ref.read(generationNotifierProvider.notifier).reset();
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(generationNotifierProvider);
    final generators = _generators;

    // Initialise default generator lazily
    _selectedGenerator ??= generators.isNotEmpty ? generators.first : null;

    final isWorking = state.step == GenerationStep.generating ||
        state.step == GenerationStep.upscaling ||
        state.step == GenerationStep.saving;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Generate Wallpaper'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Banner ───────────────────────────────────────────────────
            _InfoBanner(),
            const SizedBox(height: 20),

            // ── Generator chips ───────────────────────────────────────────
            const _SectionLabel('Generator'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: generators.map((g) {
                final selected = _selectedGenerator?.id == g.id;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        g.id == 'gemini_imagen'
                            ? Icons.auto_awesome
                            : Icons.brush,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(g.displayName),
                      if (!g.isConfigured) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.lock, size: 14, color: Colors.orange),
                      ],
                    ],
                  ),
                  selected: selected,
                  onSelected: isWorking ? null : (_) => _selectGenerator(g),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Prompt ────────────────────────────────────────────────────
            const _SectionLabel('Prompt'),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              enabled: !isWorking,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'Describe the wallpaper you want…\nExample: A serene mountain lake at golden hour with dramatic pink clouds',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // ── Style chips ───────────────────────────────────────────────
            if (_selectedGenerator != null &&
                _selectedGenerator!.supportedStyles.isNotEmpty) ...[
              const _SectionLabel('Style (optional)'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _selectedGenerator!.supportedStyles.map((s) {
                  return ChoiceChip(
                    label: Text(s),
                    selected: _selectedStyle == s,
                    onSelected: isWorking
                        ? null
                        : (picked) =>
                            setState(() => _selectedStyle = picked ? s : null),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // ── Upscale toggle ────────────────────────────────────────────
            Card(
              child: SwitchListTile(
                title: const Text('Upscale with Upscayl AI'),
                subtitle: const Text(
                    '4× upscaling before saving (requires Upscayl API key)'),
                secondary: const Icon(Icons.hd),
                value: _upscaleEnabled,
                onChanged: isWorking
                    ? null
                    : (v) => setState(() => _upscaleEnabled = v),
              ),
            ),
            const SizedBox(height: 24),

            // ── Status / progress ─────────────────────────────────────────
            if (isWorking) _StatusRow(state.statusMessage ?? ''),

            // ── Error ─────────────────────────────────────────────────────
            if (state.step == GenerationStep.error)
              _ErrorCard(state.errorMessage ?? 'Unknown error',
                  onRetry: _retry),

            // ── Preview image ─────────────────────────────────────────────
            if (state.previewBytes != null &&
                state.step != GenerationStep.done) ...[
              const _SectionLabel('Preview'),
              const SizedBox(height: 8),
              _PhoneFrame(
                child: Image.memory(state.previewBytes!, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
              // Approve / reject row
              if (state.step == GenerationStep.awaitingApproval) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.replay),
                        label: const Text('Regenerate'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _approveAndSave,
                        icon: const Icon(Icons.check),
                        label:
                            Text(_upscaleEnabled ? 'Upscale & Save' : 'Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
            ],

            // ── Final saved image ──────────────────────────────────────────
            if (state.step == GenerationStep.done &&
                state.finalBytes != null) ...[
              _SuccessBanner(path: state.savedPath ?? ''),
              const SizedBox(height: 12),
              _PhoneFrame(
                child: Image.memory(state.finalBytes!, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Generate Another'),
              ),
              const SizedBox(height: 24),
            ],

            // ── Generate button (only when idle / error) ──────────────────
            if (state.step == GenerationStep.idle ||
                state.step == GenerationStep.error) ...[
              FilledButton.icon(
                onPressed: _generatePreview,
                icon: const Icon(Icons.auto_awesome),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child:
                      Text('Generate Preview', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Small reusable widgets ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall!
            .copyWith(fontWeight: FontWeight.bold),
      );
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.tips_and_updates,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '1. Enter a prompt  →  2. Generate preview  →  3. Approve  →  '
                '4. Upscale (optional) & save as 1080×2340 JPG',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String message;
  const _StatusRow(this.message);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Text(message,
                    style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard(this.message, {required this.onRetry});
  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.errorContainer,
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.error_outline,
                    color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 8),
                const Text('Generation failed',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 8),
              Text(message,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer)),
              const SizedBox(height: 8),
              OutlinedButton(
                  onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      );
}

class _SuccessBanner extends StatelessWidget {
  final String path;
  const _SuccessBanner({required this.path});
  @override
  Widget build(BuildContext context) => Card(
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Saved successfully!',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green)),
                  Text(path.split('/').last,
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ]),
        ),
      );
}

/// Renders children inside a phone-shaped frame (6:13 aspect ratio).
class _PhoneFrame extends StatelessWidget {
  final Widget child;
  const _PhoneFrame({required this.child});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.55,
        ),
        child: AspectRatio(
          aspectRatio: 6 / 13,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
