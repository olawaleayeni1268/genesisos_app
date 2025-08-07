import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddScrollPage extends StatefulWidget {
  const AddScrollPage({super.key});

  @override
  State<AddScrollPage> createState() => _AddScrollPageState();
}

class _AddScrollPageState extends State<AddScrollPage> {
  final title = TextEditingController();
  final content = TextEditingController();
  bool saving = false;

  Future<void> _save() async {
    setState(() => saving = true);
    final uid = Supabase.instance.client.auth.currentUser!.id;

    await Supabase.instance.client.from('scrolls').insert({
      'user_id': uid,
      'title': title.text,
      'content': content.text,
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Scroll')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: content, decoration: const InputDecoration(labelText: 'Content'), maxLines: 5),
            const SizedBox(height: 20),
            saving
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
