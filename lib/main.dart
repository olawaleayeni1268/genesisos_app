import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

/// A minimal, safe entry that:
/// - Initializes Supabase using values injected via --dart-define (CI secrets)
/// - Shows a simple auth gate: Sign in / Create account / Sign out
/// - Persists the session across app restarts (FlutterAuthClientOptions)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      persistSession: true,
      autoRefreshToken: true,
    ),
  );

  // Simple visibility check in logs (won't print your key)
  // If this prints empty at runtime, your APK was built without the defines.
  // Re-check your GitHub Secrets and workflow step.
  // ignore: avoid_print
  print('SUPABASE_URL at runtime: "${Env.supabaseUrl}"');

  runApp(const GenesisApp());
}

class GenesisApp extends StatelessWidget {
  const GenesisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenesisOS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Session? _session;
  late final Stream<AuthState> _authStream;
  late final SupabaseClient _supabase;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _session = _supabase.auth.currentSession;
    _authStream = _supabase.auth.onAuthStateChange;
    _authStream.listen((authState) {
      setState(() => _session = authState.session);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (Env.supabaseUrl.isEmpty || Env.supabaseAnonKey.isEmpty) {
      return _BuildProblem(
        title: 'Missing Supabase config',
        message:
            'Your build does not contain SUPABASE_URL / SUPABASE_ANON_KEY.\n\n'
            'If this is a release APK from GitHub Actions, set the two repo '
            'secrets and ensure the workflow passes them via --dart-define.',
        details: Env.supabaseUrl.isEmpty
            ? 'SUPABASE_URL was empty at runtime.'
            : 'SUPABASE_ANON_KEY was empty at runtime.',
      );
    }

    if (_session == null) {
      return const SignInPage();
    }
    return const HomePage();
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_email.text.isEmpty || _password.text.isEmpty) {
      _snack('Enter email and password');
      return;
    }
    setState(() => _loading = true);
    try {
      await _supabase.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      // AuthGate will rebuild from the auth stream
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Sign in error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    if (_email.text.isEmpty || _password.text.isEmpty) {
      _snack('Enter email and password');
      return;
    }
    setState(() => _loading = true);
    try {
      await _supabase.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
      );
      _snack('Account created. You are now signed in.');
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Sign up error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GenesisOS — Sign in')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Connect to Supabase',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Env.supabaseUrl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.username, AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loading ? null : _signIn,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign in'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading ? null : _signUp,
                    child: const Text('Create account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('GenesisOS — Home'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await _supabase.auth.signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Signed out')));
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Supabase ready ✅',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  user != null ? 'You are signed in as ${user.email}' : 'No session',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  'URL: ${Env.supabaseUrl}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BuildProblem extends StatelessWidget {
  const _BuildProblem({
    required this.title,
    required this.message,
    required this.details,
  });

  final String title;
  final String message;
  final String details;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GenesisOS — Config issue')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontSize: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(height: 8),
                      Text(message, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(details,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
