import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditScrollPage extends StatefulWidget {
  final Map<String, dynamic> scroll;
  const EditScrollPage({super.key, required this.scroll});

  @override
  State<EditScrollPage> createState() => _EditScrollPageState();
}

class _EditScrollPageState extends State<EditScrollPage> {
  late final title = TextEditingController(text: widget.scroll['title']);
  late final content = TextEditingController(text: widget.scroll['content']);
  bool saving = false;

  Future<void> _update() async {
    setState(() => saving = true);

    await Supabase.instance.client
        .from('scrolls')
        .update({'title': title.text, 'content': content.text})
        .eq('id', widget.scroll['id']);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Scroll')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: content, maxLines: 5, decoration: const InputDecoration(labelText: 'Content')),
            const SizedBox(height: 20),
            saving
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _update, child: const Text('Save changes')),
          ],
        ),
      ),
    );
  }
}
