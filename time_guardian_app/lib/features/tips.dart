import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TipsPage extends StatelessWidget {
  const TipsPage({super.key});

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  Widget _tipCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent.withAlpha(30),
          child: Icon(icon, color: Colors.blueAccent),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(description),
        ),
        trailing: const Icon(Icons.open_in_new),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study & Time Management'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Improve Your Focus",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Hand-picked resources to help you manage time, reduce distraction, and study effectively.",
              style: TextStyle(
                fontSize: 16,
                color: Color.fromARGB(136, 236, 234, 234),
              ),
            ),

            const SizedBox(height: 24),

            _tipCard(
              title: "Time Blocking",
              description:
                  "Plan your day by assigning specific time blocks to tasks.",
              icon: Icons.block,
              onTap: () => _openLink(
                "https://www.timely.com/blog/4-time-blocking-techniques",
              ),
            ),

            _tipCard(
              title: "Deep Work",
              description:
                  "Eliminate distractions and focus deeply on cognitively demanding tasks.",
              icon: Icons.psychology,
              onTap: () =>
                  _openLink("https://www.todoist.com/inspiration/deep-work"),
            ),

            _tipCard(
              title: "Avoid Multitasking",
              description:
                  "Single-tasking improves accuracy, speed, and mental clarity.",
              icon: Icons.headset,
              onTap: () =>
                  _openLink("https://www.apa.org/research/action/multitask"),
            ),

            _tipCard(
              title: "Plan Tomorrow Today",
              description:
                  "End your day by planning the next one to reduce mental load.",
              icon: Icons.checklist,
              onTap: () => _openLink("https://jamesclear.com/daily-routines"),
            ),

            _tipCard(
              title: "Pomodoro Technique",
              description:
                  "Work in focused 25-minute sessions followed by short breaks.",
              icon: Icons.timer,
              onTap: () => _openLink(
                "https://todoist.com/productivity-methods/pomodoro-technique",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
