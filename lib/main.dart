import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:connectivity/connectivity.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hut_assistant/decode.dart';
import 'package:hut_assistant/keywords.dart';
import 'package:hut_assistant/operations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:translator/translator.dart';

void main() {
  runApp(MyApp());
}

// main color theme
const MaterialColor myColor = MaterialColor(0xFF6A0DAD, const <int, Color>{
  50: Color.fromRGBO(106, 13, 173, .1),
  100: Color.fromRGBO(106, 13, 173, .2),
  200: Color.fromRGBO(106, 13, 173, .3),
  300: Color.fromRGBO(106, 13, 173, .4),
  400: Color.fromRGBO(106, 13, 173, .5),
  500: Color.fromRGBO(106, 13, 173, .6),
  600: Color.fromRGBO(106, 13, 173, .7),
  700: Color.fromRGBO(106, 13, 173, .8),
  800: Color.fromRGBO(106, 13, 173, .9),
  900: Color.fromRGBO(106, 13, 173, 1),
});

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HUTA',
      theme: ThemeData(
        primarySwatch: myColor,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

Future<bool> getPrefrences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('firstEnter');
}

setFirstEnter() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool('firstEnter', true);
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _hasSpeech = false;
  double level = 0.0;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;
  String lastWords = "";
  String lastError = "";
  String lastStatus = "";
  String _currentLocaleId = "";
  List<LocaleName> _localeNames = [];
  bool isInitialised = false;
  final SpeechToText speech = SpeechToText();
  List<Message> messages = [];
  var subscription;
  bool showingNoIntenetDialog = false;
  List<String> inputChoices = [];
  Operation inputOperation;

  Future<void> initSpeechState() async {
    bool hasSpeech = await speech.initialize(
        onError: errorListener, onStatus: statusListener);
    if (hasSpeech) {
      _localeNames = await speech.locales();

      var systemLocale = await speech.systemLocale();
      bool isPerAvailable = false;
      for (LocaleName l in _localeNames)
        if (l.localeId == 'fa_IR') {
          isPerAvailable = true;
          break;
        }
      if (isPerAvailable)
        _currentLocaleId = 'fa_IR';
      else
        _currentLocaleId = systemLocale.localeId;
    }

    if (!mounted) return;

    setState(() {
      _hasSpeech = hasSpeech;
    });
  }

  // initializing app
  // this method runs at entering to app
  @override
  void initState() {
    // TODO: implement initState
    // if this is first time for entering to app
    getPrefrences().then((isFirstEnter) {
      if (isFirstEnter == null || !isFirstEnter) {
        setState(() {
          messages.add(Message(
              msg:
                  'سلام\nاسم من دستیار شخصی دانشگاه صنعتی همدانه\nشما میتونید منو هوتا صدا کنید.\nروی دکمه میکروفون یک بار کلیک کنید و درخواستتونو بگید.',
              sender: MessageSender.system));
        });
        setFirstEnter();
      }
    });
    // request for microohone permission
    Permission.microphone.request().then((value) {
      if (value.isDenied) {
        setState(() {
          messages.add(Message(
              msg: 'برای کار کردن با برنامه مجوز استفاده از میکروفون لازم است.',
              sender: MessageSender.system));
        });
        Permission.microphone.request().then((value2) {
          // exiting from app
          if (value2.isDenied) SystemNavigator.pop();
        });
      }
    });
    // initialise speech engine
    initSpeechState();
    // checking internet connection
    Connectivity().checkConnectivity().then((result) {
      checkConnection(result);
    });
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      checkConnection(result);
    });
    super.initState();
  }

  // building page
  // this method runs after the initState method and everytime that setState method called
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar in top of page
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(40),
        child: AppBar(
          elevation: 6.0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32.0),
                  bottomRight: Radius.circular(32.0))),
          title: Text(
            'هوتا',
            style: TextStyle(fontFamily: 'Homa'),
            textDirection: TextDirection.rtl,
          ),
          centerTitle: true,
        ),
      ),
      // chat part of page
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (messages.isNotEmpty)
            Expanded(
              child: SingleChildScrollView(
                reverse: true,
                child: Column(
                  children: List.generate(messages.length, (index) {
                    Message message = messages[index];

                    bool amISender = message.sender == MessageSender.user;
                    return Padding(
                      padding: EdgeInsets.only(
                          left: amISender ? 80.0 : 0.0,
                          right: amISender ? 0.0 : 80.0),
                      child: Align(
                        alignment:
                            amISender ? Alignment.topRight : Alignment.topLeft,
                        child: Card(
                          color: amISender ? Colors.blue[700] : Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                            Radius.circular(16.0),
                          )),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text(
                                  message.msg.trim(),
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                      fontFamily: 'Sans',
                                      color: amISender
                                          ? Colors.white
                                          : Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          // microphone button
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 10.0,
                ),
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                          blurRadius: .26,
                          spreadRadius: level * 1.5,
                          color: Color(0xFF6A0DAD).withOpacity(.15))
                    ],
                    color: Color(0xFF6A0DAD),
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.mic,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (speech.isListening) {
                        print('stopped.');
                        stopListening();
                      } else {
                        print('started');
                        startListening();
                      }
                    },
                  ),
                ),
                SizedBox(
                  height: 10.0,
                ),
                Text(
                  (speech.isNotListening
                      ? 'کلیک کرده و صحبت کنید'
                      : lastWords.isEmpty
                          ? 'در حال گوش دادن...'
                          : lastWords),
                  style: TextStyle(
                      fontFamily: 'Homa',
                      color: Theme.of(context).primaryColor),
                  textDirection: TextDirection.rtl,
                ),
                SizedBox(
                  height: 10.0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void startListening() {
    lastWords = "";
    lastError = "";
    speech.listen(
        onResult: resultListener,
        listenFor: Duration(seconds: 10),
        localeId: _currentLocaleId,
        onSoundLevelChange: soundLevelListener,
        cancelOnError: true,
        listenMode: ListenMode.confirmation);
    setState(() {});
  }

  void stopListening() {
    speech.stop();
    setState(() {
      level = 0.0;
    });
  }

  void cancelListening() {
    speech.cancel();
    setState(() {
      level = 0.0;
    });
  }

  // if input is completed this method gets answer
  // otherwise word will be completed
  void resultListener(SpeechRecognitionResult result) {
    setState(() {
      lastWords = "${result.recognizedWords}";
      if (speech.isNotListening) {
        messages.add(new Message(msg: lastWords, sender: MessageSender.user));
      }
    });
    if (speech.isNotListening) {
      if (inputOperation == null) {
        DecodeResult result = DecodeSentence.answer(lastWords);
        setState(() {
          messages.add(
              new Message(msg: result.answer, sender: MessageSender.system));
        });
        if (result.operation != null) {
          switch (result.operation) {
            case Operation.search:
              if (!Operations.searchInGoogle(result.operationData)) {
                setState(() {
                  messages.add(new Message(
                      msg: 'متاسفانه نمیتونم.', sender: MessageSender.system));
                });
              }
              break;
            case Operation.callNumber:
              Operations.call(result.operationData);
              break;

            case Operation.callContact:
              Permission.contacts.request().then((request) {
                if (request == PermissionStatus.granted) {
                  ContactsService.getContacts().then((contacts) {
                    print(contacts.first.displayName);
                    bool isFounded = false;
                    for (Contact c in contacts) {
                      if (result.operationData.contains(c.displayName)) {
                        isFounded = true;
                        print('found it');
                        if (c.phones.length == 1) {
                          Operations.call(c.phones.first.value);
                        } else {
                          String out = 'به کدوم شماره؟' + '\n';
                          for (Item pn in c.phones) {
                            out += pn.value + '\n';
                            inputChoices.add(pn.value);
                          }
                          setState(() {
                            messages.add(new Message(
                                msg: out, sender: MessageSender.system));
                          });
                          inputOperation = Operation.callNumber;
                        }
                      }
                    }
                    if (!isFounded)
                      setState(() {
                        messages.add(new Message(
                            msg: 'متاسفانه چنین مخاطبی یافت نشد.',
                            sender: MessageSender.system));
                      });
                  });
                } else {
                  setState(() {
                    messages.add(new Message(
                        msg: 'مجوز مخاطبین مورد نیاز است.',
                        sender: MessageSender.system));
                  });
                }
              });
              break;

            case Operation.textNumber:
              Operations.text(result.operationData);
              break;

            case Operation.textContact:
              Permission.contacts.request().then((request) {
                if (request == PermissionStatus.granted) {
                  ContactsService.getContacts().then((contacts) {
                    bool isFounded = false;
                    for (Contact c in contacts) {
                      if (result.operationData.contains(c.displayName)) {
                        isFounded = true;
                        print('found it');
                        if (c.phones.length == 1) {
                          Operations.text(c.phones.first.value);
                        } else {
                          String out = 'به کدوم شماره؟' + '\n';
                          for (Item pn in c.phones) {
                            out += pn.value + '\n';
                            inputChoices.add(pn.value);
                          }
                          setState(() {
                            messages.add(new Message(
                                msg: out, sender: MessageSender.system));
                          });
                          inputOperation = Operation.textNumber;
                        }
                      }
                    }
                    if (!isFounded)
                      setState(() {
                        messages.add(new Message(
                            msg: 'متاسفانه چنین مخاطبی یافت نشد.',
                            sender: MessageSender.system));
                      });
                  });
                } else {
                  setState(() {
                    messages.add(new Message(
                        msg: 'مجوز مخاطبین مورد نیاز است.',
                        sender: MessageSender.system));
                  });
                }
              });
              break;

            case Operation.mail:
              Permission.contacts.request().then((request) {
                if (request == PermissionStatus.granted) {
                  ContactsService.getContacts().then((contacts) {
                    print(contacts.first.displayName);
                    bool isFounded = false;
                    for (Contact c in contacts) {
                      if (result.operationData.contains(c.displayName)) {
                        isFounded = true;
                        print('found it');
                        if (c.emails.length == 1) {
                          Operations.mail(c.emails.first.value);
                        } else {
                          String out = 'به کدوم ایمیل؟' + '\n';
                          for (Item em in c.emails) {
                            out += em.value + '\n';
                            inputChoices.add(em.value);
                          }
                          setState(() {
                            messages.add(new Message(
                                msg: out, sender: MessageSender.system));
                          });
                          inputOperation = Operation.mail;
                        }
                      }
                    }
                    if (!isFounded) {
                      Operations.mail('');
                      setState(() {
                        messages.add(new Message(
                            msg: 'باشه', sender: MessageSender.system));
                      });
                    }
                  });
                } else {
                  Operations.mail('');
                }
              });
              break;

            case Operation.exit:
              SystemNavigator.pop();
              break;

            case Operation.play_music:
              int randomMusicNumber =
                  Random().nextInt(Operations.recommandedMusics.length);
              setState(() {
                messages.add(new Message(
                    msg: Operations.recommandedMusics.keys
                        .elementAt(randomMusicNumber),
                    sender: MessageSender.system));
              });
              Operations.playMusic(randomMusicNumber);
              break;

            case Operation.play_movie:
              int randomMovieNumber =
                  Random().nextInt(Operations.recommandedMovies.length);
              setState(() {
                messages.add(new Message(
                    msg: Operations.recommandedMovies[randomMovieNumber],
                    sender: MessageSender.system));
              });
              break;

            case Operation.translateToEn:
              final translator = GoogleTranslator();
              translator
                  .translate(result.operationData, from: 'fa', to: 'en')
                  .then((tranlate) {
                setState(() {
                  messages.add(new Message(
                      msg: tranlate.text, sender: MessageSender.system));
                });
              });
              break;

            case Operation.translateToAr:
              final translator = GoogleTranslator();
              translator
                  .translate(result.operationData, from: 'fa', to: 'ar')
                  .then((tranlate) {
                setState(() {
                  messages.add(new Message(
                      msg: tranlate.text, sender: MessageSender.system));
                });
              });
              break;

            case Operation.translateToTr:
              final translator = GoogleTranslator();
              translator
                  .translate(result.operationData, from: 'fa', to: 'tr')
                  .then((tranlate) {
                setState(() {
                  messages.add(new Message(
                      msg: tranlate.text, sender: MessageSender.system));
                });
              });
              break;

            case Operation.translateToEs:
              final translator = GoogleTranslator();
              translator
                  .translate(result.operationData, from: 'fa', to: 'es')
                  .then((tranlate) {
                setState(() {
                  messages.add(new Message(
                      msg: tranlate.text, sender: MessageSender.system));
                });
              });
              break;

            case Operation.translateToDe:
              final translator = GoogleTranslator();
              translator
                  .translate(result.operationData, from: 'fa', to: 'de')
                  .then((tranlate) {
                setState(() {
                  messages.add(new Message(
                      msg: tranlate.text, sender: MessageSender.system));
                });
              });
              break;

            case Operation.translateToFr:
              final translator = GoogleTranslator();
              translator
                  .translate(result.operationData, from: 'fa', to: 'fr')
                  .then((tranlate) {
                setState(() {
                  messages.add(new Message(
                      msg: tranlate.text, sender: MessageSender.system));
                });
              });
              break;
          }
        }
      } else {
        bool isCancel = false;
        for (String lw in lastWords.split(' ')) {
          if (cancelWords.contains(lw)) {
            inputChoices = [];
            inputOperation = null;
            setState(() {
              messages.add(
                  new Message(msg: 'لغو عملیات', sender: MessageSender.system));
            });
            isCancel = true;
            break;
          }
        }
        if (!isCancel) {
          int r = DecodeSentence.answerInput(lastWords);
          if (r != -1) {
            switch (inputOperation) {
              case Operation.callNumber:
                Operations.call(inputChoices[r]);
                break;

              case Operation.textNumber:
                Operations.text(inputChoices[r]);
                break;

              case Operation.mail:
                Operations.mail(inputChoices[r]);
                break;
            }
            inputChoices = [];
            inputOperation = null;
          } else {
            setState(() {
              messages.add(new Message(
                  msg: DecodeSentence.dontUnderstandSentence,
                  sender: MessageSender.system));
            });
          }
        }
      }
    }
  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    // print("sound level $level: $minSoundLevel - $maxSoundLevel ");
    setState(() {
      this.level = level;
    });
  }

  void errorListener(SpeechRecognitionError error) {
    // print("Received error status: $error, listening: ${speech.isListening}");
    setState(() {
      lastError = "${error.errorMsg} - ${error.permanent}";
    });
  }

  void statusListener(String status) {
    // print(
    // "Received listener status: $status, listening: ${speech.isListening}");
    setState(() {
      lastStatus = "$status";
    });
  }

  void checkConnection(ConnectivityResult result) {
    print('internet check: ' + result.toString());
    if (result == ConnectivityResult.none) {
      showNoInternetDialog();
    } else {
      try {
        InternetAddress.lookup('google.com').then((result) {
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            print('connected');
            isCurrentRouteFirst(context).then((value) {
              if (!value && showingNoIntenetDialog) Navigator.of(context).pop();
            });
          }
        });
      } on SocketException catch (_) {
        print('not connected');
        showNoInternetDialog();
      }
    }
  }

  // check if noInternet message is showing or not
  Future<bool> isCurrentRouteFirst(BuildContext context) {
    var completer = new Completer<bool>();
    Navigator.popUntil(context, (route) {
      completer.complete(route.isFirst);
      return true;
    });
    return completer.future;
  }

  void showNoInternetDialog() {
    if (!showingNoIntenetDialog) {
      showingNoIntenetDialog = true;
      showGeneralDialog(
        barrierLabel: "Barrier",
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.5),
        transitionDuration: Duration(milliseconds: 700),
        context: context,
        pageBuilder: (_, __, ___) {
          return Center(
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40), color: Colors.white),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'images/no_internet.png',
                    height: 100,
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Text(
                    'اینترنت در دسترس نیست!',
                    style: TextStyle(
                        fontFamily: 'Homa',
                        color: Colors.black,
                        decoration: TextDecoration.none,
                        fontSize: 22.0),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FlatButton(
                          child: Text(
                            'فعال سازی wifi',
                            style: TextStyle(
                              fontFamily: 'Homa',
                              color: Colors.black87,
                              fontSize: 14.0,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          onPressed: () {
                            Operations.jumpToWifiPage();
                            Navigator.of(context).pop();
                          }),
                      FlatButton(
                          child: Text(
                            'فعالسازی data',
                            style: TextStyle(
                              fontFamily: 'Homa',
                              color: Colors.black87,
                              fontSize: 14.0,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          onPressed: () {
                            Operations.jumpToDataPage();
                            Navigator.of(context).pop();
                          }),
                      FlatButton(
                          child: Text(
                            'خروج',
                            style: TextStyle(
                              fontFamily: 'Homa',
                              color: Colors.black87,
                              fontSize: 14.0,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          onPressed: () {
                            SystemNavigator.pop();
                            Navigator.of(context).pop();
                          }),
                    ],
                  ),
                ],
              ),
              margin: EdgeInsets.only(left: 12, right: 12),
            ),
          );
        },
        transitionBuilder: (_, anim, __, child) {
          return SlideTransition(
            position:
                Tween(begin: Offset(0, 1), end: Offset(0, 0)).animate(anim),
            child: child,
          );
        },
      );
    }
  }
}

// a data type for sender of message
enum MessageSender {
  user,
  system,
}

// message class
class Message {
  String msg;
  MessageSender sender;

  Message({this.msg, this.sender});
}
