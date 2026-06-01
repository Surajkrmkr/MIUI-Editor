import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pro_workspace/pro_workspace_shell.dart';

class WorkspaceShell extends ConsumerWidget {
  const WorkspaceShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ProfessionalWorkspaceShell();
  }
}
