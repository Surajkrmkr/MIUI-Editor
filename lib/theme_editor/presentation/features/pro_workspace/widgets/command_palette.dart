import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/theme_extensions.dart';

class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key});

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final _controller = TextEditingController();
  final List<String> _commands = [
    'Import Wallpaper',
    'Generate SVGs',
    'Generate Icons',
    'Pack MTZ',
    'Export Project',
    'Switch to Classic UI',
    'Reset Canvas Zoom',
    'Apply HyperOS Preset',
    'Apply Neon Preset',
    'Show Layers',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 500,
          height: 400,
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(120),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Type a command or search...',
                    hintStyle: TextStyle(color: colors.textDisabled),
                    prefixIcon: Icon(
                      Icons.keyboard_command_key_rounded,
                      color: colors.primary,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              Divider(height: 1, color: colors.border),

              // Command List
              Expanded(
                child: ListView.builder(
                  itemCount: _commands.length,
                  itemBuilder: (context, index) {
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.bolt_rounded,
                            size: 16, color: colors.textDisabled),
                        title: Text(
                          _commands[index],
                          style: TextStyle(
                              color: colors.textSecondary, fontSize: 12),
                        ),
                        trailing: Text(
                          'Ctrl+Enter',
                          style: TextStyle(
                              color: colors.textDisabled, fontSize: 9),
                        ),
                        onTap: () => Navigator.pop(context),
                      ),
                    );
                  },
                ),
              ),

              // Footer
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Text('↑↓ to navigate',
                        style: TextStyle(
                            color: colors.textDisabled, fontSize: 9)),
                    const SizedBox(width: 12),
                    Text('↵ to execute',
                        style: TextStyle(
                            color: colors.textDisabled, fontSize: 9)),
                    const SizedBox(width: 12),
                    Text('esc to close',
                        style: TextStyle(
                            color: colors.textDisabled, fontSize: 9)),
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

void showCommandPalette(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => const CommandPalette(),
  );
}
