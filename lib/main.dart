// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:typed_data';
import 'package:chat_bot/constantes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'ChatMessage.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyApp(),
  ));
}

const backgroundColor = Color(0xff343541);
const botBackgroundColor = Color(0xff4444654);

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

enum TtsState { playing, stopped, paused, continued }

class _MyAppState extends State<MyApp> {
  late bool isLoading;
  TextEditingController _textController = new TextEditingController();
  List<ChatMessage> messages = [];
  final _scrollController = ScrollController();

  late FlutterTts flutterTts;
  String? _newVoiceText;
  TtsState ttsState = TtsState.stopped;
  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;
  get isPaused => ttsState == TtsState.paused;
  get isContinued => ttsState == TtsState.continued;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;

  @override
  void initState() {
    isLoading = false;
    super.initState();
    initTts();
  }

  initTts() {
    flutterTts = FlutterTts();

    _setAwaitOptions();

    if (isAndroid) {
      _getDefaultEngine();
      _getDefaultVoice();
    }

    flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
        ttsState = TtsState.playing;
      });
    });

    if (isAndroid) {
      flutterTts.setInitHandler(() {
        setState(() {
          print("TTS Initialized");
        });
      });
    }

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setPauseHandler(() {
      setState(() {
        print("Paused");
        ttsState = TtsState.paused;
      });
    });

    flutterTts.setContinueHandler(() {
      setState(() {
        print("Continued");
        ttsState = TtsState.continued;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });
  }

  Future _speak() async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (_newVoiceText != null) {
      if (_newVoiceText!.isNotEmpty) {
        await flutterTts.speak(_newVoiceText!);
      }
    }
  }

  Future _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  Future _pause() async {
    var result = await flutterTts.pause();
    if (result == 1) setState(() => ttsState = TtsState.paused);
  }

  Future _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      print(engine);
    }
  }

  Future _getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
    if (voice != null) {
      print(voice);
    }
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  void _onChange(String text) {
    setState(() {
      _newVoiceText = text;
    });
  }

  Future<String> generateResponse(String prompt) async {
    final apiKey = apiSecretKey;
    var url = Uri.https("api.openai.com", "/v1/completions");
    final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'text-davinci-003',
          'prompt': prompt,
          'temperature': 0,
          'max_tokens': 2000,
          'top_p': 1,
          'frequency_penalty': 0.0,
          'presence_penalty': 0.0
        }));

    if (response.statusCode == 201 || response.statusCode == 200) {
      Map<String, dynamic> newResponse =
          jsonDecode(Utf8Decoder().convert(response.body.codeUnits));
      print(Utf8Decoder().convert(response.body.codeUnits));
      // print(response.body);
      _onChange(newResponse['choices'][0]['text']);
      _speak();
      return newResponse['choices'][0]['text'];
    }

    return 'Sorry, podemos conversar mais tarde? Agora encontro-me indisponivel.';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: botBackgroundColor,
        appBar: AppBar(
          backgroundColor: botBackgroundColor,
          title: Text("Chat Bot"),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(child: _buildList()),
            Visibility(
              visible: isLoading,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [_buildInput(), _buildSubmitBtn()],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitBtn() {
    return Visibility(
      visible: !isLoading,
      child: Container(
        height: 48,
        color: botBackgroundColor,
        child: IconButton(
          icon: Icon(
            Icons.send_rounded,
            color: Color.fromRGBO(142, 142, 160, 1),
          ),
          onPressed: () {
            setState(() {
              messages.add(ChatMessage(
                text: _textController.text,
                chatMessageType: ChatMessageType.user,
              ));
              isLoading = true;
            });

            var input = _textController.text;
            _textController.clear();
            Future.delayed(Duration(milliseconds: 50))
                .then((value) => _scrollDown);

            generateResponse(input).then((value) {
              setState(() {
                isLoading = false;
                messages.add(ChatMessage(
                    text: value, chatMessageType: ChatMessageType.bot));
              });
            });
            _textController.clear();
            Future.delayed(Duration(milliseconds: 50))
                .then((value) => _scrollDown());
          },
        ),
      ),
    );
  }

  void _scrollDown() {
    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Expanded _buildInput() {
    return Expanded(
        child: TextField(
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(color: Colors.white),
      controller: _textController,
      decoration: InputDecoration(
          fillColor: botBackgroundColor,
          filled: true,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none),
      onSubmitted: ((value) {
        if (_textController.text.trim().toLowerCase() == "ok") {
          _stop();
          return;
        }
        setState(() {
          messages.add(ChatMessage(
            text: _textController.text,
            chatMessageType: ChatMessageType.user,
          ));
          isLoading = true;
        });

        var input = _textController.text;
        _textController.clear();
        Future.delayed(Duration(milliseconds: 50)).then((value) => _scrollDown);

        generateResponse(input).then((value) {
          setState(() {
            isLoading = false;
            messages.add(
                ChatMessage(text: value, chatMessageType: ChatMessageType.bot));
          });
        });
        _textController.clear();
        Future.delayed(Duration(milliseconds: 50))
            .then((value) => _scrollDown());
      }),
    ));
  }

  ListView _buildList() {
    return ListView.builder(
        controller: _scrollController,
        itemCount: messages.length,
        itemBuilder: ((context, index) {
          var message = messages[index];
          _newVoiceText = message.text;
          return ChatMessageWidget(
            text: message.text,
            chatMessageType: message.chatMessageType,
          );
        }));
  }
}

class ChatMessageWidget extends StatelessWidget {
  final String text;
  final ChatMessageType chatMessageType;

  const ChatMessageWidget({
    Key? key,
    required this.text,
    required this.chatMessageType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isBot = chatMessageType == ChatMessageType.bot;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(30)),
        color: isBot ? botBackgroundColor : backgroundColor,
      ),
      margin: EdgeInsets.only(
          top: 10, bottom: 10, right: isBot ? 50 : 10, left: isBot ? 10 : 50),
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          chatMessageType == ChatMessageType.bot
              ? Container(
                  margin: EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      color: Color.fromRGBO(16, 163, 127, 1),
                    ),
                  ),
                )
              : Container(
                  margin: EdgeInsets.only(left: 16),
                  child: CircleAvatar(
                    backgroundColor: Color.fromRGBO(16, 163, 127, 1),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  )),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                child: Text(
                  text,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.white),
                ),
              )
            ],
          ))
        ],
      ),
    );
  }
}
