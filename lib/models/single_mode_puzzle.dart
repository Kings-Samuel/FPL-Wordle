class SingleModePuzzle {
  String? player1,
      player2,
      player3,
      player4,
      player5,
      player1unveiled,
      player2unveiled,
      player3unveiled,
      player4unveiled,
      player5unveiled,
      allPlayersEncodedJSONstring;
  List<String>? selectedAttributes;
  int? lives, hints;
  bool? isFinished;

  SingleModePuzzle({
    this.player1,
    this.player2,
    this.player3,
    this.player4,
    this.player5,
    this.player1unveiled,
    this.player2unveiled,
    this.player3unveiled,
    this.player4unveiled,
    this.player5unveiled,
    this.allPlayersEncodedJSONstring,
    this.selectedAttributes,
    this.lives,
    this.hints,
    this.isFinished,
  });

  SingleModePuzzle.fromJson(Map<String, dynamic> json) {
    player1 = json['player1'];
    player2 = json['player2'];
    player3 = json['player3'];
    player4 = json['player4'];
    player5 = json['player5'];
    player1unveiled = json['player1unveiled'];
    player2unveiled = json['player2unveiled'];
    player3unveiled = json['player3unveiled'];
    player4unveiled = json['player4unveiled'];
    player5unveiled = json['player5unveiled'];
    allPlayersEncodedJSONstring = json['allPlayersEncodedJSONstring'];
    selectedAttributes = json['selectedAttributes'].cast<String>();
    lives = json['lives'];
    hints = json['hints'];
    isFinished = json['isFinished'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['player1'] = player1;
    data['player2'] = player2;
    data['player3'] = player3;
    data['player4'] = player4;
    data['player5'] = player5;
    data['player1unveiled'] = player1unveiled;
    data['player2unveiled'] = player2unveiled;
    data['player3unveiled'] = player3unveiled;
    data['player4unveiled'] = player4unveiled;
    data['player5unveiled'] = player5unveiled;
    data['allPlayersEncodedJSONstring'] = allPlayersEncodedJSONstring;
    data['selectedAttributes'] = selectedAttributes;
    data['lives'] = lives;
    data['hints'] = hints;
    data['isFinished'] = isFinished;
    return data;
  }
}
