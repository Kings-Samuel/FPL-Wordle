import 'package:appwrite/appwrite.dart';
import '../../consts.dart';

Client _client = Client();
late Databases _database;
late Storage _storage;
late Account _account;
late Functions _functions;
late Teams _teams;

Databases get database => _database;
Storage get storage => _storage;
Account get account => _account;
Functions get functions => _functions;
Teams get teams => _teams;

Future<void> initAppwrite() async {
  _client.setProject(Consts.projectId).setEndpoint(Consts.endpoint);
  _database = Databases(_client);
  _storage = Storage(_client);
  _account = Account(_client);
  _functions = Functions(_client);
  _teams = Teams(_client);
}