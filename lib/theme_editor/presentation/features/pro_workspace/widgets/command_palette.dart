import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/app_theme.dart';

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
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 500,
          height: 400,
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 40, offset: const Offset(0, 20)),
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
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Type a command or search...',
                    hintStyle: TextStyle(color: Colors.white24),
                    prefixIcon: Icon(Icons.keyboard_command_key_rounded, color: AppTheme.accent),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const Divider(height: 1, color: Colors.white10),
              
              // Command List
              Expanded(
                child: ListView.builder(
                  itemCount: _commands.length,
                  itemBuilder: (context, index) {
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.bolt_rounded, size: 16, color: Colors.white24),
                        title: Text(_commands[index], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        trailing: const Text('Ctrl+Enter', style: TextStyle(color: Colors.white10, fontSize: 9)),
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
                decoration: const BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                ),
                child: const Row(
                  children: [
                    Text('↑↓ to navigate', style: TextStyle(color: Colors.white10, fontSize: 9)),
                    SizedBox(width: 12),
                    Text('↵ to execute', style: TextStyle(color: Colors.white10, fontSize: 9)),
                    SizedBox(width: 12),
                    Text('esc to close', style: TextStyle(color: Colors.white10, fontSize: 9)),
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
