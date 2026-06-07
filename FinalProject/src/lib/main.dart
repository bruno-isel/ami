import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'routes.dart';
import 'screens/my_tasks_screen.dart';
import 'screens/task_detail_screen.dart';
import 'screens/confirm_task_screen.dart';
import 'screens/voice_input_screen.dart';
import 'screens/task_created_screen.dart';
import 'screens/my_lists_screen.dart';
import 'utils/constants.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const VoiceTaskApp(),
    ),
  );
}

class VoiceTaskApp extends StatelessWidget {
  const VoiceTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoiceTask',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryBlue),
        useMaterial3: true,
      ),
      initialRoute: Routes.myTasks,
      routes: {
        Routes.myTasks: (_) => const MyTasksScreen(),
        Routes.taskDetail: (ctx) {
          final id = ModalRoute.of(ctx)!.settings.arguments as String;
          return TaskDetailScreen(taskId: id);
        },
        Routes.voiceInput: (_) => const VoiceInputScreen(),
        Routes.confirmTask: (_) => const ConfirmTaskScreen(),
        Routes.taskCreated: (_) => const TaskCreatedScreen(),
        Routes.myLists: (_) => const MyListsScreen(),
      },
    );
  }
}
