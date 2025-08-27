import 'package:sembast/sembast.dart';
import 'package:shinpo/model/word.dart';
import 'package:shinpo/repository/base_repository.dart';

class WordRepository extends BaseRepository {
  final _store = stringMapStoreFactory.store('wordsByNews');

  Future<void> saveWords(String newsId, List<Word> words) async {
    final db = await getDatabase();
    final data = {
      'newsId': newsId,
      'words': words.map((w) => w.toMap()).toList(),
    };
    await _store.record(newsId).put(db, data);
  }

  Future<List<Word>> getWords(String newsId) async {
    final db = await getDatabase();
    final record = await _store.record(newsId).get(db);
    if (record == null) return [];
    final list = (record['words'] as List?) ?? [];
    return list.map<Word>((json) => Word.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  Future<void> clearWords(String newsId) async {
    final db = await getDatabase();
    await _store.record(newsId).delete(db);
  }
}
