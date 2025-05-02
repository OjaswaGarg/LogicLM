@Engine("sqlite");

LogicLM(
  name: "Singer Song Analysis",
  title: "Singer and Song Database Exploration",
  tagline: "<i>Analyze singers, their songs, sales, and demographics.</i>",
  port: 8090,
  fact_tables: ["SingerFactTable", "SongFactTable"],
  default_fact_table: "SongFactTable",

  dimensions: [
    "SingerId", "SingerName", "SingerBirthYear", "SingerNetWorth", "SingerCitizenship",
    "SongId", "SongTitle", "SongSales", "SongHighestPosition"
  ],

  measures: [
    "NumSingers", "NumSongs",
    "AvgNetWorth", "MaxNetWorth", "MinNetWorth",
    "AvgSales", "TotalSales", "MaxSales", "MinSales",
    "AvgHighestPosition",
    "NumSingersByCitizenship", "MaxNetWorthByCitizenship",
    "NumSongsPerSinger", "TotalSalesPerSinger"
  ],

  filters: [
     "SingerCitizenshipIs", "SingerCitizenshipIsNot",
     "SingerBirthYearIs", "SingerBirthYearIn",
     "SingerNetWorthMoreThan", "SingerNetWorthLessThan",
     "SongSalesMoreThan", "SongSalesLessThan",
     "HasSongs", "HasNoSongs"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Dimensions, Measures, and Filters should be predicate calls, e.g., [SingerName(), NumSongsPerSinger()].",
    "For filters, provide arguments, e.g., SingerBirthYearIn(years: [1948, 1949]), SongSalesMoreThan(min_sales: 300000).",
    "Use list syntax for multiple filter values: SingerCitizenshipIs(citizenship_values: ['USA', 'UK']).",
    "Order results using 'order:', e.g., order: [SingerNetWorth() desc].",
    "Use -1 for no limit.",
    "To count singers per citizenship: query: [SingerCitizenship(), NumSingersByCitizenship()].",
    "To find the singer with the highest net worth: query: [SingerName()], order: [SingerNetWorth() desc], limit: 1.",
    "To find the most common citizenship: query: [SingerCitizenship(), NumSingersByCitizenship()], order: [NumSingersByCitizenship() desc], limit: 1.",
    "To find singers with > 1 song: query: [SingerName(), NumSongsPerSinger()], having: [NumSongsPerSinger() > 1].",
    "To find singers with no songs, switch to the SingerFactTable: fact_table: SingerFactTable, query: [SingerName()], filter: [HasNoSongs()].",
    "Finding citizenships shared across complex conditions (e.g., born before X and after Y) requires a custom Logica query structure beyond standard filters."
  ]
);

Singer(singer_id:, name:, birth_year:, net_worth_millions:, citizenship:) :-
  singer(singer_id:, name:, birth_year:, net_worth_millions:, citizenship:);

Song(song_id:, title:, singer_id:, sales:, highest_position:) :-
  song(song_id:, title:, singer_id:, sales:, highest_position:);

SingerFactTableT(singer_id:, name:, birth_year:, net_worth_millions:, citizenship:) :-
  Singer(singer_id:, name:, birth_year:, net_worth_millions:, citizenship:);

SingerFactTable(r) :- SingerFactTableT(..r);

SongFactTableT(
    singer_id:, singer_name:, singer_birth_year:, singer_net_worth_millions:, singer_citizenship:,
    song_id:, song_title:, song_sales:, song_highest_position:
  ) :-
  Song(song_id:, title: song_title, singer_id:, sales: song_sales, highest_position: song_highest_position),
  Singer(singer_id:, name: singer_name, birth_year: singer_birth_year, net_worth_millions: singer_net_worth_millions, citizenship: singer_citizenship);

SongFactTable(r) :- SongFactTableT(..r);

SingerId(fact) = fact.singer_id;
SingerName(fact) = fact.singer_name;
SingerBirthYear(fact) = fact.singer_birth_year;
SingerNetWorth(fact) = fact.singer_net_worth_millions;
SingerCitizenship(fact) = fact.singer_citizenship;
SongId(fact) = fact.song_id;
SongTitle(fact) = fact.song_title;
SongSales(fact) = fact.song_sales;
SongHighestPosition(fact) = fact.song_highest_position;

NumSingers(fact) = Count(fact.singer_id);
NumSongs(fact) = Count(fact.song_id);
AvgNetWorth(fact) = Avg(fact.singer_net_worth_millions);
MaxNetWorth(fact) = Max(fact.singer_net_worth_millions);
MinNetWorth(fact) = Min(fact.singer_net_worth_millions);
AvgSales(fact) = Avg(fact.song_sales);
TotalSales(fact) = Sum(fact.song_sales);
MaxSales(fact) = Max(fact.song_sales);
MinSales(fact) = Min(fact.song_sales);
AvgHighestPosition(fact) = Avg(fact.song_highest_position);
NumSingersByCitizenship(fact) = Sum(1);
MaxNetWorthByCitizenship(fact) = Max(fact.singer_net_worth_millions);
NumSongsPerSinger(fact) = Count(fact.song_id);
TotalSalesPerSinger(fact) = Sum(fact.song_sales);

SingerCitizenshipIs(fact, citizenship_values:) :- Constraint(fact.singer_citizenship in citizenship_values);
SingerCitizenshipIsNot(fact, citizenship_values:) :- Constraint(!(fact.singer_citizenship in citizenship_values));
SingerBirthYearIs(fact, years:) :- Constraint(fact.singer_birth_year in years);
SingerBirthYearIn(fact, years:) :- Constraint(fact.singer_birth_year in years);
SingerNetWorthMoreThan(fact, min_worth:) :- fact.singer_net_worth_millions > min_worth;
SingerNetWorthLessThan(fact, max_worth:) :- fact.singer_net_worth_millions < max_worth;
SongSalesMoreThan(fact, min_sales:) :- fact.song_sales > min_sales;
SongSalesLessThan(fact, max_sales:) :- fact.song_sales < max_sales;

HasSongs(fact) :- Song(singer_id: fact.singer_id);
HasNoSongs(fact) :- ~Song(singer_id: fact.singer_id);