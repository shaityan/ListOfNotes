import 'package:flutter/material.dart';
import 'data/idea_service.dart';
import 'data/note_repository.dart';
import 'models/note.dart';

final NoteRepository noteRepository = SharedPrefsNoteRepository();
final IdeaService ideaService = IdeaService();

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Список заметок',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const NotesListScreen(),
      const InfoScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notes),
            label: 'Заметки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'О приложении',
          ),
        ],
      ),
    );
  }
}

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  List<Note> _notes = [];
  bool _isLoading = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final notes = await noteRepository.loadNotes();
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorText = 'Не удалось загрузить заметки';
      });
    }
  }

  Future<void> _openNewNote() async {
    final result = await Navigator.push<NoteEditResult>(
      context,
      MaterialPageRoute(
        builder: (context) => const EditNoteScreen(),
      ),
    );

    if (result != null && !result.deleted && result.note != null) {
      setState(() {
        _notes.add(result.note!);
      });
      await noteRepository.saveNotes(_notes);
    }
  }

  Future<void> _editNote(int index) async {
    final note = _notes[index];

    final result = await Navigator.push<NoteEditResult>(
      context,
      MaterialPageRoute(
        builder: (context) => EditNoteScreen(initialNote: note),
      ),
    );

    if (result != null) {
      if (result.deleted) {
        setState(() {
          _notes.removeAt(index);
        });
      } else if (result.note != null) {
        setState(() {
          _notes[index] = result.note!;
        });
      }
      await noteRepository.saveNotes(_notes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заметки'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Список заметок',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Здесь отображаются все заметки текущего сеанса. ',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (_isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (_errorText != null) {
                    return Center(
                      child: Text(_errorText!),
                    );
                  }

                  if (_notes.isEmpty) {
                    return const Center(
                      child: Text('Пока нет ни одной заметки.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: _notes.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            note.title.isEmpty ? 'Без заголовка' : note.title,
                          ),
                          subtitle: Text(
                            note.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _editNote(index),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewNote,
        tooltip: 'Добавить заметку',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('О приложении'),
        centerTitle: true,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Список заметок',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Приложение для создания и просмотра заметок.',
            ),
          ],
        ),
      ),
    );
  }
}

class NoteEditResult {
  final Note? note;
  final bool deleted;

  const NoteEditResult({
    this.note,
    required this.deleted,
  });
}

class EditNoteScreen extends StatefulWidget {
  final Note? initialNote;

  const EditNoteScreen({super.key, this.initialNote});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.initialNote?.title ?? '');
    _textController =
        TextEditingController(text: widget.initialNote?.text ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final text = _textController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Текст заметки не может быть пустым')),
      );
      return;
    }

    final note = Note(title: title, text: text);
    Navigator.pop(
      context,
      NoteEditResult(
        note: note,
        deleted: false,
      ),
    );
  }

  Future<void> _deleteNote() async {
    final isConfirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Удалить заметку?'),
              content: const Text('Это действие нельзя будет отменить.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Удалить'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!isConfirmed) {
      return;
    }

    Navigator.pop(
      context,
      const NoteEditResult(
        note: null,
        deleted: true,
      ),
    );
  }

  Future<void> _handleIdeaRequest() async {
    try {
      final idea = await ideaService.fetchRandomIdea();
      setState(() {
        _textController.text = idea;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось получить идею'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialNote != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактирование заметки' : 'Новая заметка'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Заголовок',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Например, "Список дел на завтра"',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Текст заметки',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Введите текст заметки...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _handleIdeaRequest,
                    child: const Text('Случайная идея'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveNote,
                    child: const Text('Сохранить'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _deleteNote,
                    child: const Text('Удалить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
