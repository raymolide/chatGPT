// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:chat_bot/constantes.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'ChatMessage.dart';

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

class _MyAppState extends State<MyApp> {
  late bool isLoading;
  TextEditingController _textController = new TextEditingController();
  List<ChatMessage> messages = [];
  final _scrollController = ScrollController();

  @override
  void initState() {
    isLoading = false;
    super.initState();
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

    Map<String, dynamic> newResponse = jsonDecode(response.body);
    print(response.body);
    return newResponse['choices'][0]['text'];
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
    ));
  }

  ListView _buildList() {
    return ListView.builder(
        controller: _scrollController,
        itemCount: messages.length,
        itemBuilder: ((context, index) {
          var message = messages[index];
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
