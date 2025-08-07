import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animations/animations.dart';

import 'add_scroll_page.dart';
import 'edit_scroll_page.dart';
import 'login_page.dart';
import 'main.dart'; // for themeNotifier

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final search = TextEditingController();
  String query = '';
  String sort = 'date'; // or 'title'

  Future<List<dynamic>> _fetch() => Supabase.instance.client
      .from('scrolls')
      .select()
      .order('created_at', ascending: false);

  List<dynamic> _applyFilters(List<dynamic> rows) {
    final filtered = query.isEmpty
        ? rows
        : rows.where((r) {
            final t = (r['title'] as String).toLowerCase();
            final c = (r['content'] as String).toLowerCase();
            return t.contains(query) || c.contains(query);
          }).toList();

    if (sort == 'title') {
      filtered.sort((a, b) =>
          (a['title'] as String).compareTo((b['title'] as String)));
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Scrolls'),
        actions: [
          // theme toggle
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              themeNotifier.value = themeNotifier.value == ThemeMode.light
                  ? ThemeMode.dark
                  : ThemeMode.light;
            },
          ),
          // log-out button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                // optional immediate nav; AuthGate will also catch this
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false,
                );
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(86),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: search,
                  decoration: const InputDecoration(
                      hintText: 'Search…',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.search)),
                  onChanged: (v) => setState(() => query = v.toLowerCase()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DropdownButton<String>(
                  value: sort,
                  onChanged: (v) => setState(() => sort = v!),
                  items: const [
                    DropdownMenuItem(value: 'date', child: Text('Sort by date')),
                    DropdownMenuItem(value: 'title', child: Text('Sort by title')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddScrollPage()),
          );
          setState(() {}); // refresh after adding
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _fetch(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = _applyFilters(snap.data!);
          if (rows.isEmpty) {
            return const Center(child: Text('Nothing here'));
          }
          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, i) {
              final row = rows[i];
              return OpenContainer(
                closedElevation: 0,
                openBuilder: (_, __) => EditScrollPage(scroll: row),
                closedBuilder: (_, open) => ListTile(
                  title: Text(row['title']),
                  subtitle: Text(row['content']),
                  trailing:
                      Text(row['created_at'].toString().substring(0, 10)),
                  onTap: open,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
