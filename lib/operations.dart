import 'package:app_settings/app_settings.dart';
import 'package:url_launcher/url_launcher.dart';

enum Operation {
  search,
  open_app,
  turn_on_off,
  callNumber,
  callContact,
  textNumber,
  textContact,
  mail,
  play_music,
  play_movie,
  getInput,
  translateToEn,
  translateToAr,
  translateToTr,
  translateToEs,
  translateToDe,
  translateToFr,
  exit,
}

class Operations {
  static bool searchInGoogle(String content) {
    return launchURL('https://www.google.com/search?q=' + content.trim());
  }

  static bool launchURL(String url) {
    canLaunch(url).then((suessful) {
      if (suessful) {
        launch(url);
      }
      return suessful;
    });
  }

  static jumpToWifiPage() {
    AppSettings.openWIFISettings();
  }

  static jumpToDataPage() {
    AppSettings.openDataRoamingSettings();
  }

  static jumpToGPSPage() {
    AppSettings.openLocationSettings();
  }

  static jumpToBluetoothPage() {
    AppSettings.openBluetoothSettings();
  }

  static call(String phoneNumber) {
    launch("tel:" + phoneNumber);
  }

  static text(String phoneNumber) {
    launch("sms:" + phoneNumber);
  }

  static mail(String emailAddress) {
    launch("mailto:" + emailAddress);
  }

  static playMusic(int number) {
    launchURL(recommandedMusics.values.elementAt(number));
  }

  static final recommandedMusics = {
    'اگه یه روز از فرامرز اصلانی':
        'https://www.google.com/search?q=age+ye+rooz+faramarz+aslani',
    'lovely از بیلی آیلیش و خلید':
        'https://www.google.com/search?q=lovely+billie+eilish',
    'let me down slowly از آلک بنجامین':
        'https://www.google.com/search?q=let+me+down+slowly',
    'چشمه طوسی از محسن چاوشی':
        'https://www.google.com/search?q=محسن چاوشی cheshmeye toosi',
    'حماسه کولی از گروه کوئین':
        'https://www.google.com/search?q=bohemian+rhapsody+by+queen',
    'دور از هر جاده ای از handsome family':
        'https://www.google.com/search?q=The+Handsome+Family+-+Far+From+Any+Road',
    'بنی آدم از cold play': 'https://www.google.com/search?q=بنی+آدم+coldplay',
  };

  static final recommandedMovies = [
    'Shutter Island (2010)',
    "Schindler's List (1993)",
    "Tenet (2020)",
    "Interstellar (2014)",
    "V for Vendetta (2005)",
  ];
}
