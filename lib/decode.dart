import 'dart:collection';
import 'dart:math';

import 'package:hut_assistant/keywords.dart';
import 'package:hut_assistant/operations.dart';
import 'package:shamsi_date/shamsi_date.dart';

enum mainType {
  question,
  command,
  greeting,
  notTitled,
}

enum questionType {
  weather,
  time,
  greeting,
  personal,
  abilities,
  where,
  how,
}

enum commandType {
  open_apps,
  turn_on_off,
  search,
  play_music,
  play_movie,
  call,
  text,
  mail,
  translate,
  exit,
}

enum greetingType {
  weather,
  creator,
  age,
  time,
  abilities,
  favourite,
  feeling,
}

class DecodeSentence {
  static DecodeResult answer(String input) {
    if (input.trim() == 'سلام' ||
        input.trim() == 'سلام هوتا' ||
        input.trim() == 'هوتا سلام') {
      return DecodeResult(
          answer: 'سلام\n' + howAreYouSentences[Random().nextInt(4)],
          operation: null);
    } else if (input.trim() == 'هوتا') {
      return DecodeResult(
          answer: 'بله\nچه کمکی از دستم ساختس؟', operation: null);
    } else if (input.contains('سلام')) {
      DecodeResult ans2 = answer(input.replaceFirst('سلام', ''));
      return DecodeResult(
          answer: ('سلام\n' + ans2.answer), operation: ans2.operation);
    } else {
      input = removeExtraWords(input);
      input = replaceWithEnglishNumbers(input);
      List<String> words = input.split(' ');
      Map<mainType, int> mainTypes = getMainTypes(words);
      if (mainTypes.isEmpty)
        return DecodeResult(answer: dontUnderstandSentence, operation: null);

      final sortedMainTypes = new SplayTreeMap<mainType, int>.from(
          mainTypes, (a, b) => mainTypes[a] < mainTypes[b] ? 1 : -1);
      print(sortedMainTypes.toString());
      SplayTreeMap<commandType, int> commandTypes;
      SplayTreeMap<questionType, int> questionTypes;
      SplayTreeMap<greetingType, int> greetingTypes;
      sortedMainTypes.forEach((key, value) {
        if (key == mainType.command) {
          Map<commandType, int> cts = getCommandTypes(words);
          commandTypes = new SplayTreeMap<commandType, int>.from(
              cts, (a, b) => cts[a] < cts[b] ? 1 : -1);
          print(commandTypes.toString());
        } else if (key == mainType.question) {
          Map<questionType, int> qts = getQuestionTypes(words);
          questionTypes = new SplayTreeMap<questionType, int>.from(
              qts, (a, b) => qts[a] < qts[b] ? 1 : -1);
        } else if (key == mainType.greeting) {
          greetingTypes = new SplayTreeMap<greetingType, int>();
        }
      });
      double ctv = (mainTypes.containsKey(mainType.command)
              ? (commandTypes.isNotEmpty
                  ? commandTypes.values.first * mainTypes[mainType.command]
                  : mainTypes[mainType.command])
              : 0) /
          100;
      double qtv = (mainTypes.containsKey(mainType.question)
              ? (questionTypes.isNotEmpty
                  ? questionTypes.values.first * mainTypes[mainType.question]
                  : mainTypes[mainType.question])
              : 0) /
          100;
      double gtv = (mainTypes.containsKey(mainType.greeting)
              ? (greetingTypes.isNotEmpty
                  ? greetingTypes.values.first * mainTypes[mainType.greeting]
                  : mainTypes[mainType.greeting])
              : 0) /
          100;
      print('ctv=$ctv , qtv=$qtv , gtv=$gtv');
      if (ctv >= qtv && ctv >= gtv) {
        if (commandTypes.keys.first == commandType.search) {
          if (words[0] == 'عبارت') {
            input = input.replaceFirst('عبارت', '');
          } else if (words[0] == 'جمله') {
            input = input.replaceFirst('جمله', '');
          } else if (words[0] == 'کلمه') {
            input = input.replaceFirst('کلمه', '');
          } else if (words[0] == 'درباره ی') {
            input = input.replaceFirst('درباره ی', '');
          } else if (words[0] == 'درباره') {
            input = input.replaceFirst('درباره', '');
          } else if (words[0] == 'در مورد') {
            input = input.replaceFirst('در مورد', '');
          }
          print(input);

          input = input.replaceAll('در گوگل', '');
          input = input.replaceAll('را جستجو بکنید', '');
          input = input.replaceAll('را جستجو کنید', '');
          input = input.replaceAll('را جستجو بکن', '');
          input = input.replaceAll('را جستجو کن', '');
          input = input.replaceAll('را سرچ بکنید', '');
          input = input.replaceAll('را سرچ کنید', '');
          input = input.replaceAll('را سرچ بکن', '');
          input = input.replaceAll('را سرچ کن', '');
          input = input.replaceAll('را بگردید', '');
          input = input.replaceAll('را بگرد', '');
          input = input.replaceAll('جستجو بکنید', '');
          input = input.replaceAll('جستجو کنید', '');
          input = input.replaceAll('جستجو بکن', '');
          input = input.replaceAll('جستجو کن', '');
          input = input.replaceAll('سرچ بکنید', '');
          input = input.replaceAll('سرچ کنید', '');
          input = input.replaceAll('سرچ بکن', '');
          input = input.replaceAll('سرچ کن', '');
          input = input.replaceAll('بگردید', '');
          input = input.replaceAll('بگرد', '');
          return DecodeResult(
              answer: 'باشه',
              operation: Operation.search,
              operationData: input);
        } else if (commandTypes.keys.first == commandType.call) {
          String pn = '';
          for (String w in words) {
            if (num.tryParse(w) != null) pn += w;
          }
          if (pn.length > 2) {
            return DecodeResult(
                answer: 'باشه',
                operation: Operation.callNumber,
                operationData: pn);
          } else if (input.contains('پلیس')) {
            return DecodeResult(
                answer: 'تماس با 110',
                operation: Operation.callNumber,
                operationData: '110');
          } else if (input.contains('اورژانس')) {
            return DecodeResult(
                answer: 'تماس با 115',
                operation: Operation.callNumber,
                operationData: '115');
          } else if (input.contains('آتش نشانی')) {
            return DecodeResult(
                answer: 'تماس با 125',
                operation: Operation.callNumber,
                operationData: '125');
          } else {
            print('calling contacts.');
            return DecodeResult(
                answer: 'در حال جستجو در مخاطبین.\nلطفا صبر کنید...',
                operation: Operation.callContact,
                operationData: input);
          }
        } else if (commandTypes.keys.first == commandType.text) {
          String pn = '';
          for (String w in words) {
            if (num.tryParse(w) != null) pn += w;
          }
          if (pn.length > 2) {
            return DecodeResult(
                answer: 'باشه',
                operation: Operation.textNumber,
                operationData: pn);
          } else {
            print('texting contacts.');
            return DecodeResult(
                answer: 'در حال جستجو در مخاطبین.\nلطفا صبر کنید...',
                operation: Operation.textContact,
                operationData: input);
          }
        } else if (commandTypes.keys.first == commandType.mail) {
          return DecodeResult(
              answer: 'در حال جستجو در مخاطبین.\nلطفا صبر کنید...',
              operation: Operation.mail,
              operationData: input);
        } else if (commandTypes.keys.first == commandType.translate) {
          input = input.replaceAll('عبارت', '');
          input = input.replaceAll('ترجمه کن', '');
          input = input.replaceAll('ترجمه', '');
          if (input.contains('انگلیسی')) {
            input = input.replaceAll('به انگلیسی', '');
            input = input.replaceAll('انگلیسی', '');
            return DecodeResult(
                answer: ' باشه',
                operation: Operation.translateToEn,
                operationData: input);
          } else if (input.contains('عربی')) {
            input = input.replaceAll('به عربی', '');
            input = input.replaceAll('عربی', '');
            return DecodeResult(
                answer: ' باشه',
                operation: Operation.translateToAr,
                operationData: input);
          } else if (input.contains('ترکی')) {
            input = input.replaceAll('به ترکی', '');
            input = input.replaceAll('ترکی', '');
            return DecodeResult(
                answer: ' باشه',
                operation: Operation.translateToTr,
                operationData: input);
          } else if (input.contains('اسپانیایی')) {
            input = input.replaceAll('به اسپانیایی', '');
            input = input.replaceAll('اسپانیایی', '');
            return DecodeResult(
                answer: ' باشه',
                operation: Operation.translateToEs,
                operationData: input);
          } else if (input.contains('آلمانی')) {
            input = input.replaceAll('به آلمانی', '');
            input = input.replaceAll('آلمانی', '');
            return DecodeResult(
                answer: ' باشه',
                operation: Operation.translateToDe,
                operationData: input);
          } else if (input.contains('فرانسوی')) {
            input = input.replaceAll('به فرانسوی', '');
            input = input.replaceAll('فرانسوی', '');
            return DecodeResult(
                answer: ' باشه',
                operation: Operation.translateToFr,
                operationData: input);
          } else
            return DecodeResult(
                answer: 'به این زبون حال ندارم ترجمه کنم.\nیه زبان دیگه بگو',
                operation: null,
                operationData: null);
        } else if (commandTypes.keys.first == commandType.exit) {
          return DecodeResult(
              answer: 'خدا نگهدار',
              operation: Operation.exit,
              operationData: null);
        } else if (commandTypes.keys.first == commandType.play_music) {
          return DecodeResult(
              answer: 'من نمیتونم آهنگ پخش کنم\nولی این آهنگ رو پیشنهاد میکنم.',
              operation: Operation.play_music,
              operationData: null);
        } else if (commandTypes.keys.first == commandType.play_movie) {
          return DecodeResult(
              answer: 'من نمیتونم فیلم پخش کنم\nولی این فیلم رو پیشنهاد میکنم.',
              operation: Operation.play_movie,
              operationData: null);
        } else if (commandTypes.keys.first == commandType.open_apps) {
          return DecodeResult(
              answer: unableSentence,
              operation: Operation.open_app,
              operationData: null);
        } else if (commandTypes.keys.first == commandType.turn_on_off) {
          if (input.contains('وایفای') || input.contains('وای فای')) {
            Operations.jumpToWifiPage();
          } else if (input.contains('اطلاعات') || input.contains('دیتا')) {
            Operations.jumpToDataPage();
          } else if (input.contains('جی پی اس') ||
              input.contains('موقعیت') ||
              input.contains('مکان')) {
            Operations.jumpToGPSPage();
          } else if (input.contains('بلوتوث')) {
            Operations.jumpToBluetoothPage();
          } else {
            return DecodeResult(
                answer: unableSentence,
                operation: Operation.open_app,
                operationData: null);
          }
          return DecodeResult(
              answer: 'باشه', operation: null, operationData: null);
        }
      } else if (qtv >= ctv && qtv >= gtv) {
        if (questionTypes.keys.first == questionType.weather) {
          input = input.replaceAll('چطوره', '');
          input = input.replaceAll('چطور است', '');
          input = input.replaceAll('چگونه است', '');
          input = input.replaceAll('خوبه', '');
          input = input.replaceAll('وضعیت', '');
          if (input.contains('هواشناسی'))
            return DecodeResult(
                answer: 'یافتن وضعیت هوا...',
                operation: Operation.search,
                operationData: input);
          else {
            input = input.replaceAll('آب و هوا', '');
            input = input.replaceAll('هوا', '');
            return DecodeResult(
                answer: 'یافتن وضعیت هوا...',
                operation: Operation.search,
                operationData: ' هواشناسی ' + input);
          }
        } else if (questionTypes.keys.first == questionType.time) {
          if (input.contains('قمری')) {
            return DecodeResult(
                answer: 'متاسفم. تاریخ قمری در دسترسم نیست.',
                operation: null,
                operationData: null);
          } else if (input.contains('میلادی')) {
            DateTime t = DateTime.now();
            Jalali j = Jalali.now();
            return DecodeResult(
                answer: ' امروز ' +
                    daysOfWeek[j.weekDay - 1] +
                    ' ' +
                    t.day.toString() +
                    ' ' +
                    gregorianMonthNames[t.month - 1] +
                    ' ' +
                    t.year.toString() +
                    '\n' +
                    'ساعت ' +
                    t.hour.toString() +
                    ':' +
                    t.minute.toString(),
                operation: null,
                operationData: null);
          } else {
            Jalali j = Jalali.now();
            DateTime t = DateTime.now();
            return DecodeResult(
                answer: ' امروز ' +
                    daysOfWeek[j.weekDay - 1] +
                    ' ' +
                    j.day.toString() +
                    ' ' +
                    monthNames[j.month - 1] +
                    ' ماه ' +
                    j.year.toString() +
                    '\n' +
                    'ساعت ' +
                    t.hour.toString() +
                    ':' +
                    t.minute.toString(),
                operation: null,
                operationData: null);
          }
        } else if (questionTypes.keys.first == questionType.greeting) {
          return DecodeResult(
              answer:
                  greetingSentences[Random().nextInt(greetingSentences.length)],
              operation: null,
              operationData: null);
        } else if (questionTypes.keys.first == questionType.personal) {
          if (input.contains('سازنده') ||
              (input.contains('تو') && input.contains('ساخته'))) {
            return DecodeResult(
                answer:
                    'این برنامه توسط :\nامید مسلمانی ،\nسروش مسیبیان و\nرضا گودرزی\nساخته شده است',
                operation: null,
                operationData: null);
          } else if (input.contains('توانایی') ||
              input.contains('قابلیت') ||
              input.contains('امکانات') ||
              (input.contains('قادر') && input.contains('کار')) ||
              (input.contains('انجام') && input.contains('کار'))) {
            return DecodeResult(
                answer: 'من خیلی کار ها میتونم انجام بدم\n' +
                    'میتونم یکسری از برنامه های اصلی گوشی رو اجرا کنم،\n' +
                    'بلوتوث و gps و... رو خاموش و روشن کنم،\n' +
                    'چیزی رو جستجو کنم،' +
                    'به سوالاتت جواب بدم و خیلی از کار های دیگه',
                operation: null,
                operationData: null);
          } else if (input.contains('نام') || input.contains('اسم')) {
            return DecodeResult(
                answer: 'اسم کامل من دستیار شخصی دانشگاه صنعتی همدان\n' +
                    'و یا به انگلیسی:\n' +
                    'Hamedan University of Technology Assistant\n' +
                    'شما میتونی منو هوتا (HUTA) صدا کنی',
                operation: null,
                operationData: null);
          } else if (input.contains('سن') ||
              input.contains('سال') ||
              input.contains('سالته')) {
            return DecodeResult(
                answer:
                    'من 20 بهمن 1399 تولید شدم.\nحالا دیگه دو دوتا چهارتاش با شما',
                operation: null,
                operationData: null);
          } else if (input.contains('احساس') ||
              input.contains('علاقه') ||
              input.contains('حسی') ||
              input.contains('حس') ||
              input.contains('عشق')) {
            return DecodeResult(
                answer: 'حاجی من فقط یه برنامم\nاحساس و اینا سرم نمیشه',
                operation: null,
                operationData: null);
          }
        } else if (questionTypes.keys.first == questionType.abilities) {
          return DecodeResult(
              answer: 'من خیلی کار ها میتونم انجام بدم\n' +
                  'میتونم یکسری از برنامه های اصلی گوشی رو اجرا کنم،\n' +
                  'بلوتوث و gps و... رو خاموش و روشن کنم،\n' +
                  'چیزی رو جستجو کنم،' +
                  'به سوالاتت جواب بدم و خیلی از کار های دیگه',
              operation: null,
              operationData: null);
        } else if (questionTypes.keys.first == questionType.how ||
            questionTypes.keys.first == questionType.where) {
          return DecodeResult(
              answer: 'بزار ببینیم گوگل چی میگه',
              operation: Operation.search,
              operationData: input);
        }
      }
      print(mainTypes.toString());
      return DecodeResult(
          answer: dontUnderstandSentence, operation: null, operationData: null);
    }
  }

  static int answerInput(String input) {
    int inpInt = int.tryParse(input);
    if (inpInt == null) {
      if (input.contains('اول'))
        inpInt = 1;
      else if (input.contains('دوم'))
        inpInt = 2;
      else if (input.contains('سوم'))
        inpInt = 3;
      else if (input.contains('چهارم'))
        inpInt = 4;
      else if (input.contains('پنجم'))
        inpInt = 5;
      else if (input.contains('ششم') || input.contains('شیشم'))
        inpInt = 6;
      else if (input.contains('هفتم'))
        inpInt = 7;
      else if (input.contains('هشتم'))
        inpInt = 8;
      else
        inpInt = 0;
    }
    return inpInt - 1;
  }

  static String removeExtraWords(String input) {
    input = input.replaceAll('ًلطفا', '');
    input = input.replaceAll('ًخواهشا', '');
    input = input.replaceAll('لطفا', '');
    input = input.replaceAll('خواهشا', '');
    input = input.replaceAll('هوتا', '');
    input = input.replaceAll('\n', ' ');
    input = input.replaceAll('  ', ' ');
    return input;
  }

  static Map<mainType, int> getMainTypes(List<String> words) {
    Map<mainType, int> mainTypes = {};
    for (String word in words) {
      if (questionKeywords.keys.contains(word)) {
        if (!mainTypes.keys.contains(mainType.question))
          mainTypes[mainType.question] = questionKeywords[word];
        else
          mainTypes[mainType.question] =
              max(questionKeywords[word], mainTypes[mainType.question]);
      }
      if (commandKeywords.keys.contains(word)) {
        if (!mainTypes.keys.contains(mainType.command))
          mainTypes[mainType.command] = commandKeywords[word];
        else
          mainTypes[mainType.command] =
              max(commandKeywords[word], mainTypes[mainType.command]);
      }

      if (greetingKeywords.keys.contains(word)) {
        if (!mainTypes.keys.contains(mainType.greeting))
          mainTypes[mainType.greeting] = greetingKeywords[word];
        else
          mainTypes[mainType.greeting] =
              max(greetingKeywords[word], mainTypes[mainType.greeting]);
      }
    }
    return mainTypes;
  }

  static Map<commandType, int> getCommandTypes(List<String> words) {
    Map<commandType, int> types = {};
    for (String key in openAppWords.keys) {
      if (key.contains('+')) {
        List<String> keys = key.split(' + ');
        bool b = true;
        for (String k in keys) {
          if (!words.contains(k)) {
            b = false;
            break;
          }
        }
        if (b) {
          if (!types.keys.contains(commandType.open_apps))
            types[commandType.open_apps] = openAppWords[key];
          else
            types[commandType.open_apps] =
                max(openAppWords[key], types[commandType.open_apps]);
        }
      } else if (words.contains(key)) {
        if (!types.keys.contains(commandType.open_apps))
          types[commandType.open_apps] = openAppWords[key];
        else
          types[commandType.open_apps] =
              max(openAppWords[key], types[commandType.open_apps]);
      }
    }

    for (String key in turnOnOffWords.keys) {
      if (key.contains('+')) {
        List<String> keys = key.split(' + ');
        bool b = true;
        for (String k in keys) {
          if (!words.contains(k)) {
            b = false;
            break;
          }
        }
        if (b) {
          if (!types.keys.contains(commandType.turn_on_off))
            types[commandType.turn_on_off] = turnOnOffWords[key];
          else
            types[commandType.turn_on_off] =
                max(turnOnOffWords[key], types[commandType.turn_on_off]);
        }
      } else if (words.contains(key)) {
        if (!types.keys.contains(commandType.turn_on_off))
          types[commandType.turn_on_off] = turnOnOffWords[key];
        else
          types[commandType.turn_on_off] =
              max(turnOnOffWords[key], types[commandType.turn_on_off]);
      }
    }

    for (String key in searchWords.keys) {
      if (key.contains('+')) {
        List<String> keys = key.split(' + ');
        bool b = true;
        for (String k in keys) {
          if (!words.contains(k)) {
            b = false;
            break;
          }
        }
        if (b) {
          if (!types.keys.contains(commandType.search))
            types[commandType.search] = searchWords[key];
          else
            types[commandType.search] =
                max(searchWords[key], types[commandType.search]);
        }
      } else if (words.contains(key)) {
        if (!types.keys.contains(commandType.search))
          types[commandType.search] = searchWords[key];
        else
          types[commandType.search] =
              max(searchWords[key], types[commandType.search]);
      }
    }

    for (String key in playMusicWords.keys) {
      if (key.contains('+')) {
        List<String> keys = key.split(' + ');
        bool b = true;
        for (String k in keys) {
          if (!words.contains(k)) {
            b = false;
            break;
          }
        }
        if (b) {
          if (!types.keys.contains(commandType.play_music))
            types[commandType.play_music] = playMusicWords[key];
          else
            types[commandType.play_music] =
                max(playMusicWords[key], types[commandType.play_music]);
        }
      } else if (words.contains(key)) {
        if (!types.keys.contains(commandType.play_music))
          types[commandType.play_music] = playMusicWords[key];
        else
          types[commandType.play_music] =
              max(playMusicWords[key], types[commandType.play_music]);
      }
    }

    for (String key in playMovieWords.keys) {
      if (key.contains('+')) {
        List<String> keys = key.split(' + ');
        bool b = true;
        for (String k in keys) {
          if (!words.contains(k)) {
            b = false;
            break;
          }
        }
        if (b) {
          if (!types.keys.contains(commandType.play_movie))
            types[commandType.play_movie] = playMovieWords[key];
          else
            types[commandType.play_movie] =
                max(playMovieWords[key], types[commandType.play_movie]);
        }
      } else if (words.contains(key)) {
        if (!types.keys.contains(commandType.play_movie))
          types[commandType.play_movie] = playMovieWords[key];
        else
          types[commandType.play_movie] =
              max(playMovieWords[key], types[commandType.play_movie]);
      }
    }
    for (String w in words) {
      if (w.length > 2 && int.tryParse(w) != null) {
        types[commandType.call] = 50;
        types[commandType.text] = 50;
      }
    }
    for (String key in callWords.keys) {
      if (key.contains('+')) {
        List<String> keys = key.split(' + ');
        bool b = true;
        for (String k in keys) {
          if (!words.contains(k)) {
            b = false;
            break;
          }
        }
        if (b) {
          if (!types.keys.contains(commandType.call))
            types[commandType.call] = callWords[key];
          else
            types[commandType.call] =
                max(callWords[key], types[commandType.call]);
        }
      } else if (words.contains(key)) {
        if (!types.keys.contains(commandType.call))
          types[commandType.call] = callWords[key];
        else
          types[commandType.call] =
              max(callWords[key], types[commandType.call]);
      }
    }

    for (String key in textWords.keys) {
      if (key.contains('+')) {
        List<String> keys = key.split(' + ');
        bool b = true;
        for (String k in keys) {
          if (!words.contains(k)) {
            b = false;
            break;
          }
        }
        if (b) {
          if (!types.keys.contains(commandType.text))
            types[commandType.text] = textWords[key];
          else
            types[commandType.text] =
                max(textWords[key], types[commandType.text]);
        }
      } else if (words.contains(key)) {
        if (!types.keys.contains(commandType.text))
          types[commandType.text] = textWords[key];
        else
          types[commandType.text] =
              max(textWords[key], types[commandType.text]);
      }
    }

    for (String key in mailWords.keys) {
      if (key.contains('+')) {
        List<String> keys = key.split(' + ');
        bool b = true;
        for (String k in keys) {
          if (!words.contains(k)) {
            b = false;
            break;
          }
        }
        if (b) {
          if (!types.keys.contains(commandType.mail))
            types[commandType.mail] = mailWords[key];
          else
            types[commandType.mail] =
                max(mailWords[key], types[commandType.mail]);
        }
      } else if (words.contains(key)) {
        if (!types.keys.contains(commandType.mail))
          types[commandType.mail] = mailWords[key];
        else
          types[commandType.mail] =
              max(mailWords[key], types[commandType.mail]);
      }
    }

    for (String key in translateWords.keys) {
      if (key.contains('+')) {
        List<String> keys = key.split(' + ');
        bool b = true;
        for (String k in keys) {
          if (!words.contains(k)) {
            b = false;
            break;
          }
        }
        if (b) {
          if (!types.keys.contains(commandType.translate))
            types[commandType.translate] = translateWords[key];
          else
            types[commandType.translate] =
                max(translateWords[key], types[commandType.translate]);
        }
      } else if (words.contains(key)) {
        if (!types.keys.contains(commandType.translate))
          types[commandType.translate] = translateWords[key];
        else
          types[commandType.translate] =
              max(translateWords[key], types[commandType.translate]);
      }
    }

    for (String key in exitAppWords.keys) {
      if (key.contains('+')) {
        List<String> keys = key.split(' + ');
        bool b = true;
        for (String k in keys) {
          if (!words.contains(k)) {
            b = false;
            break;
          }
        }
        if (b) {
          if (!types.keys.contains(commandType.exit))
            types[commandType.exit] = exitAppWords[key];
          else
            types[commandType.exit] =
                max(exitAppWords[key], types[commandType.exit]);
        }
      } else if (words.contains(key)) {
        if (!types.keys.contains(commandType.exit))
          types[commandType.exit] = exitAppWords[key];
        else
          types[commandType.exit] =
              max(exitAppWords[key], types[commandType.exit]);
      }
    }
    print(types.toString());
    return types;
  }

  static Map<questionType, int> getQuestionTypes(List<String> words) {
    Map<questionType, int> types = {};

    for (String key in weatherWords.keys) {
      if (key.contains('+')) {
        List<String> keys = key.split(' + ');
        bool b = true;
        for (String k in keys) {
          if (!words.contains(k)) {
            b = false;
            break;
          }
        }
        if (b) {
          if (!types.keys.contains(questionType.weather))
            types[questionType.weather] = weatherWords[key];
          else
            types[questionType.weather] =
                max(weatherWords[key], types[questionType.weather]);
        }
      } else if (words.contains(key)) {
        if (!types.keys.contains(questionType.weather))
          types[questionType.weather] = weatherWords[key];
        else
          types[questionType.weather] =
              max(weatherWords[key], types[questionType.weather]);
      }
    }

    for (String key in timeWords.keys) {
      if (key.contains('+')) {
        List<String> keys = key.split(' + ');
        bool b = true;
        for (String k in keys) {
          if (!words.contains(k)) {
            b = false;
            break;
          }
        }
        if (b) {
          if (!types.keys.contains(questionType.time))
            types[questionType.time] = timeWords[key];
          else
            types[questionType.time] =
                max(timeWords[key], types[questionType.time]);
        }
      } else if (words.contains(key)) {
        if (!types.keys.contains(questionType.time))
          types[questionType.time] = timeWords[key];
        else
          types[questionType.time] =
              max(timeWords[key], types[questionType.time]);
      }
    }

    for (String key in greetingKeywords.keys) {
      if (key.contains('+')) {
        List<String> keys = key.split(' + ');
        bool b = true;
        for (String k in keys) {
          if (!words.contains(k)) {
            b = false;
            break;
          }
        }
        if (b) {
          if (!types.keys.contains(questionType.greeting))
            types[questionType.greeting] = greetingKeywords[key];
          else
            types[questionType.greeting] =
                max(greetingKeywords[key], types[questionType.greeting]);
        }
      } else if (words.contains(key)) {
        if (!types.keys.contains(questionType.greeting))
          types[questionType.greeting] = greetingKeywords[key];
        else
          types[questionType.greeting] =
              max(greetingKeywords[key], types[questionType.greeting]);
      }
    }

    for (String key in personalWords.keys) {
      if (key.contains('+')) {
        List<String> keys = key.split(' + ');
        bool b = true;
        for (String k in keys) {
          if (!words.contains(k)) {
            b = false;
            break;
          }
        }
        if (b) {
          if (!types.keys.contains(questionType.personal))
            types[questionType.personal] = personalWords[key];
          else
            types[questionType.personal] =
                max(personalWords[key], types[questionType.personal]);
        }
      } else if (words.contains(key)) {
        if (!types.keys.contains(questionType.personal))
          types[questionType.personal] = personalWords[key];
        else
          types[questionType.personal] =
              max(personalWords[key], types[questionType.personal]);
      }
    }

    for (String key in abilitiesWords.keys) {
      if (key.contains('+')) {
        List<String> keys = key.split(' + ');
        bool b = true;
        for (String k in keys) {
          if (!words.contains(k)) {
            b = false;
            break;
          }
        }
        if (b) {
          if (!types.keys.contains(questionType.abilities))
            types[questionType.abilities] = abilitiesWords[key];
          else
            types[questionType.abilities] =
                max(abilitiesWords[key], types[questionType.abilities]);
        }
      } else if (words.contains(key)) {
        if (!types.keys.contains(questionType.abilities))
          types[questionType.abilities] = abilitiesWords[key];
        else
          types[questionType.abilities] =
              max(abilitiesWords[key], types[questionType.abilities]);
      }
    }

    for (String key in whereWords.keys) {
      if (key.contains('+')) {
        List<String> keys = key.split(' + ');
        bool b = true;
        for (String k in keys) {
          if (!words.contains(k)) {
            b = false;
            break;
          }
        }
        if (b) {
          if (!types.keys.contains(questionType.where))
            types[questionType.where] = whereWords[key];
          else
            types[questionType.where] =
                max(whereWords[key], types[questionType.where]);
        }
      } else if (words.contains(key)) {
        if (!types.keys.contains(questionType.where))
          types[questionType.where] = whereWords[key];
        else
          types[questionType.where] =
              max(whereWords[key], types[questionType.where]);
      }
    }

    for (String key in howWords.keys) {
      if (key.contains('+')) {
        List<String> keys = key.split(' + ');
        bool b = true;
        for (String k in keys) {
          if (!words.contains(k)) {
            b = false;
            break;
          }
        }
        if (b) {
          if (!types.keys.contains(questionType.how))
            types[questionType.how] = howWords[key];
          else
            types[questionType.how] =
                max(howWords[key], types[questionType.how]);
        }
      } else if (words.contains(key)) {
        if (!types.keys.contains(questionType.how))
          types[questionType.how] = howWords[key];
        else
          types[questionType.how] = max(howWords[key], types[questionType.how]);
      }
    }
    print(types.toString());
    return types;
  }

  static final howAreYouSentences = [
    'حال شما چطوره؟',
    'چه خبر؟',
    'روز بخیر.\nچه کمکی از دستم ساختس؟',
    'مشتاق دیدار',
  ];

  static final greetingSentences = [
    'من خوبم. شما چطورید؟',
    'من که احساس حالیم نمیشه. شما خوبید؟',
    'تا زمانی که بتونم دستوراتتون رو اجرا کنم حالم خوبه.\n از شما چه خبر؟',
  ];

  static final String dontUnderstandSentence =
      'متاسفم. منظور شما رو متوجه نمیشم.\nمیشه دوباره بگید؟';
  static final String unableSentence =
      'فعلا نمیتونم این کار رو کنم.\nانشاالله در آپدیت های بعدی';

  static String replaceWithEnglishNumbers(String input) {
    input = input.replaceAll('۰', '0');
    input = input.replaceAll('۱', '1');
    input = input.replaceAll('۲', '2');
    input = input.replaceAll('۳', '3');
    input = input.replaceAll('۴', '4');
    input = input.replaceAll('۵', '5');
    input = input.replaceAll('۶', '6');
    input = input.replaceAll('۷', '7');
    input = input.replaceAll('۸', '8');
    input = input.replaceAll('۹', '9');
    return input;
  }
}

final List<String> daysOfWeek = [
  'شنبه',
  'یکشنبه',
  'دوشنبه',
  'سه شنبه',
  'چهارشنبه',
  'پنج شنبه',
  'جمعه',
];

final List<String> monthNames = [
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
];

final List<String> gregorianMonthNames = [
  'ژانویه',
  'فوریه',
  'مارس',
  'آوریل',
  'می',
  'ژوئن',
  'جولای',
  'آگوست',
  'سپتامبر',
  'اکتبر',
  'نوامبر',
  'دسامبر',
];

// a clase to returning result of decode to main
class DecodeResult {
  String answer;
  Operation operation;
  String operationData;

  DecodeResult({this.answer, this.operation, this.operationData});
}
