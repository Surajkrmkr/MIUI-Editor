import 'package:flutter/material.dart';

enum UserProfiles {
  suraj,
  subhangi,
  rajat,
  abhishek,
  sumit,
  defaultUser,
}

class UserProfileProvider extends ChangeNotifier {
  UserProfiles activeUser = UserProfiles.defaultUser;

  set setUserProfile(UserProfiles user) {
    activeUser = user;
    notifyListeners();
  }
}

final Map<UserProfiles, Map<String, String>> users = {
  UserProfiles.suraj: {
    'user': 'u1',
    'image': 'assets/user1.png',
    'fontUrl': 'https://gitlab.com/Surajkrmkr/font-api/-/raw/main/fonts.json',
    'name': 'Suraj',
    'author': 'Sj'
  },
  UserProfiles.subhangi: {
    'user': 'u2',
    'image': 'assets/user2.png',
    'fontUrl': 'https://gitlab.com/piyushkpv/shadowgirl/-/raw/main/fonts.json',
    'name': 'Subhangi',
    'author': 'Subhangi'
  },
  UserProfiles.rajat: {
    'user': 'u3',
    'image': 'assets/user3.png',
    'fontUrl': 'https://gitlab.com/piyushkpv/font-api/-/raw/main/fonts.json',
    'name': 'Rajat',
    'author': 'Rajat'
  },
  UserProfiles.abhishek: {
    'user': 'u4',
    'image': 'assets/user4.png',
    'fontUrl': 'https://gitlab.com/piyushkpv/shadowgirl/-/raw/main/fonts.json',
    'name': 'Abhishek',
    'author': 'Abhishek'
  },
  UserProfiles.sumit: {
    'user': 'u5',
    'image': 'assets/user5.png',
    'fontUrl': 'https://gitlab.com/piyushkpv/font-api/-/raw/main/fonts.json',
    'name': 'Sumi7t',
    'author': 'Sumi7t'
  }
};
