// lib/main.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---- Supabase init (no persistSession; it's automatic in 2.8+) ----
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: const AuthClientOptions(
      autoRefreshToken: true,
      // For web builds you can add: authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const GenesisApp());
}

class GenesisApp extends StatefulWidget {
  const GenesisApp({super.key});

  @override
  State<GenesisApp> createState() => _GenesisAppState();
}

class _GenesisAppState extends State<GenesisApp> {
  ThemeMode _mode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenesisOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: _mode,
      home: AuthGate(onToggleTheme: _toggleTheme),
    );
  }
}

/// Watches Supabase auth state and shows Login or App.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.onToggleTheme});
  final VoidCallback onToggleTheme;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _sub;
  Session? _session = Supabase.instance.client.auth.currentSession;

  @override
  void initState() {
    super.initState();
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      setState(() {
        _session = event.session;
      });
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _session ?? Supabase.instance.client.auth.currentSession;
    if (session == null) {
      return LoginPage(onToggleTheme: widget.onToggleTheme);
    }
    return ScrollsPage(onToggleTheme: widget.onToggleTheme);
  }
}

// --------------------------- Login Page ---------------------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onToggleTheme});
  final VoidCallback onToggleTheme;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in ✅')),
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signUp() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Sign-up email sent (check inbox / spam) ✉️')),
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _email.text.trim(),
        // For mobile you can omit redirectTo; for web you’d use your site URL
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent ✉️')),
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = Env.supabaseUrl;
    return Scaffold(
      appBar: AppBar(
        title: const Text('GenesisOS • Sign in'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: widget.onToggleTheme,
            icon: const Icon(Icons.brightness_6),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Supabase URL -> $url',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _signIn,
            child:
                _busy ? const CircularProgressIndicator() : const Text('Sign in'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(onPressed: _busy ? null : _signUp, child: const Text('Create account')),
              const SizedBox(width: 12),
              TextButton(onPressed: _busy ? null : _resetPassword, child: const Text('Forgot password')),
            ],
          ),
        ],
      ),
    );
  }
}

// --------------------------- Scrolls Page ---------------------------

enum ScrollSort { dateDesc, titleAsc, favoritesFirst }

class ScrollsPage extends StatefulWidget {
  const ScrollsPage({super.key, required this.onToggleTheme});
  final VoidCallback onToggleTheme;

  @override
  State<ScrollsPage> createState() => _ScrollsPageState();
}

class _ScrollsPageState extends State<ScrollsPage> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  bool _saving = false;
  ScrollSort _sort = ScrollSort.dateDesc;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final content = _content.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content are required.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      await Supabase.instance.client.from('scrolls').insert({
        'user_id': user.id,
        'title': title,
        'content': content,
        'is_favorite': false,
      });
      _title.clear();
      _content.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved ✅')),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleFavorite(String id, bool current) async {
    try {
      await Supabase.instance.client
          .from('scrolls')
          .update({'is_favorite': !current}).eq('id', id);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fav error: ${e.message}')));
    }
  }

  Future<bool> _deleteWithUndo(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    try {
      // Delete first (stream will drop it), but offer undo.
      await Supabase.instance.client.from('scrolls').delete().eq('id', id);

      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              final data = Map<String, dynamic>.from(row);
              data.remove('id'); // let DB reassign id on reinsert
              try {
                await Supabase.instance.client.from('scrolls').insert(data);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Undo failed: $e')),
                );
              }
            },
          ),
        ),
      );
      return true;
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete error: ${e.message}')),
        );
      }
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> _streamScrolls() {
    final user = Supabase.instance.client.auth.currentUser!;
    final query = Supabase.instance.client
        .from('scrolls')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id);
    // Sorting is applied in-memory below so the undo behavior is smoother.
    return query;
  }

  List<Map<String, dynamic>> _applySort(List<Map<String, dynamic>> rows) {
    final list = List<Map<String, dynamic>>.from(rows);
    switch (_sort) {
      case ScrollSort.dateDesc:
        list.sort((a, b) =>
            DateTime.parse(b['created_at'] as String)
                .compareTo(DateTime.parse(a['created_at'] as String)));
        break;
      case ScrollSort.titleAsc:
        list.sort((a, b) =>
            (a['title'] as String).toLowerCase().compareTo((b['title'] as String).toLowerCase()));
        break;
      case ScrollSort.favoritesFirst:
        list.sort((a, b) {
          final fa = (a['is_favorite'] as bool?) ?? false;
          final fb = (b['is_favorite'] as bool?) ?? false;
          if (fa == fb) {
            // secondary sort by date desc
            return DateTime.parse(b['created_at'] as String)
                .compareTo(DateTime.parse(a['created_at'] as String));
          }
          return fb ? 1 : -1; // true first
        });
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GenesisOS • Scrolls'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: widget.onToggleTheme,
            icon: const Icon(Icons.brightness_6),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _title,
              decoration:
                  const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _content,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Content (Markdown supported later)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator())
                      : const Text('Save scroll'),
                ),
                const Spacer(),
                PopupMenuButton<ScrollSort>(
                  initialValue: _sort,
                  onSelected: (v) => setState(() => _sort = v),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: ScrollSort.dateDesc,
                      child: Text('Sort: Date (newest)'),
                    ),
                    PopupMenuItem(
                      value: ScrollSort.titleAsc,
                      child: Text('Sort: Title (A–Z)'),
                    ),
                    PopupMenuItem(
                      value: ScrollSort.favoritesFirst,
                      child: Text('Sort: Favorites first'),
                    ),
                  ],
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.sort),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _streamScrolls(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final rows = _applySort(snap.data!);
                  if (rows.isEmpty) {
                    return const Center(
                        child: Text('No scrolls yet. Create your first one.'));
                  }
                  return ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      final id = row['id'] as String;
                      final title = (row['title'] as String?) ?? '';
                      final content = (row['content'] as String?) ?? '';
                      final fav = (row['is_favorite'] as bool?) ?? false;

                      return Dismissible(
                        key: ValueKey(id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _deleteWithUndo(row),
                        child: ListTile(
                          title: Text(title),
                          subtitle: Text(
                            content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: Icon(fav ? Icons.star : Icons.star_border),
                            onPressed: () => _toggleFavorite(id, fav),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
