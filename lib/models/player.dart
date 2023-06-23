class Player {
  String? firstName, secondName, webName, pointsPerGame, selectedByPercent;
  int? elementType,
      team,
      nowCost,
      totalPoints,
      bonus,
      goalsScored,
      assists,
      cleanSheets,
      goalsConceded,
      ownGoals,
      penaltiesMissed,
      yellowCards,
      redCards,
      starts,
      puzzzlePosition;
  bool? isUnveiled;

  Player(
      {this.firstName,
      this.secondName,
      this.webName,
      this.elementType,
      this.team,
      this.nowCost,
      this.totalPoints,
      this.bonus,
      this.goalsScored,
      this.assists,
      this.cleanSheets,
      this.goalsConceded,
      this.ownGoals,
      this.penaltiesMissed,
      this.yellowCards,
      this.redCards,
      this.starts,
      this.selectedByPercent,
      this.pointsPerGame,
      this.isUnveiled});

  Player.fromJson(Map<String, dynamic> json) {
    firstName = json['first_name'];
    secondName = json['second_name'];
    webName = json['web_name'];
    elementType = json['element_type'];
    team = json['team'];
    nowCost = json['now_cost'];
    totalPoints = json['total_points'];
    bonus = json['bonus'];
    goalsScored = json['goals_scored'];
    assists = json['assists'];
    cleanSheets = json['clean_sheets'];
    goalsConceded = json['goals_conceded'];
    ownGoals = json['own_goals'];
    penaltiesMissed = json['penalties_missed'];
    yellowCards = json['yellow_cards'];
    redCards = json['red_cards'];
    starts = json['starts'];
    selectedByPercent = json['selected_by_percent'];
    pointsPerGame = json['points_per_game'];
    isUnveiled = json['isUnveiled'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['first_name'] = firstName;
    data['second_name'] = secondName;
    data['web_name'] = webName;
    data['element_type'] = elementType;
    data['team'] = team;
    data['now_cost'] = nowCost;
    data['total_points'] = totalPoints;
    data['bonus'] = bonus;
    data['goals_scored'] = goalsScored;
    data['assists'] = assists;
    data['clean_sheets'] = cleanSheets;
    data['goals_conceded'] = goalsConceded;
    data['own_goals'] = ownGoals;
    data['penalties_missed'] = penaltiesMissed;
    data['yellow_cards'] = yellowCards;
    data['red_cards'] = redCards;
    data['starts'] = starts;
    data['selected_by_percent'] = selectedByPercent;
    data['points_per_game'] = pointsPerGame;
    data['isUnveiled'] = isUnveiled;
    return data;
  }
}
