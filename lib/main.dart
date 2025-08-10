import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Remove every kind of whitespace (spaces, tabs, newlines, NBSP, zero-width)
String sanitizeUrl(String input) {
  final s = (input)
      .replaceAll(RegExp(r'[\s\u00A0\u200B\u200C\u200D\uFEFF]'), '')
      .trim();
  if (s.isEmpty) return s;
  if (!s.startsWith('http')) return 'https://$s';
  return s;
}

/// Load config from --dart-define, then .env, with strict validation + fallback.
Future<Map<String, String>> loadSupabaseConfig() async {
  await dotenv.load(fileName: '.env', isOptional: true);

  var url = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  var key = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  if (url.isEmpty) url = dotenv.env['SUPABASE_URL'] ?? '';
  if (key.isEmpty) key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  url = sanitizeUrl(url);
  key = key.trim();

  // Fallback (prevents a bricked app if .env is malformed)
  if (url.isEmpty || key.isEmpty) {
    url = sanitizeUrl('https://pmxriyrzlkscisvgcjow.supabase.co');
    key =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBteHJpeXJ6bGtzY2lzdmdjam93Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3MjQ0OTcsImV4cCI6MjA2OTMwMDQ5N30.qfNPGiFJQN-wi5oKVYzMjEdFbrDcD7RRP0-_merMuFM';
  }

  final uri = Uri.tryParse(url);
  final good = uri != null &&
      uri.scheme == 'https' &&
      uri.host.isNotEmpty &&
      uri.host.endsWith('.supabase.co');

  if (!good) {
    throw Exception('Bad SUPABASE_URL after sanitize: "$url"');
  }

  assert(() {
    final codes = url.codeUnits.map((c) => '0x${c.toRadixString(16)}').join(' ');
    debugPrint('Supabase URL -> $url ($codes)');
    return true;
  }());

  return {'url': url, 'key': key};
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cfg = await loadSupabaseConfig();
  await Supabase.initialize(url: cfg['url']!, anonKey: cfg['key']!);

  final prefs = await SharedPreferences.getInstance();
  final dark = prefs.getBool('darkMode') ?? false;

  runApp(GenesisApp(initialDarkMode: dark));
}

/* ============================= APP & THEME ============================= */

class GenesisApp extends StatefulWidget {
  final bool initialDarkMode;
  const GenesisApp({super.key, required this.initialDarkMode});

  @override
  State<GenesisApp> createState() => _GenesisAppState();
}

class _GenesisAppState extends State<GenesisApp> {
  late bool _dark = widget.initialDarkMode;

  Future<void> _toggleTheme() async {
    setState(() => _dark = !_dark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenesisOS',
      debugShowCheckedModeBanner: false,
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: AuthGate(onToggleTheme: _toggleTheme, dark: _dark),
    );
  }
}

/* ============================== AUTH GATE ============================== */

class AuthGate extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool dark;
  const AuthGate({super.key, required this.onToggleTheme, required this.dark});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    return session == null
        ? AuthScreen(onToggleTheme: widget.onToggleTheme, dark: widget.dark)
        : AppShell(onToggleTheme: widget.onToggleTheme, dark: widget.dark);
  }
}

/* ============================== AUTH SCREENS ============================== */

class AuthScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool dark;
  const AuthScreen({super.key, required this.onToggleTheme, required this.dark});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GenesisOS — Authenticate'),
        actions: [
          IconButton(
            tooltip: 'Toggle dark mode',
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.dark ? Icons.dark_mode : Icons.light_mode),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Sign in'),
            Tab(text: 'Create account'),
            Tab(text: 'Forgot password'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [_SignInView(), _SignUpView(), _ForgotPasswordView()],
      ),
    );
  }
}

class _SignInView extends StatefulWidget {
  const _SignInView();
  @override
  State<_SignInView> createState() => _SignInViewState();
}
class _SignInViewState extends State<_SignInView> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed in ✅')));
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 12),
        TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
        const SizedBox(height: 20),
        FilledButton(onPressed: _loading ? null : _signIn, child: _loading ? const CircularProgressIndicator() : const Text('Sign in')),
      ]),
    );
  }
}

class _SignUpView extends StatefulWidget {
  const _SignUpView();
  @override
  State<_SignUpView> createState() => _SignUpViewState();
}
class _SignUpViewState extends State<_SignUpView> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _signUp() async {
    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      if (res.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created. Sign in now.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check your email to confirm.')));
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 12),
        TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
        const SizedBox(height: 20),
        FilledButton(onPressed: _loading ? null : _signUp, child: _loading ? const CircularProgressIndicator() : const Text('Create account')),
      ]),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();
  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}
class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _email = TextEditingController();
  bool _sending = false;

  @override void dispose() { _email.dispose(); super.dispose(); }

  Future<void> _sendReset() async {
    setState(() => _sending = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(_email.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset email sent. Check your inbox.')));
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 16),
        FilledButton(onPressed: _sending ? null : _sendReset, child: _sending ? const CircularProgressIndicator() : const Text('Send reset email')),
        const SizedBox(height: 16),
        const Text('Note: In-app reset (deep link) can be added later.'),
      ]),
    );
  }
}

/* ============================== APP SHELL ============================== */

class AppShell extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool dark;
  const AppShell({super.key, required this.onToggleTheme, required this.dark});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [ScrollsPage(onToggleTheme: widget.onToggleTheme, dark: widget.dark), const LinksPage(), const AccountPage()];
    final titles = ['Scrolls', 'Links', 'Account'];
    return Scaffold(
      appBar: AppBar(
        title: Text('GenesisOS — ${titles[_index]}'),
        actions: [
          IconButton(
            tooltip: 'Toggle dark mode',
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.dark ? Icons.dark_mode : Icons.light_mode),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Scrolls'),
          NavigationDestination(icon: Icon(Icons.link_outlined), selectedIcon: Icon(Icons.link), label: 'Links'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}

/* ============================== SCROLLS PAGE ============================== */

enum ScrollSort { dateDesc, titleAsc, favoritesFirst }

class ScrollsPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool dark;
  const ScrollsPage({super.key, required this.onToggleTheme, required this.dark});
  @override
  State<ScrollsPage> createState() => _ScrollsPageState();
}

class _ScrollsPageState extends State<ScrollsPage> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  bool _saving = false;
  ScrollSort _sort = ScrollSort.dateDesc;

  /// IDs hidden locally to avoid Dismissible assert until the realtime stream updates.
  final Set<String> _locallyHidden = <String>{};

  @override void dispose() { _title.dispose(); _content.dispose(); super.dispose(); }

  Stream<List<Map<String, dynamic>>> _stream() {
    final user = Supabase.instance.client.auth.currentUser!;
    final base = Supabase.instance.client
        .from('scrolls')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id);

    switch (_sort) {
      case ScrollSort.dateDesc:
        return base.order('created_at', ascending: false);
      case ScrollSort.titleAsc:
        return base.order('title', ascending: true);
      case ScrollSort.favoritesFirst:
        return base.order('is_favorite', ascending: false).order('created_at', ascending: false);
    }
  }

  Future<void> _save() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    if (_title.text.trim().isEmpty || _content.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and content are required.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.from('scrolls').insert({
        'user_id': user.id,
        'title': _title.text.trim(),
        'content': _content.text.trim(),
      });
      _title.clear();
      _content.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved ✅')));
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleFavorite(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    final current = (row['is_favorite'] ?? false) as bool;
    try {
      await Supabase.instance.client.from('scrolls').update({'is_favorite': !current}).eq('id', id);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fav error: ${e.message}')));
    }
  }

  /// Use confirmDismiss + local hide to prevent "dismissed widget still in tree"
  Future<bool> _confirmDelete(Map<String, dynamic> row) async {
    final id = row['id'] as String;

    // Optimistically hide locally so the next build doesn't include it.
    setState(() => _locallyHidden.add(id));

    try {
      await Supabase.instance.client.from('scrolls').delete().eq('id', id);

      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              // Unhide locally and reinsert
              setState(() => _locallyHidden.remove(id));
              final data = {
                'id': row['id'],
                'user_id': row['user_id'],
                'title': row['title'],
                'content': row['content'],
                'created_at': row['created_at'],
                'is_favorite': row['is_favorite'] ?? false,
              };
              try {
                await Supabase.instance.client.from('scrolls').insert(data);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Undo failed: $e')));
              }
            },
          ),
          duration: const Duration(seconds: 5),
        ),
      );

      return true; // proceed with dismiss animation
    } on PostgrestException catch (e) {
      // If delete failed, unhide and cancel dismiss
      setState(() => _locallyHidden.remove(id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete error: ${e.message}')));
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 8),
          TextField(
            controller: _content,
            minLines: 3,
            maxLines: 7,
            decoration: const InputDecoration(labelText: 'Content (Markdown supported)'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const CircularProgressIndicator() : const Text('Save scroll'),
              ),
              const Spacer(),
              PopupMenuButton<ScrollSort>(
                tooltip: 'Sort',
                initialValue: _sort,
                onSelected: (v) => setState(() => _sort = v),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: ScrollSort.dateDesc, child: Text('Sort: Date (newest)')),
                  PopupMenuItem(value: ScrollSort.titleAsc, child: Text('Sort: Title (A–Z)')),
                  PopupMenuItem(value: ScrollSort.favoritesFirst, child: Text('Sort: Favorites first')),
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
              stream: _stream(),
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                // Filter out any rows we locally hid (optimistic remove)
                final rows = snap.data!
                    .where((r) => !_locallyHidden.contains(r['id'] as String))
                    .toList();
                if (rows.isEmpty) return const Center(child: Text('No scrolls yet. Create your first one.'));
                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = rows[i];
                    final fav = (r['is_favorite'] ?? false) as bool;
                    return Dismissible(
                      key: ValueKey(r['id'] as String),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) => _confirmDelete(r),
                      child: ListTile(
                        title: Text(r['title'] ?? ''),
                        subtitle: Text(
                          (r['content'] ?? '').toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          tooltip: fav ? 'Unfavorite' : 'Favorite',
                          icon: Icon(fav ? Icons.star : Icons.star_border),
                          onPressed: () => _toggleFavorite(r),
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ScrollDetailPage(row: r)),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================== DETAIL (MARKDOWN) =========================== */

class ScrollDetailPage extends StatelessWidget {
  final Map<String, dynamic> row;
  const ScrollDetailPage({super.key, required this.row});

  @override
  Widget build(BuildContext context) {
    final title = (row['title'] ?? '').toString();
    final content = (row['content'] ?? '').toString();
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Markdown(data: content, padding: const EdgeInsets.all(16)),
    );
  }
}

/* ================================ LINKS PAGE ================================ */

const appLinks = {
  'TikTok': 'https://www.tiktok.com/@your_handle',
  'Facebook': 'https://facebook.com/your_page',
  'WhatsApp Group': 'https://chat.whatsapp.com/your_invite',
  'Website': 'https://your-domain.com',
};

class LinksPage extends StatelessWidget {
  const LinksPage({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: appLinks.entries
          .map((e) => ListTile(
                leading: const Icon(Icons.link),
                title: Text(e.key),
                subtitle: Text(e.value, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                onTap: () => _open(e.value),
              ))
          .toList(),
    );
  }
}

/* ================================ ACCOUNT PAGE ================================ */

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Email: ${user?.email ?? '-'}', style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 24),
        FilledButton.tonal(
          onPressed: () async => Supabase.instance.client.auth.signOut(),
          child: const Text('Sign out'),
        ),
      ]),
    );
  }
}
