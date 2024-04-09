import 'dart:io'; // Add import for File
import 'dart:async'; // Add import for Stream

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';
class UniBlist {
  final File file;

  UniBlist({required this.file});
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key); // Fix super key

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Gemini gemini = Gemini.instance;

  List<ChatMessage> messages = [];
  late ChatUser currentUser;
  late ChatUser geminiUser;

  @override
  void initState() {
    super.initState();
    currentUser = ChatUser(id: "0", firstName: "User");
    geminiUser = ChatUser(
      id: "1",
      firstName: "Gemini",
      profileImage:
      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRP0hepz0vF_Nr2ENdPHiyTahbgQ1OJhvKwyg&usqp=CAU",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Gemini Chat"),
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return DashChat(
      inputOptions: InputOptions(trailing: [
        IconButton(onPressed: _sendMediaMessage, icon: Icon(Icons.image)),
      ]),
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
    );
  }

  void _sendMessage(ChatMessage chatMessage) async {
    setState(() {
      messages = [chatMessage, ...messages];
    });
    try {
      String question = chatMessage.text;
      List<UniBlist>? images;
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [UniBlist(file: File(chatMessage.medias!.first.url))];
      }

      // Handle asynchronous operations properly
      await gemini.streamGenerateContent(question, ).listen(
            (event) {
          ChatMessage? lastMessage = messages.firstOrNull;
          if (chatMessage != null && lastMessage!.user == geminiUser) {
            lastMessage = messages.removeAt(0);
            String response = event.content?.parts!
                .fold("", (previous, current) => "$previous   ${current.text}") ??
                "";
            lastMessage.text += response;
            setState(() {
              messages = [lastMessage!, ...messages];
            });
          } else {
            String response = event.content?.parts!
                .fold("", (previous, current) => "$previous   ${current.text}") ??
                "";
            ChatMessage message = ChatMessage(
              user: geminiUser,
              createdAt: DateTime.now(),
              text: response,
            );
            setState(() {
              messages = [message, ...messages];
            });
          }
        },
      );
    } catch (e) {
      print(e);
    }
  }


  void _sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: "Describe this picture?",
        medias: [
          ChatMedia(
            url: file.path,
            fileName: "",
            type: MediaType.image,
          ),
        ],
      );
      _sendMessage(chatMessage);
    }
  }
}
