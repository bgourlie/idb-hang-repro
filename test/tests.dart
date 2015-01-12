import 'dart:html' as dom;
import 'dart:indexed_db';
import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_enhanced_config.dart';

const DB_NAME = 'testdb';

void main(){
  useHtmlEnhancedConfiguration();
  unittestConfiguration.timeout = new Duration(seconds: 5);
  var db;

  setUp((){
    print('calling setup.');
    final completer = new Completer();
    return dom.window.indexedDB.open(DB_NAME, version: 1,
        onUpgradeNeeded: (VersionChangeEvent e)  {
          print('db upgrade called (${e.oldVersion} -> ${e.newVersion})');
          final db = (e.target as Request).result;
          db.createObjectStore('foo', autoIncrement: true);
        }, onBlocked: (e) => print('open blocked.')).then((_db_){
      print('db opened.');
      db = _db_;
    });
  });

  tearDown(() {
    var completer = new Completer();
    print('calling teardown.');
    dom.window.indexedDB.deleteDatabase(DB_NAME, onBlocked: (e) {
      print('delete db blocked, but completing future anyway');
      completer.complete();
    }).then((_) {
      print('db successfully deleted!');
      completer.complete();
    });

    return completer.future;
  });

  group('indexed DB delete hang repro', (){
    test('second test which will add data', (){
      print('adding data in second test...');
      final tx = db.transaction('foo', 'readwrite');
      final objectStore = tx.objectStore('foo');
      expect(objectStore.add({'bar' : 1, 'baz' : 2}).then((addedKey) {
        print('object added to store with key=$addedKey');
        expect(tx.completed.then((_) {
          print('transaction complete.');
        }, onError: (e) => print('transaction errored!')), completes);
      }, onError: (e) => print('error adding object!')), completes);
    });

    test('call setup and teardown', (){
      print('just setup and teardown being called in first test.');
      expect(true, isTrue);
    });

  });
}