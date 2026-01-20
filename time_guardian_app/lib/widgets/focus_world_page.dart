// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:time_guardian/home_page.dart';

class FocusWorldPage extends StatefulWidget {
  const FocusWorldPage({super.key});

  @override
  State<FocusWorldPage> createState() => _FocusWorldPageState();
}

class _FocusWorldPageState extends State<FocusWorldPage> {
  String currentWorld = "Focusing";
  Timer? timer;
  int seconds = 0;

  String? _sessionId;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    await _startSession();
    startTimer();
  }

  Future<void> _startSession() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _startTime = DateTime.now();

    final response = await Supabase.instance.client
        .from('sessions')
        .insert({
          'user_id': user.id,
          'world_id': 'FOCUS_WORLD',
          'start_time': _startTime!.toIso8601String(),
        })
        .select()
        .single();

    _sessionId = response['id'];
  }

  Future<void> endSession() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null || _sessionId == null) {
      debugPrint("❌ Cannot end session: missing user or sessionId");
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('sessions')
          .update({'end_time': DateTime.now().toIso8601String()})
          .eq('id', _sessionId!)
          .select()
          .single();

      debugPrint("✅ Session ended: ${response['id']}");
    } catch (e) {
      debugPrint("❌ Failed to end session: $e");
    }
  }

  Future<void> _endSession() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _sessionId == null) return;

    await Supabase.instance.client
        .from('sessions')
        .update({'end_time': DateTime.now().toIso8601String()})
        .eq('id', _sessionId!);
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => seconds++);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _endSession();
    super.dispose();
  }

  String formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    return "${hours.toString().padLeft(2, '0')}:"
        "${minutes.toString().padLeft(2, '0')}:"
        "${secs.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final isFocus = currentWorld == "Focusing";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Focus Mode"),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 31, 116, 66),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isFocus ? const Color(0xFF224623) : Colors.red.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      currentWorld,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      formatTime(seconds),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                await _endSession();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => HomePage()),
                );
              },
              child: const Text("Back to Home"),
            ),
            const SizedBox(height: 1),
            Image.network(
              "https://static.vecteezy.com/system/resources/previews/024/775/553/non_2x/stay-focused-concept-working-man-with-goals-schedule-and-new-mail-work-in-focus-productivity-self-discipline-achievement-of-objectives-illustration-for-web-design-banners-ui-vector.jpg",
              height: 500,
              width: 500,
            ),
          ],
        ),
      ),
    );
  }
}
