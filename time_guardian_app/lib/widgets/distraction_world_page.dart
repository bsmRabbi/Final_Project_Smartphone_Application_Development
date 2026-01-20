// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:time_guardian/home_page.dart';

class DistractionWorldPage extends StatefulWidget {
  const DistractionWorldPage({super.key});

  @override
  State<DistractionWorldPage> createState() => _DistractionWorldPageState();
}

class _DistractionWorldPageState extends State<DistractionWorldPage> {
  String currentWorld = "Distracted";

  int seconds = 0;
  Timer? timer;

  String? _sessionId;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    startTimer();
    _startSession();
  }

  Future<void> _startSession() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _startTime = DateTime.now();

    final response = await Supabase.instance.client
        .from('sessions')
        .insert({
          'user_id': user.id,
          'world_id': 'DISTRACTION_WORLD',
          'start_time': _startTime!.toIso8601String(),
        })
        .select()
        .single();

    _sessionId = response['id'];
  }

  Future<void> _endSession() async {
    if (_sessionId == null) return;

    await Supabase.instance.client
        .from('sessions')
        .update({'end_time': DateTime.now().toIso8601String()})
        .eq('id', _sessionId!);
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        seconds++;
      });
    });
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
  void dispose() {
    _endSession();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Distraction Mode"),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 117, 35, 43),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 83, 10, 17),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Column(
                  children: [
                    const Text(
                      "Distracted",
                      style: TextStyle(
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
              child: const Text("Back to Home", style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 5),
            Image.network(
              "https://www.timetackle.com/wp-content/uploads/2022/01/Blog-66_digital-distraction.jpg",
              height: 500,
              width: 500,
            ),
          ],
        ),
      ),
    );
  }
}
