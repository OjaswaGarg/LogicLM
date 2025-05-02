@Engine("sqlite");

LogicLM(
  name: "Tennis Analysis",
  title: "ATP/WTA Tennis Data Exploration",
  tagline: "<i>Analyze players, matches, and rankings.</i>",
  port: 8090,
  fact_tables: ["MatchDetails", "PlayerRankingDetails", "Players", "Matches", "Rankings"],
  default_fact_table: "MatchDetails",

  dimensions: [
    "PlayerId", "PlayerFirstName", "PlayerLastName", "PlayerFullName", "PlayerHand",
    "PlayerBirthDate", "PlayerCountryCode",
    "WinnerId", "WinnerName", "WinnerHand", "WinnerCountryCode", "WinnerAge",
    "WinnerHeight", "WinnerRank", "WinnerRankPoints", "WinnerSeed",
    "LoserId", "LoserName", "LoserHand", "LoserCountryCode", "LoserAge",
    "LoserHeight", "LoserRank", "LoserRankPoints", "LoserSeed",
    "MatchNum", "MatchRound", "MatchScore", "MatchSurface", "MatchMinutes",
    "MatchBestOf",
    "TourneyId", "TourneyName", "TourneyDate", "TourneyLevel", "MatchYear",
    "RankingDate", "RankingRank", "RankingPoints", "RankingTours"
  ],

  measures: [
    "CountMatches", "CountPlayers", "CountQualifyingMatches", "CountRankings",
    "AvgWinnerAge", "AvgLoserAge", "AvgWinnerRank", "AvgLoserRank",
    "AvgWinnerRankPoints", "AvgLoserRankPoints", "AvgMatchMinutes",
    "MinWinnerAge", "MaxWinnerAge", "MinLoserAge", "MaxLoserAge",
    "MinWinnerRank", "MaxWinnerRank", "MinLoserRank", "MaxLoserRank",
    "MinWinnerRankPoints", "MaxWinnerRankPoints", "MinLoserRankPoints", "MaxLoserRankPoints",
    "MinMatchMinutes", "MaxMatchMinutes",
    "CountDistinctPlayerCountries", "CountDistinctWinnerNames", "CountDistinctLoserNames",
    "CountDistinctTourneyNames",
    "AvgPlayerRanking", "SumPlayerRankingPoints", "SumPlayerTours", "MaxPlayerTours",
    "CountWins"
  ],

  filters: [
     "PlayerCountryCodeIs", "PlayerHandIs", "PlayerBirthDateIs",
     "WinnerCountryCodeIs", "WinnerHandIs", "WinnerRankIs", "WinnerRankLessThan", "WinnerRankGreaterThan",
     "LoserCountryCodeIs", "LoserHandIs", "LoserRankIs", "LoserRankLessThan", "LoserRankGreaterThan",
     "MatchYearIs", "MatchYearBetween", "MatchYearBefore", "MatchYearAfter",
     "TourneyNameIs", "TourneyNameContains", "TourneyLevelIs", "MatchSurfaceIs",
     "MatchMinutesMoreThan", "MatchMinutesLessThan",
     "RankingDateIs", "RankingRankIs"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Dimensions, Measures, and Filters should be predicate calls.",
    "Example: query: [WinnerName(), CountMatches()], filter: [MatchYearIs(years: [2016])].",
    "Use list syntax for multiple filter values: PlayerCountryCodeIs(codes: ['USA', 'SRB']).",
    "Order results using 'order:', e.g., order: [AvgWinnerAge() asc].",
    "Use -1 for no limit.",
    "Finding players who won in multiple conditions (e.g., years 2013 AND 2016) requires combining results or more complex Logica.",
    "To find extrema (e.g., oldest player), sort and limit: query: [PlayerFirstName(), PlayerCountryCode()], fact_table: 'Players', order: [PlayerBirthDate() asc], limit: 1.",
    "To group and filter aggregates (e.g., countries with > 50 players): query: [PlayerCountryCode(), CountPlayers()], fact_table: 'Players', having: [CountPlayers() > 50]."
  ]
);

Players(player_id:, first_name:, last_name:, hand:, birth_date:, country_code:) :-
  players(player_id:, first_name:, last_name:, hand:, birth_date:, country_code:);

Matches(best_of:, draw_size:, loser_age:, loser_entry:, loser_hand:, loser_ht:, loser_id:, loser_ioc:, loser_name:, loser_rank:, loser_rank_points:, loser_seed:, match_num:, minutes:, round:, score:, surface:, tourney_date:, tourney_id:, tourney_level:, tourney_name:, winner_age:, winner_entry:, winner_hand:, winner_ht:, winner_id:, winner_ioc:, winner_name:, winner_rank:, winner_rank_points:, winner_seed:, year:) :-
  matches(best_of:, draw_size:, loser_age:, loser_entry:, loser_hand:, loser_ht:, loser_id:, loser_ioc:, loser_name:, loser_rank:, loser_rank_points:, loser_seed:, match_num:, minutes:, round:, score:, surface:, tourney_date:, tourney_id:, tourney_level:, tourney_name:, winner_age:, winner_entry:, winner_hand:, winner_ht:, winner_id:, winner_ioc:, winner_name:, winner_rank:, winner_rank_points:, winner_seed:, year:);

QualifyingMatches(best_of:, draw_size:, l_1stin:, l_1stwon:, l_2ndwon:, l_svgms:, l_ace:, l_bpfaced:, l_bpsaved:, l_df:, l_svpt:, loser_age:, loser_entry:, loser_hand:, loser_ht:, loser_id:, loser_ioc:, loser_name:, loser_rank:, loser_rank_points:, loser_seed:, match_num:, minutes:, round:, score:, surface:, tourney_date:, tourney_id:, tourney_level:, tourney_name:, w_1stin:, w_1stwon:, w_2ndwon:, w_svgms:, w_ace:, w_bpfaced:, w_bpsaved:, w_df:, w_svpt:, winner_age:, winner_entry:, winner_hand:, winner_ht:, winner_id:, winner_ioc:, winner_name:, winner_rank:, winner_rank_points:, winner_seed:, year:) :-
  qualifying_matches(best_of:, draw_size:, l_1stin:, l_1stwon:, l_2ndwon:, l_svgms:, l_ace:, l_bpfaced:, l_bpsaved:, l_df:, l_svpt:, loser_age:, loser_entry:, loser_hand:, loser_ht:, loser_id:, loser_ioc:, loser_name:, loser_rank:, loser_rank_points:, loser_seed:, match_num:, minutes:, round:, score:, surface:, tourney_date:, tourney_id:, tourney_level:, tourney_name:, w_1stin:, w_1stwon:, w_2ndwon:, w_svgms:, w_ace:, w_bpfaced:, w_bpsaved:, w_df:, w_svpt:, winner_age:, winner_entry:, winner_hand:, winner_ht:, winner_id:, winner_ioc:, winner_name:, winner_rank:, winner_rank_points:, winner_seed:, year:);

Rankings(ranking_date:, ranking:, player_id:, ranking_points:, tours:) :-
  rankings(ranking_date:, ranking:, player_id:, ranking_points:, tours:);


MatchDetailsT(
    match_num:, minutes:, round:, score:, surface:, tourney_date:, tourney_id:, tourney_level:, tourney_name:, year:, best_of:,
    winner_id:, winner_age:, winner_entry:, winner_hand:, winner_ht:, winner_rank:, winner_rank_points:, winner_seed:,
    winner_first_name:, winner_last_name:, winner_birth_date:, winner_country_code:,
    loser_id:, loser_age:, loser_entry:, loser_hand:, loser_ht:, loser_rank:, loser_rank_points:, loser_seed:,
    loser_first_name:, loser_last_name:, loser_birth_date:, loser_country_code:
  ) :-
  Matches(match_num:, minutes:, round:, score:, surface:, tourney_date:, tourney_id:, tourney_level:, tourney_name:, year:, best_of:,
          winner_id: wid, winner_age:, winner_entry:, winner_hand: whand, winner_ht:, winner_rank:, winner_rank_points:, winner_seed:,
          loser_id: lid, loser_age:, loser_entry:, loser_hand: lhand, loser_ht:, loser_rank:, loser_rank_points:, loser_seed:),
  Players(player_id: wid, first_name: winner_first_name, last_name: winner_last_name, hand: whand, birth_date: winner_birth_date, country_code: winner_country_code),
  Players(player_id: lid, first_name: loser_first_name, last_name: loser_last_name, hand: lhand, birth_date: loser_birth_date, country_code: loser_country_code),
  winner_id == wid, loser_id == lid;


PlayerRankingDetailsT(
    player_id:, first_name:, last_name:, hand:, birth_date:, country_code:,
    ranking_date:, ranking:, ranking_points:, tours:
  ) :-
  Players(player_id:, first_name:, last_name:, hand:, birth_date:, country_code:),
  Rankings(player_id:, ranking_date:, ranking:, ranking_points:, tours:);

MatchDetails(r) :- MatchDetailsT(..r);
PlayerRankingDetails(r) :- PlayerRankingDetailsT(..r);


PlayerId(fact) = fact.player_id;
PlayerFirstName(fact) = fact.first_name;
PlayerLastName(fact) = fact.last_name;
PlayerFullName(fact) = fact.first_name || " " || fact.last_name;
PlayerHand(fact) = fact.hand;
PlayerBirthDate(fact) = fact.birth_date;
PlayerCountryCode(fact) = fact.country_code;

WinnerId(fact) = fact.winner_id;
WinnerName(fact) = fact.winner_first_name || " " || fact.winner_last_name;
WinnerHand(fact) = fact.winner_hand;
WinnerCountryCode(fact) = fact.winner_country_code;
WinnerAge(fact) = fact.winner_age;
WinnerHeight(fact) = fact.winner_ht;
WinnerRank(fact) = fact.winner_rank;
WinnerRankPoints(fact) = fact.winner_rank_points;
WinnerSeed(fact) = fact.winner_seed;

LoserId(fact) = fact.loser_id;
LoserName(fact) = fact.loser_first_name || " " || fact.loser_last_name;
LoserHand(fact) = fact.loser_hand;
LoserCountryCode(fact) = fact.loser_country_code;
LoserAge(fact) = fact.loser_age;
LoserHeight(fact) = fact.loser_ht;
LoserRank(fact) = fact.loser_rank;
LoserRankPoints(fact) = fact.loser_rank_points;
LoserSeed(fact) = fact.loser_seed;

MatchNum(fact) = fact.match_num;
MatchRound(fact) = fact.round;
MatchScore(fact) = fact.score;
MatchSurface(fact) = fact.surface;
MatchMinutes(fact) = fact.minutes;
MatchBestOf(fact) = fact.best_of;

TourneyId(fact) = fact.tourney_id;
TourneyName(fact) = fact.tourney_name;
TourneyDate(fact) = fact.tourney_date;
TourneyLevel(fact) = fact.tourney_level;
MatchYear(fact) = fact.year;

RankingDate(fact) = fact.ranking_date;
RankingRank(fact) = fact.ranking;
RankingPoints(fact) = fact.ranking_points;
RankingTours(fact) = fact.tours;


CountMatches(fact) = Sum(1);
CountPlayers(fact) = Count(fact.player_id);
CountQualifyingMatches(fact) = Sum(1);
CountRankings(fact) = Sum(1);
AvgWinnerAge(fact) = Avg(fact.winner_age);
AvgLoserAge(fact) = Avg(fact.loser_age);
AvgWinnerRank(fact) = Avg(fact.winner_rank);
AvgLoserRank(fact) = Avg(fact.loser_rank);
AvgWinnerRankPoints(fact) = Avg(fact.winner_rank_points);
AvgLoserRankPoints(fact) = Avg(fact.loser_rank_points);
AvgMatchMinutes(fact) = Avg(fact.minutes);
MinWinnerAge(fact) = Min(fact.winner_age);
MaxWinnerAge(fact) = Max(fact.winner_age);
MinLoserAge(fact) = Min(fact.loser_age);
MaxLoserAge(fact) = Max(fact.loser_age);
MinWinnerRank(fact) = Min(fact.winner_rank);
MaxWinnerRank(fact) = Max(fact.winner_rank);
MinLoserRank(fact) = Min(fact.loser_rank);
MaxLoserRank(fact) = Max(fact.loser_rank);
MinWinnerRankPoints(fact) = Min(fact.winner_rank_points);
MaxWinnerRankPoints(fact) = Max(fact.winner_rank_points);
MinLoserRankPoints(fact) = Min(fact.loser_rank_points);
MaxLoserRankPoints(fact) = Max(fact.loser_rank_points);
MinMatchMinutes(fact) = Min(fact.minutes);
MaxMatchMinutes(fact) = Max(fact.minutes);
CountDistinctPlayerCountries(fact) = Count(fact.country_code);
CountDistinctWinnerNames(fact) = Count(WinnerName(fact));
CountDistinctLoserNames(fact) = Count(LoserName(fact));
CountDistinctTourneyNames(fact) = Count(fact.tourney_name);
AvgPlayerRanking(fact) = Avg(fact.ranking);
SumPlayerRankingPoints(fact) = Sum(fact.ranking_points);
SumPlayerTours(fact) = Sum(fact.tours);
MaxPlayerTours(fact) = Max(fact.tours);
CountWins(fact) = Sum(1);


PlayerCountryCodeIs(fact, codes:) :- Constraint(PlayerCountryCode(fact) in codes);
PlayerHandIs(fact, hands:) :- Constraint(PlayerHand(fact) in hands);
PlayerBirthDateIs(fact, dates:) :- Constraint(PlayerBirthDate(fact) in dates);

WinnerCountryCodeIs(fact, codes:) :- Constraint(WinnerCountryCode(fact) in codes);
WinnerHandIs(fact, hands:) :- Constraint(WinnerHand(fact) in hands);
WinnerRankIs(fact, ranks:) :- Constraint(WinnerRank(fact) in ranks);
WinnerRankLessThan(fact, value:) :- WinnerRank(fact) < value;
WinnerRankGreaterThan(fact, value:) :- WinnerRank(fact) > value;

LoserCountryCodeIs(fact, codes:) :- Constraint(LoserCountryCode(fact) in codes);
LoserHandIs(fact, hands:) :- Constraint(LoserHand(fact) in hands);
LoserRankIs(fact, ranks:) :- Constraint(LoserRank(fact) in ranks);
LoserRankLessThan(fact, value:) :- LoserRank(fact) < value;
LoserRankGreaterThan(fact, value:) :- LoserRank(fact) > value;

MatchYearIs(fact, years:) :- Constraint(MatchYear(fact) in years);
MatchYearBetween(fact, min_year:, max_year:) :- MatchYear(fact) >= min_year, MatchYear(fact) <= max_year;
MatchYearBefore(fact, year:) :- MatchYear(fact) < year;
MatchYearAfter(fact, year:) :- MatchYear(fact) > year;

TourneyNameIs(fact, names:) :- Constraint(TourneyName(fact) in names);
TourneyNameContains(fact, substr:) :- Contains(TourneyName(fact), substr);
TourneyLevelIs(fact, levels:) :- Constraint(TourneyLevel(fact) in levels);
MatchSurfaceIs(fact, surfaces:) :- Constraint(MatchSurface(fact) in surfaces);

MatchMinutesMoreThan(fact, value:) :- MatchMinutes(fact) > value;
MatchMinutesLessThan(fact, value:) :- MatchMinutes(fact) < value;

RankingDateIs(fact, dates:) :- Constraint(RankingDate(fact) in dates);
RankingRankIs(fact, ranks:) :- Constraint(RankingRank(fact) in ranks);