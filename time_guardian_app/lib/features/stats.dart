// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:time_guardian/main.dart';

class Stats extends StatefulWidget {
  const Stats({
    super.key,
    required int focusSeconds,
    required int distractionSeconds,
    required int dailyFocusSeconds,
    required int dailyDistractionSeconds,
  });

  @override
  State<Stats> createState() => _StatsState();
}

class _StatsState extends State<Stats> {
  int dailyFocusSeconds = 0;
  int dailyDistractionSeconds = 0;
  int totalFocusSeconds = 0;
  int totalDistractionSeconds = 0;
  bool isLoading = true;

  String formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return hours > 0 ? "$hours h $minutes m" : "$minutes m";
  }

  @override
  void initState() {
    super.initState();
    fetchDailyTime();
    fetchTotalTime();
  }

  Future<void> fetchDailyTime() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final List<dynamic> sessions = await supabase
          .from('sessions')
          .select('start_time, end_time, world_id')
          .eq('user_id', user.id)
          .gte('start_time', startOfDay.toIso8601String())
          .lt('start_time', endOfDay.toIso8601String());

      int focus = 0;
      int distraction = 0;

      for (final s in sessions) {
        final startRaw = s['start_time'];
        final endRaw = s['end_time'];

        if (startRaw == null || endRaw == null) {
          // session still running → skip
          continue;
        }

        final start = DateTime.parse(startRaw);
        final end = DateTime.parse(endRaw);

        if (!end.isAfter(start)) continue;

        final duration = end.difference(start).inSeconds;

        if (s['world_id'] == 'FOCUS_WORLD') {
          focus += duration;
        } else if (s['world_id'] == 'DISTRACTION_WORLD') {
          distraction += duration;
        }
      }

      if (!mounted) return;

      setState(() {
        dailyFocusSeconds = focus;
        dailyDistractionSeconds = distraction;
      });
    } catch (e) {
      debugPrint("❌ Daily fetch error: $e");
    }
  }

  Future<void> fetchTotalTime() async {
    try {
      final data = await supabase.rpc('get_total_time_per_world');

      int focus = 0;
      int distraction = 0;

      for (final row in data) {
        if (row['world_id'] == 'FOCUS_WORLD') {
          focus = row['total_seconds'] ?? 0;
        } else if (row['world_id'] == 'DISTRACTION_WORLD') {
          distraction = row['total_seconds'] ?? 0;
        }
      }

      if (!mounted) return;

      setState(() {
        totalFocusSeconds = focus;
        totalDistractionSeconds = distraction;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching totals: $e");
    }
  }

  Widget buildStatBox(String title, int seconds, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 50),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatTime(seconds),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget dailyFeedbackBox() {
    bool doingGreat = dailyFocusSeconds > dailyDistractionSeconds;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: doingGreat
            ? Colors.green.withOpacity(0.15)
            : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: doingGreat ? Colors.green : Colors.red,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            doingGreat ? Icons.check_circle : Icons.warning_amber_rounded,
            color: doingGreat ? Colors.green : Colors.red,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              doingGreat
                  ? "You are doing great today 👏 \nKeep focusing!"
                  : "You are not up to the mark today \nTry to reduce distractions.",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: doingGreat ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget totalFeedbackBox() {
    bool doingGreat = totalFocusSeconds > totalDistractionSeconds;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: doingGreat
            ? Colors.green.withOpacity(0.15)
            : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: doingGreat ? Colors.green : Colors.red,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            doingGreat ? Icons.check_circle : Icons.warning_amber_rounded,
            color: doingGreat ? Colors.green : Colors.red,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              doingGreat
                  ? "You have been doing great 👏 \nKeep up the good work!"
                  : "You are falling behind \nTry to focus more.",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: doingGreat ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stats"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Today's Stats",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: buildStatBox(
                    "Focus",
                    dailyFocusSeconds,
                    const Color.fromARGB(255, 15, 95, 17),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: buildStatBox(
                    "Distraction",
                    dailyDistractionSeconds,
                    const Color.fromARGB(255, 110, 28, 22),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            dailyFeedbackBox(),

            const SizedBox(height: 30),

            const Text(
              "Total Stats",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: buildStatBox(
                    "Focus",
                    totalFocusSeconds,
                    const Color.fromARGB(255, 15, 95, 17),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: buildStatBox(
                    "Distraction",
                    totalDistractionSeconds,
                    const Color.fromARGB(255, 110, 28, 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            totalFeedbackBox(),
          ],
        ),
      ),
    );
  }
}
