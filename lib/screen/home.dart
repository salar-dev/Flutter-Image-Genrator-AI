import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON encoding/decoding
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:lottie/lottie.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  TextEditingController promptController = TextEditingController();
  bool isLoading = false;
  String? _imageUrl;

  void generateImage() async {
    const apiKey = 'YOUR_OPENAI_API_KEY';
    const url = 'https://api.openai.com/v1/images/generations';

    if (promptController.text.isNotEmpty) {
      setState(() {
        isLoading = true;
        _imageUrl = null;
      });
      try {
        var response = await http.post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'prompt': promptController.text,
            'size': '1024x1024',
          }),
        );

        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          setState(() {
            _imageUrl = data['data'][0]['url'];
            isLoading = false;
          });
          if (kDebugMode) {
            print(_imageUrl);
          }
        } else {
          setState(() {
            isLoading = false;
          });
          if (kDebugMode) {
            print('Failed with status code: ${response.statusCode}');
            print(response.body);
          }
          // Handle HTTP error
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        if (kDebugMode) {
          print(e);
        }
      }
    }
  }

  void saveImage() async {
    var response = await Dio()
        .get(_imageUrl!, options: Options(responseType: ResponseType.bytes));
    final result = await ImageGallerySaver.saveImage(
      Uint8List.fromList(response.data),
      quality: 80,
    );
    if (kDebugMode) {
      print(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E2E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Image Generator AI 🤖🔥',
          style: TextStyle(color: Colors.white),
        ),
        leading: _imageUrl != null
            ? IconButton(
                onPressed: () {
                  promptController.clear();
                  setState(() {
                    _imageUrl = null;
                  });
                },
                icon: const Icon(
                  Icons.history_rounded,
                  color: Color(0xFFA200FF),
                ),
              )
            : Container(),
        actions: [
          _imageUrl != null
              ? IconButton(
                  onPressed: () {
                    saveImage();
                  },
                  icon: const Icon(
                    Icons.download_outlined,
                    color: Color(0xFFA200FF),
                  ),
                )
              : Container(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: _imageUrl == null
                    ? Lottie.asset(
                        isLoading
                            ? 'assets/loading.json'
                            : 'assets/ai_logo.json',
                      )
                    : ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(12)),
                        child: Image.network(
                          _imageUrl!,
                          width: MediaQuery.sizeOf(context).width - 30,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            width: MediaQuery.sizeOf(context).width,
            color: const Color(0xFF1E1E1E),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Enter your prompt",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF5F5F5F),
                        width: 2,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                    ),
                    child: TextField(
                      controller: promptController,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Write the prompt here...',
                        hintStyle: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF9F9F9F),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: MaterialButton(
                      minWidth: MediaQuery.sizeOf(context).width,
                      height: 55,
                      color: const Color(0xFFA200FF),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.generating_tokens,
                            color: Colors.white,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Generate',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      onPressed: () {
                        if (!isLoading) {
                          generateImage();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
