enum UserProfileType { suraj, subhangi, rajat, abhishek, sumit, defaultUser }

class UserProfile {
  const UserProfile({
    required this.type,
    required this.iconFolder,
    required this.avatarAsset,
    required this.fontApiUrl,
    required this.displayName,
    required this.authorTag,
  });

  final UserProfileType type;
  final String iconFolder;
  final String avatarAsset;
  final String fontApiUrl;
  final String displayName;
  final String authorTag;
}

const Map<UserProfileType, UserProfile> kUserProfiles = {
  UserProfileType.suraj: UserProfile(
    type: UserProfileType.suraj,
    iconFolder: 'u1',
    avatarAsset: 'assets/users/suraj.png',
    fontApiUrl: 'https://gitlab.com/Surajkrmkr/font-api/-/raw/main/fonts.json',
    displayName: 'Suraj',
    authorTag: 'Sj',
  ),
  UserProfileType.subhangi: UserProfile(
    type: UserProfileType.subhangi,
    iconFolder: 'u2',
    avatarAsset: 'assets/users/subhangi.png',
    fontApiUrl: 'https://gitlab.com/piyushkpv/shadowgirl/-/raw/main/fonts.json',
    displayName: 'Subhangi',
    authorTag: 'Subhangi',
  ),
  UserProfileType.rajat: UserProfile(
    type: UserProfileType.rajat,
    iconFolder: 'u3',
    avatarAsset: 'assets/users/rajat.png',
    fontApiUrl: 'https://gitlab.com/piyushkpv/font-api/-/raw/main/fonts.json',
    displayName: 'Rajat',
    authorTag: 'Rajat',
  ),
  UserProfileType.abhishek: UserProfile(
    type: UserProfileType.abhishek,
    iconFolder: 'u4',
    avatarAsset: 'assets/users/abhishek.png',
    fontApiUrl: 'https://gitlab.com/piyushkpv/shadowgirl/-/raw/main/fonts.json',
    displayName: 'Abhishek',
    authorTag: 'Abhishek',
  ),
};
