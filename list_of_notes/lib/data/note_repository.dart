import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/note.dart';

abstract class NoteRepository {
  Future<List<Note>> loadNotes();
  Future<void> saveNotes(List<Note> notes);
}

class SharedPrefsNoteRepository implements NoteRepository {
  static const String _key = 'notes';

  @override
  Future<List<Note>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
    return list
        .map(
          (e) => Note.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<void> saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final list = notes.map((n) => n.toJson()).toList();
    final jsonString = jsonEncode(list);
    await prefs.setString(_key, jsonString);
  }
}


