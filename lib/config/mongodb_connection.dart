import 'package:mongo_dart/mongo_dart.dart';
import '../models/user.dart';

class MongoService {
  static const String _uri = 'mongodb+srv://vinhbdq23it:RXEIlyu2yVrPeBAV@cluster0.mtub8wb'
      '.mongodb.net/midterm?retryWrites=true&w=majority&appName=Cluster0';

  static Future<Db> open() async {
    final db = await Db.create(_uri);
    await db.open();
    return db;
  }

  static Future<int> countUsers() async {
    final db = await open();
    try {
      final users = db.collection('users');
      return await users.count();
    } finally {
      await db.close();
      // ignore: avoid_print
      print('\nConnection closed.');
    }
  }

  static Future<void> insertUser(AppUser user) async {
    final db = await open();
    try {
      final users = db.collection('users');
      await users.insertOne(user.toMap());
    } finally {
      await db.close();
    }
  }

  static Future<List<AppUser>> fetchUsers() async {
    final db = await open();
    try {
      final users = db.collection('users');
      final docs = await users.find().toList();
      return docs.map((e) => AppUser.fromMap(e)).toList();
    } finally {
      await db.close();
    }
  }

  static Future<void> updateUser(String username, AppUser updatedUser) async {
    final db = await open();
    try {
      final users = db.collection('users');
      await users.updateOne(
        where.eq('username', username),
        modify.set('username', updatedUser.username)
            .set('email', updatedUser.email)
            .set('password', updatedUser.password)
            .set('image', updatedUser.image),
      );
    } finally {
      await db.close();
    }
  }

  static Future<void> deleteUser(String username) async {
    final db = await open();
    try {
      final users = db.collection('users');
      await users.deleteOne(where.eq('username', username));
    } finally {
      await db.close();
    }
  }
}