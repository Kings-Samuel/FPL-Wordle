class Profile {
  String? id, premiumMembershipExpDate;
  int? coins,
      gamesPlayed,
      gamesWon,
      gamesLost,
      gamesAbandoned,
      longestWinStreak,
      difficulty,
      totalXP,
      highScore,
      // playedToday,
      playersFound,
      correctFirstGuess,
      noHintsUsed,
      scoresShared;
  // multiplayerModePlayed,
  // winsInMultiplayerMode;
  // Achievements? achievements;
  bool? isPremiumMember;

  Profile({
    this.id,
    this.coins,
    this.gamesPlayed,
    this.gamesWon,
    this.gamesLost,
    this.gamesAbandoned,
    this.premiumMembershipExpDate,
    this.longestWinStreak,
    this.difficulty,
    this.isPremiumMember,
    this.totalXP,
    this.highScore,
    // this.playedToday, // ! this doesn't need to be updated once the value equals 3
    this.playersFound,
    this.correctFirstGuess,
    this.noHintsUsed,
    this.scoresShared,
    // this.multiplayerModePlayed,
    // this.winsInMultiplayerMode,
    // this.achievements,
  });

  Profile.fromJson(Map<String, dynamic> json) {
    id = json["\$id"];
    coins = json['coins'];
    gamesPlayed = json['gamesPlayed'];
    gamesWon = json['gamesWon'];
    gamesLost = json['gamesLost'];
    gamesAbandoned = json['gamesAbandoned'];
    premiumMembershipExpDate = json['premiumMembershipExpDate'];
    longestWinStreak = json['longestWinStreak'];
    difficulty = json['difficulty'];
    isPremiumMember = json['isPremiumMember'];
    totalXP = json['totalXP'];
    highScore = json['highScore'];
    // playedToday = json['playedToday'];
    playersFound = json['playersFound'];
    correctFirstGuess = json['correctFirstGuess'];
    noHintsUsed = json['noHintsUsed'];
    scoresShared = json['scoresShared'];
    // multiplayerModePlayed = json['multiplayerModePlayed'];
    // winsInMultiplayerMode = json['winsInMultiplayerMode'];
    // achievements = json['achievements'] != null ? Achievements.fromJson(json['achievements']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['coins'] = coins;
    data['gamesPlayed'] = gamesPlayed;
    data['gamesWon'] = gamesWon;
    data['gamesLost'] = gamesLost;
    data['gamesAbandoned'] = gamesAbandoned;
    data['premiumMembershipExpDate'] = premiumMembershipExpDate;
    data['longestWinStreak'] = longestWinStreak;
    data['difficulty'] = difficulty;
    data['isPremiumMember'] = isPremiumMember;
    data['totalXP'] = totalXP;
    data['highScore'] = highScore;
    // data['playedToday'] = playedToday;
    data['playersFound'] = playersFound;
    data['correctFirstGuess'] = correctFirstGuess;
    data['noHintsUsed'] = noHintsUsed;
    data['scoresShared'] = scoresShared;
    // data['multiplayerModePlayed'] = multiplayerModePlayed;
    // data['winsInMultiplayerMode'] = winsInMultiplayerMode;
    // if (achievements != null) {
    //   data['achievements'] = achievements!.toJson();
    // }
    return data;
  }
}

class Achievements {
  String? id;
  bool? gamesPlayedX5,
      gamesPlayedX10,
      gamesPlayedX20,
      gamesInOneDayX3,
      winningStreakX5,
      playersFoundX25,
      playersFoundX50,
      correctFirstGuessX10,
      playAgameInMultiPlayerMode,
      winsInMultiplayerModeX5,
      noHintsUsedX5,
      scoresSharedX3,
      scoresSharedX10;

  Achievements({
    this.id,
    this.gamesPlayedX5,
    this.gamesPlayedX10,
    this.gamesPlayedX20,
    this.gamesInOneDayX3,
    this.winningStreakX5,
    this.playersFoundX25,
    this.playersFoundX50,
    this.correctFirstGuessX10,
    this.playAgameInMultiPlayerMode,
    this.winsInMultiplayerModeX5,
    this.noHintsUsedX5,
    this.scoresSharedX3,
    this.scoresSharedX10,
  });

  Achievements.fromJson(Map<String, dynamic> json) {
    id = json["\$id"];
    gamesPlayedX5 = json['gamesPlayedX5'];
    gamesPlayedX10 = json['gamesPlayedX10'];
    gamesPlayedX20 = json['gamesPlayedX20'];
    gamesInOneDayX3 = json['gamesInOneDayX3'];
    winningStreakX5 = json['winningStreakX5'];
    playersFoundX25 = json['playersFoundX25'];
    playersFoundX50 = json['playersFoundX50'];
    correctFirstGuessX10 = json['correctFirstGuessX10'];
    playAgameInMultiPlayerMode = json['playAgameInMultiPlayerMode'];
    winsInMultiplayerModeX5 = json['winsInMultiplayerModeX5'];
    noHintsUsedX5 = json['noHintsUsedX5'];
    scoresSharedX3 = json['scoresSharedX3'];
    scoresSharedX10 = json['scoresSharedX10'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['\$id'] = id;
    data['gamesPlayedX5'] = gamesPlayedX5;
    data['gamesPlayedX10'] = gamesPlayedX10;
    data['gamesPlayedX20'] = gamesPlayedX20;
    data['gamesInOneDayX3'] = gamesInOneDayX3;
    data['winningStreakX5'] = winningStreakX5;
    data['playersFoundX25'] = playersFoundX25;
    data['playersFoundX50'] = playersFoundX50;
    data['correctFirstGuessX10'] = correctFirstGuessX10;
    data['playAgameInMultiPlayerMode'] = playAgameInMultiPlayerMode;
    data['winsInMultiplayerModeX5'] = winsInMultiplayerModeX5;
    data['noHintsUsedX5'] = noHintsUsedX5;
    data['scoresSharedX3'] = scoresSharedX3;
    data['scoresSharedX10'] = scoresSharedX10;
    return data;
  }
}
