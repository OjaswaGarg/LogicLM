@Engine("duckdb");

LogicLM(
  name: "Sports Injury Analysis",
  title: "Game, Stadium, and Injury Data Exploration",
  tagline: "<i>Explore relationships between games, stadiums, and player injuries.</i>",
  port: 8089,
  fact_tables: ["InjuryFactTable"],
  default_fact_table: "InjuryFactTable",

  dimensions: [
    "InjuryId", "PlayerName", "InjuryDescription", "InjurySource",
    "GameId", "GameSeason", "GameDate", "HomeTeam", "AwayTeam", "GameScore", "GameCompetition",
    "StadiumId", "StadiumName"
  ],

  measures: [
    "NumInjuries", "NumPlayersInjured", "NumGamesWithInjuries", "NumStadiumsWithInjuries",
    "NumCompetitionsWithInjuries", "NumHomeTeamsWithInjuries", "NumAwayTeamsWithInjuries",
    "AvgMatchesMissed", "MinMatchesMissed", "MaxMatchesMissed",
    "AvgStadiumAttendanceInjuryGames", "TotalStadiumHomeGames", "AvgStadiumCapacityPctInjuryGames"
  ],

  filters: [
     "PlayerIs", "InjuryDescContains", "SeasonIs", "CompetitionIs", "HomeTeamIs", "AwayTeamIs",
     "TeamIs", "StadiumIs", "DateIs", "DateAfter", "DateBefore", "DateBetween",
     "MatchesMissedIs", "MatchesMissedMoreThan", "MatchesMissedLessThan"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Dimensions, Measures, and Filters should be predicate calls, e.g., [StadiumName(), NumInjuries()].",
    "For filters, provide arguments, e.g., SeasonIs(seasons: [2022, 2023]), MatchesMissedMoreThan(num_matches: 5).",
    "Use list syntax for multiple filter values: PlayerIs(player_names: ['Player A', 'Player B']).",
    "The central unit of analysis is an individual injury record linked to its game and stadium.",
    "Order results using 'order:', e.g., order: [NumInjuries() desc].",
    "Use -1 for no limit.",
    "The 'number_of_matches' column is text; queries attempt conversion but may yield null for non-numeric entries or during aggregation."
  ]
);

SafeMatchesMissed(matches_text) = ToInt(matches_text) :- StringIsNumeric(matches_text);
SafeMatchesMissed(matches_text) = null :- ~StringIsNumeric(matches_text);

InjuryFactTableT(
    injury_id:, player_name:, injury_desc:, matches_missed_str:, injury_source:,
    game_id:, game_season:, game_date:, home_team:, away_team:, game_score:, game_competition:,
    stadium_id:, stadium_name:, stadium_home_games:, stadium_avg_attendance:, stadium_capacity_pct:
  ) :-
  injury_accident(id: injury_id, player: player_name, injury: injury_desc, number_of_matches: matches_missed_str, source: injury_source, game_id: game_id_ref),
  game(id: game_id_ref, stadium_id: stadium_id_ref, season: game_season, date: game_date, home_team:, away_team:, score: game_score, competition: game_competition),
  stadium(id: stadium_id_ref, name: stadium_name, home_games: stadium_home_games, average_attendance: stadium_avg_attendance, capacity_percentage: stadium_capacity_pct),
  game_id == game_id_ref,
  stadium_id == stadium_id_ref;

InjuryFactTable(r) :- InjuryFactTableT(..r);

InjuryId(fact) = fact.injury_id;
PlayerName(fact) = fact.player_name;
InjuryDescription(fact) = fact.injury_desc;
InjurySource(fact) = fact.injury_source;
GameId(fact) = fact.game_id;
GameSeason(fact) = fact.game_season;
GameDate(fact) = fact.game_date;
HomeTeam(fact) = fact.home_team;
AwayTeam(fact) = fact.away_team;
GameScore(fact) = fact.game_score;
GameCompetition(fact) = fact.game_competition;
StadiumId(fact) = fact.stadium_id;
StadiumName(fact) = fact.stadium_name;

NumInjuries(fact) = Sum(1);
NumPlayersInjured(fact) = Count(fact.player_name);
NumGamesWithInjuries(fact) = Count(fact.game_id);
NumStadiumsWithInjuries(fact) = Count(fact.stadium_id);
NumCompetitionsWithInjuries(fact) = Count(fact.game_competition);
NumHomeTeamsWithInjuries(fact) = Count(fact.home_team);
NumAwayTeamsWithInjuries(fact) = Count(fact.away_team);
AvgMatchesMissed(fact) = Avg(SafeMatchesMissed(fact.matches_missed_str));
MinMatchesMissed(fact) = Min(SafeMatchesMissed(fact.matches_missed_str));
MaxMatchesMissed(fact) = Max(SafeMatchesMissed(fact.matches_missed_str));
AvgStadiumAttendanceInjuryGames(fact) = Avg(fact.stadium_avg_attendance);
TotalStadiumHomeGames(fact) = SumDistinct(fact.stadium_id -> fact.stadium_home_games);
AvgStadiumCapacityPctInjuryGames(fact) = Avg(fact.stadium_capacity_pct);

PlayerIs(fact, player_names:) :- Constraint(PlayerName(fact) in player_names);
InjuryDescContains(fact, substring:) :- Substring(fact.injury_desc, substring);
SeasonIs(fact, seasons:) :- Constraint(GameSeason(fact) in seasons);
CompetitionIs(fact, competitions:) :- Constraint(GameCompetition(fact) in competitions);
HomeTeamIs(fact, team_names:) :- Constraint(HomeTeam(fact) in team_names);
AwayTeamIs(fact, team_names:) :- Constraint(AwayTeam(fact) in team_names);
TeamIs(fact, team_names:) :- Constraint(HomeTeam(fact) in team_names | AwayTeam(fact) in team_names);
StadiumIs(fact, stadium_names:) :- Constraint(StadiumName(fact) in stadium_names);
DateIs(fact, dates:) :- Constraint(GameDate(fact) in dates);
DateAfter(fact, date_val:) :- fact.game_date > date_val;
DateBefore(fact, date_val:) :- fact.game_date < date_val;
DateBetween(fact, min_date:, max_date:) :- fact.game_date >= min_date, fact.game_date <= max_date;
MatchesMissedIs(fact, num_matches_list:) :- Constraint(SafeMatchesMissed(fact.matches_missed_str) in num_matches_list);
MatchesMissedMoreThan(fact, num_matches:) :- SafeMatchesMissed(fact.matches_missed_str) > num_matches;
MatchesMissedLessThan(fact, num_matches:) :- SafeMatchesMissed(fact.matches_missed_str) < num_matches;
