import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final _databaseName = "controlemovimentacao.db";
  static final _databaseVersion = 12;

  // torna esta classe singleton
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initializeDatabase();
    return _database;
  }

  _initializeDatabase() async {
    WidgetsFlutterBinding.ensureInitialized();
    return await openDatabase(
      join(await getDatabasesPath(), _databaseName),
      onCreate: _onCreate,
      version: _databaseVersion,
    );
  }

  Future _onCreate(Database db, int version) async {
  await db.execute(
          "CREATE TABLE operacao(id TEXT PRIMARY KEY, tipo TEXT, cnpj TEXT, nrdoc TEXT, situacao TEXT);");

      await db.execute(
          "CREATE TABLE produtos(id TEXT PRIMARY KEY, idproduto TEXT, idprodutoPedido TEXT, cod TEXT, nome TEXT, desc TEXT, vali TEXT, qtd TEXT, end TEXT, idOperacao TEXT, lote TEXT, sl TEXT, situacao TEXT, idloteunico TEXT, infq TEXT, isVirtual TEXT, infVali TEXT, barcode TEXT, codEndGrupo TEXT, coddum TEXT);");

      await db.execute(
          'CREATE TABLE pendenteArmaz(id TEXT PRIMARY KEY, idProd TEXT, nomeProd TEXT, idtransf TEXT, barcode TEXT, qtd TEXT, end TEXT, lote TEXT, valid TEXT, idoperador TEXT, situacao TEXT);');

      await db.execute(
          'CREATE TABLE retiradaprod(idRetirado TEXT PRIMARY KEY, idProdRetirado TEXT, nomeProdRetirado TEXT, barcodeRetirado TEXT, idtransfRetirado TEXT, endRetirado TEXT, loteRetirado TEXT, validRetirado TEXT, qtdRetirado TEXT, idoperadorRetirado TEXT);');

      await db.execute('CREATE TABLE endereco(cod TEXT PRIMARY KEY);');

      await db.execute(
          "CREATE TABLE movimentacao(id TEXT PRIMARY KEY, operacao TEXT, idOperacao TEXT, operador TEXT, endereco TEXT, idProduto TEXT, dataMovimentacao TEXT, codMovi TEXT, nroContagem TEXT, qtd TEXT);");

      await db.execute(
          'CREATE TABLE enderecogrupo(codendereco TEXT, codgrupo TEXT);');

      await db.execute(
          'CREATE TABLE produtodb(id TEXT PRIMARY KEY, cod TEXT, nome TEXT, desc TEXT, vali TEXT, lote TEXT, loteunico TEXT, impressao TEXT, sl TEXT, nrserie TEXT, grupo TEXT, infvali TEXT, barcode TEXT, coddum TEXT);');

      await db.execute(
          'CREATE TABLE armprod(idArm TEXT PRIMARY KEY, idProdArm TEXT, nomeProdArm TEXT, barcodeArm TEXT, idtransfArm TEXT, endArm TEXT, loteArm TEXT, validArm TEXT, qtdArm TEXT, idoperadorArm TEXT);');
      return db;
  }
}
