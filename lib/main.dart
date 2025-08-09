import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Load the .env file (bundled as an asset in pubspec.yaml)
  await dotenv.load(fileName: '.env');

  // 2) Read values
  final url = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

  // 3) Basic validation so we fail loudly if misconfigured
  if (url == null || !url.startsWith('https://') || !url.endsWith('.supabase.co')) {
    throw Exception('Invalid or missing SUPABASE_URL. Check your .env and pubspec assets.');
  }
  if (anonKey == null || anonKey.isEmpty) {
    throw Exception('Missing SUPABASE_ANON_KEY. Check your .env and pubspec assets.');
  }

  // 4) Optional debug prints (safe/truncated)
  if (kDebugMode) {
    final safeKey = anonKey.length > 12
        ? '${anonKey.substring(0, 6)}...${anonKey.substring(anonKey.length - 6)}'
        : '<short>';
    debugPrint('Supabase URL: $url');
    debugPrint('Anon key: $safeKey');
  }

  // 5) Initialize Supabase
  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
  );

  runApp(GenesisApp(supabaseUrl: url));
}

class GenesisApp extends StatelessWidget {
  final String supabaseUrl;
  const GenesisApp({super.key, required this.supabaseUrl});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenesisOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: HomeScreen(supabaseUrl: supabaseUrl),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String supabaseUrl;
  const HomeScreen({super.key, required this.supabaseUrl});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _status = 'Waiting…';

  @override
  void initState() {
    super.initState();
    _quickSanity();
  }

  Future<void> _quickSanity() async {
    try {
      final client = Supabase.instance.client;
      final session = client.auth.currentSession; // may be null if not logged in
      setState(() {
        _status = 'Supabase ready ✅ | Session: ${session == null ? 'none' : 'active'}';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.supabaseUrl;
    return Scaffold(
      appBar: AppBar(title: const Text('GenesisOS')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Supabase is initialized', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('URL: $url', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 12),
            Text(_status),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _quickSanity,
              child: const Text('Re-check client'),
            ),
          ],
        ),
      ),
    );
  }
}
