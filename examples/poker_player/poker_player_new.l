@Engine("sqlite");

LogicLM(
  name: "Poker Player Analysis",
  title: "Poker Player Dataset Exploration",
  tagline: "<i>Analyze player stats, earnings, and demographics.</i>",
  port: 8089,
  fact_tables: ["PlayerInfo", "People"],
  default_fact_table: "PlayerInfo",

  dimensions: [
    "PlayerName", "PlayerEarnings", "PlayerFinalTables", "PlayerBestFinish",
    "PlayerMoneyRank", "PlayerBirthDate", "PlayerHeight", "PersonNationality",
    "PersonName", "PersonBirthDate", "PersonId"
  ],

  measures: [
    "NumPokerPlayers", "AvgPlayerEarnings", "MaxPlayerFinalTables",
    "NumPeopleByNationality", "NumDistinctNationalities", "NumPeople"
  ],

  filters: [
     "EarningsLessThan", "EarningsGreaterThan", "HeightGreaterThan",
     "NationalityIs", "NationalityIsNot", "IsPokerPlayer", "IsNotPokerPlayer"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Dimensions, Measures, and Filters should be predicate calls, e.g., [PlayerName(), AvgPlayerEarnings()].",
    "For filters, provide arguments, e.g., EarningsLessThan(value: 200000), NationalityIs(nationality_value: 'USA').",
    "Use list syntax for multiple filter values if applicable.",
    "Order results using 'order:', e.g., order: [PlayerEarnings() desc].",
    "Use -1 for no limit.",
    "To find extrema (e.g., player with highest earnings), sort and limit: query: [PlayerName()], order: [PlayerEarnings() desc], limit: 1.",
    "To find nationalities with >= N people, group by nationality and filter the count: query: [PersonNationality(), NumPeopleByNationality()], having: [NumPeopleByNationality() >= 2]."
  ]
);

People(people_id:, nationality:, name:, birth_date:, height:) :-
  people(people_id:, nationality:, name:, birth_date:, height:);

PokerPlayer(poker_player_id:, people_id:, final_table_made:, best_finish:, money_rank:, earnings:) :-
  poker_player(poker_player_id:, people_id:, final_table_made:, best_finish:, money_rank:, earnings:);

PlayerInfoT(
    poker_player_id:, people_id:, final_table_made:, best_finish:, money_rank:, earnings:,
    nationality:, name:, birth_date:, height:
  ) :-
  PokerPlayer(poker_player_id:, people_id:, final_table_made:, best_finish:, money_rank:, earnings:),
  People(people_id:, nationality:, name:, birth_date:, height:);

PlayerInfo(r) :- PlayerInfoT(..r);
PlayerName(fact) = fact.name;
PlayerEarnings(fact) = fact.earnings;
PlayerFinalTables(fact) = fact.final_table_made;
PlayerBestFinish(fact) = fact.best_finish;
PlayerMoneyRank(fact) = fact.money_rank;
PlayerBirthDate(fact) = fact.birth_date;
PlayerHeight(fact) = fact.height;
PersonNationality(fact) = fact.nationality;
PersonName(fact) = fact.name;
PersonBirthDate(fact) = fact.birth_date;
PersonId(fact) = fact.people_id;

NumPokerPlayers(fact) = Sum(1);
AvgPlayerEarnings(fact) = Avg(fact.earnings);
MaxPlayerFinalTables(fact) = Max(fact.final_table_made);
NumPeopleByNationality(fact) = Sum(1);
NumDistinctNationalities(fact) = Count(fact.nationality);
NumPeople(fact) = Sum(1);

EarningsLessThan(fact, value:) :- fact.earnings < value;
EarningsGreaterThan(fact, value:) :- fact.earnings > value;
HeightGreaterThan(fact, value:) :- fact.height > value;
NationalityIs(fact, nationality_value:) :- fact.nationality == nationality_value;
NationalityIsNot(fact, nationality_value:) :- fact.nationality != nationality_value;

IsPokerPlayer(fact) :- PokerPlayer(people_id: fact.people_id);
IsNotPokerPlayer(fact) :- ~PokerPlayer(people_id: fact.people_id);