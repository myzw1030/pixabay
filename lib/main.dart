import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future main() async {
  // 環境変数読み込み
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PixabayPage(),
    );
  }
}

class PixabayPage extends StatefulWidget {
  const PixabayPage({super.key});

  @override
  State<PixabayPage> createState() => _PixabayPageState();
}

class _PixabayPageState extends State<PixabayPage> {
  // 空のリスト
  List hits = [];

  Future<void> fetchImages(String text) async {
    // APIのkeyは環境変数設定
    final apiKey = dotenv.get('VAR_URL');
    // textfieldの値(text)
    final url = '$apiKey&q=$text&image_type=photo&pretty=true&per_page=100';
    Response response = await Dio().get(url);
    hits = response.data['hits'];
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    fetchImages('猫');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextFormField(
          initialValue: '猫',
          decoration: const InputDecoration(
            fillColor: Colors.white,
            filled: true,
          ),
          onFieldSubmitted: (text) {
            fetchImages(text);
          },
        ),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemCount: hits.length,
        itemBuilder: (context, index) {
          Map<String, dynamic> hit = hits[index];
          return InkWell(
            onTap: () async {
              // 1. URLからダウンロード
              Response response = await Dio().get(
                hit['webformatURL'],
                options: Options(responseType: ResponseType.bytes),
              );
              // 2. ダウンロードしたデータをファイルに一時的に保存
              Directory dir = await getTemporaryDirectory();
              File file = await File('${dir.path}/image.png')
                  .writeAsBytes(response.data);
              // 3. Shareパッケージを呼び出して共有
              Share.shareFiles([file.path]);
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  hit['previewURL'],
                  fit: BoxFit.cover,
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    color: Colors.white,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 14,
                          color: Colors.red.shade400,
                        ),
                        Text('${hit['likes']}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
