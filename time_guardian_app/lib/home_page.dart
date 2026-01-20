// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:time_guardian/features/stats.dart';
import 'package:time_guardian/main.dart';
import 'features/profile.dart';
import 'features/tips.dart';
import 'widgets/focus_world_page.dart';
import 'widgets/distraction_world_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  int focusSeconds = 0;
  int distractionSeconds = 0;
  bool isLoading = true;

  int todayFocusSeconds = 0;
  int todayDistractionSeconds = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    fetchTotalTime();
    fetchTodayTime();
  }

  String formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return hours > 0 ? "$hours h $minutes m" : "$minutes m";
  }

  Future<void> fetchTodayTime() async {
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
        todayFocusSeconds = focus;
        todayDistractionSeconds = distraction;
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
        focusSeconds = focus;
        distractionSeconds = distraction;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching totals: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Time Guardian"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Text(
                "Menu",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text("Stats"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Stats(
                      focusSeconds: focusSeconds,
                      distractionSeconds: distractionSeconds,
                      dailyFocusSeconds: todayFocusSeconds,
                      dailyDistractionSeconds: todayDistractionSeconds,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb),
              title: const Text("Tips"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TipsPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Text(
              "Choose a mode to enter",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 60),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FocusWorldPage()),
                );
              },
              child: const Text(
                "Enter Focus Mode",
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 60),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DistractionWorldPage(),
                  ),
                );
              },
              child: const Text(
                "Enter Distraction Mode",
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 150),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: 200,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Today's Focus",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatTime(todayFocusSeconds),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 200,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Today's Distraction",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatTime(todayDistractionSeconds),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: 200,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 136, 172, 189),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Total Focus",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatTime(focusSeconds),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 200,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 136, 172, 189),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Total Distraction",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatTime(distractionSeconds),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                await fetchTotalTime();
                await fetchTodayTime();
                context.showSnackBar("Stats refreshed successfully!");
              },
              child: const Text("Refresh Stats"),
            ),
          ],
        ),
      ),
    );
  }
}
