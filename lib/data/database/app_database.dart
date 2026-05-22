import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  static AppDatabase get instance => _instance;
  AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'shangkan_exam.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE questions ADD COLUMN exam_source TEXT');
      await _createImportJobsTable(db);
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE questions ADD COLUMN created_at INTEGER');
    }
    if (oldVersion < 4) {
      await _createCheckInTable(db);
      await _createExamCountdownTable(db);
      await _createCurrentAffairsTable(db);
      await _createReciteWrongTable(db);
    }
    if (oldVersion < 5) {
      await _createAiConversationTable(db);
    }
  }

  Future<void> _createTables(Database db) async {
    // 题目表
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        type TEXT NOT NULL,
        options TEXT NOT NULL,
        answer TEXT NOT NULL,
        explanation TEXT DEFAULT '',
        ai_explanation TEXT,
        knowledge_points TEXT DEFAULT '[]',
        module TEXT NOT NULL,
        chapter TEXT NOT NULL,
        difficulty INTEGER DEFAULT 3,
        source TEXT DEFAULT 'builtin',
        exam_source TEXT,
        created_at INTEGER
      )
    ''');

    // 错题记录表
    await db.execute('''
      CREATE TABLE wrong_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id INTEGER NOT NULL,
        wrong_count INTEGER DEFAULT 1,
        last_wrong_time INTEGER NOT NULL,
        next_review_time INTEGER NOT NULL,
        review_stage INTEGER DEFAULT 0,
        is_mastered INTEGER DEFAULT 0,
        FOREIGN KEY (question_id) REFERENCES questions(id)
      )
    ''');

    // 收藏表
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (question_id) REFERENCES questions(id)
      )
    ''');

    // 练习记录表
    await db.execute('''
      CREATE TABLE practice_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mode TEXT NOT NULL,
        module TEXT NOT NULL,
        chapter TEXT,
        total_count INTEGER NOT NULL,
        correct_count INTEGER NOT NULL,
        duration INTEGER NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    // 用户设置表
    await db.execute('''
      CREATE TABLE user_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // 导入任务表
    await _createImportJobsTable(db);

    // 打卡记录表
    await _createCheckInTable(db);

    // 考试倒计时表
    await _createExamCountdownTable(db);

    // 时政表
    await _createCurrentAffairsTable(db);

    // 背诵错题表
    await _createReciteWrongTable(db);

    // AI对话记录表
    await _createAiConversationTable(db);
  }

  Future<void> _createImportJobsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS import_jobs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        total_questions INTEGER DEFAULT 0,
        imported_count INTEGER DEFAULT 0,
        duplicate_count INTEGER DEFAULT 0,
        failed_count INTEGER DEFAULT 0,
        parsed_json TEXT,
        exam_source TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createCheckInTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS check_in_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        study_duration INTEGER DEFAULT 0,
        practice_count INTEGER DEFAULT 0,
        recite_count INTEGER DEFAULT 0,
        is_checked INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createExamCountdownTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exam_countdowns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        exam_date INTEGER NOT NULL,
        is_visible INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createCurrentAffairsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS current_affairs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        summary TEXT,
        category TEXT DEFAULT '综合',
        source TEXT,
        publish_date TEXT NOT NULL,
        is_important INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createReciteWrongTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recite_wrong_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        knowledge_point TEXT NOT NULL,
        content TEXT NOT NULL,
        wrong_count INTEGER DEFAULT 1,
        last_wrong_time INTEGER NOT NULL,
        next_review_time INTEGER NOT NULL,
        review_stage INTEGER DEFAULT 0,
        is_mastered INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createAiConversationTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_conversations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        model TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_questions_module ON questions(module)');
    await db.execute('CREATE INDEX idx_questions_chapter ON questions(chapter)');
    await db.execute('CREATE INDEX idx_questions_content_options ON questions(content, options)');
    await db.execute('CREATE INDEX idx_wrong_records_question ON wrong_records(question_id)');
    await db.execute('CREATE INDEX idx_wrong_records_review ON wrong_records(next_review_time)');
    await db.execute('CREATE INDEX idx_favorites_question ON favorites(question_id)');
    await db.execute('CREATE INDEX idx_practice_records_timestamp ON practice_records(timestamp)');
    await db.execute('CREATE INDEX idx_check_in_date ON check_in_records(date)');
    await db.execute('CREATE INDEX idx_current_affairs_date ON current_affairs(publish_date)');
    await db.execute('CREATE INDEX idx_recite_wrong_review ON recite_wrong_records(next_review_time)');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
