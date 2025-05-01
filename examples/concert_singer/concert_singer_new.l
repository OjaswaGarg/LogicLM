@Engine("duckdb");

LogicLM(
  name: "ConcertsDB Analysis",
  title: "Singers, Concerts, and Stadiums",
  tagline: "<i>Explore relationships between artists, events, and venues.</i>",
  port: 8089,
  fact_tables: ["FactTable"],
  default_fact_table: "FactTable",

  dimensions: [
    "SingerId", "SingerName", "SingerCountry", "SingerAge", "SingerIsMale",
    "SongName", "SongReleaseYear",
    "ConcertId", "ConcertName", "ConcertTheme", "ConcertYear",
    "StadiumId", "StadiumName", "StadiumLocation", "StadiumCapacity",
    "StadiumHighestAttendance", "StadiumLowestAttendance", "StadiumAverageAttendance"
  ],

  measures: [
    "NumSingers", "NumConcerts", "NumStadiums",
    "AvgSingerAge", "MinSingerAge", "MaxSingerAge",
    "AvgStadiumCapacity", "MaxStadiumCapacity", "MinStadiumCapacity",
    "AvgStadiumAttendance", "MaxStadiumAttendance", "MinStadiumAttendance",
    "NumSingersPerConcert", "NumConcertsPerSinger", "NumConcertsPerStadium"
  ],

  filters: [
     "SingerCountryIs", "SingerAgeIs", "SingerAgeAbove", "SingerAgeBelow", "SingerAgeBetween",
     "ConcertYearIs", "ConcertYearAfter", "ConcertYearBefore", "ConcertYearBetween",
     "StadiumCapacityIs", "StadiumCapacityAbove", "StadiumCapacityBelow", "StadiumCapacityBetween",
     "StadiumLocationIs", "StadiumNameIs",
     "SongNameContains", "SongReleaseYearIs",
     "ConcertThemeContains", "ConcertNameContains",
     "SingerNameIs", "SingerNameContains"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Dimensions, Measures, and Filters should be predicate calls, e.g., [SingerName(), NumConcertsPerSinger()].",
    "For filters, provide arguments, e.g., ConcertYearIs(years: [2014, 2015]), SingerAgeAbove(min_age: 20).",
    "Use list syntax for multiple filter values: SingerCountryIs(countries: ['USA', 'France']).",
    "Order results using 'order:', e.g., order: [AvgSingerAge() desc].",
    "Use -1 for no limit.",
    "Note: Year fields (ConcertYear, SongReleaseYear) are stored as TEXT; queries attempt safe conversion."
  ]
);



FactDataPre(
    singer_id:, singer_name:, singer_country:, singer_song_name:, singer_song_release_year:, singer_age:, singer_is_male:,
    concert_id:, concert_name:, concert_theme:, concert_stadium_id:, concert_year:,
    stadium_id:, stadium_location:, stadium_name:, stadium_capacity:, stadium_highest:, stadium_lowest:, stadium_average:
  ) :-
  singer_in_concert(concert_id:, singer_id: sid_text),
  singer(singer_id: ToInt64(sid_text), name: singer_name, country: singer_country, song_name: singer_song_name, song_release_year: singer_song_release_year, age: singer_age, is_male: singer_is_male),
  concert(concert_id:, concert_name:, theme: concert_theme, stadium_id: c_stid_text, year: concert_year),
  stadium(stadium_id: ToInt64(c_stid_text), location: stadium_location, name: stadium_name, capacity: stadium_capacity, highest: stadium_highest, lowest: stadium_lowest, average: stadium_average),
  singer_id == ToInt64(sid_text),
  concert_stadium_id == ToInt64(c_stid_text),
  stadium_id == concert_stadium_id;

FactTable(r) :- FactDataPre(..r);

SingerId(fact) = fact.singer_id;
SingerName(fact) = fact.singer_name;
SingerCountry(fact) = fact.singer_country;
SingerAge(fact) = fact.singer_age;
SingerIsMale(fact) = fact.singer_is_male;
SongName(fact) = fact.singer_song_name;
SongReleaseYear(fact) = fact.singer_song_release_year;
ConcertId(fact) = fact.concert_id;
ConcertName(fact) = fact.concert_name;
ConcertTheme(fact) = fact.concert_theme;
ConcertYear(fact) = fact.concert_year;
StadiumId(fact) = fact.stadium_id;
StadiumName(fact) = fact.stadium_name;
StadiumLocation(fact) = fact.stadium_location;
StadiumCapacity(fact) = fact.stadium_capacity;
StadiumHighestAttendance(fact) = fact.stadium_highest;
StadiumLowestAttendance(fact) = fact.stadium_lowest;
StadiumAverageAttendance(fact) = fact.stadium_average;

NumSingers(fact) = Count(fact.singer_id);
NumConcerts(fact) = Count(fact.concert_id);
NumStadiums(fact) = Count(fact.stadium_id);
AvgSingerAge(fact) = Avg(fact.singer_age);
MinSingerAge(fact) = Min(fact.singer_age);
MaxSingerAge(fact) = Max(fact.singer_age);
AvgStadiumCapacity(fact) = Avg(fact.stadium_capacity);
MaxStadiumCapacity(fact) = Max(fact.stadium_capacity);
MinStadiumCapacity(fact) = Min(fact.stadium_capacity);
AvgStadiumAttendance(fact) = Avg(fact.stadium_average);
MaxStadiumAttendance(fact) = Max(fact.stadium_average);
MinStadiumAttendance(fact) = Min(fact.stadium_lowest);
NumSingersPerConcert(fact) = Count(fact.singer_id);
NumConcertsPerSinger(fact) = Count(fact.concert_id);
NumConcertsPerStadium(fact) = Count(fact.concert_id);

SingerCountryIs(fact, countries:) :- Constraint(SingerCountry(fact) in countries);
SingerAgeIs(fact, ages:) :- Constraint(SingerAge(fact) in ages);
SingerAgeAbove(fact, min_age:) :- fact.singer_age > min_age;
SingerAgeBelow(fact, max_age:) :- fact.singer_age < max_age;
SingerAgeBetween(fact, min_age:, max_age:) :- fact.singer_age >= min_age, fact.singer_age <= max_age;
ConcertYearIs(fact, years:) :- Constraint(ToInt64(fact.concert_year) in years);
ConcertYearAfter(fact, year:) :- ToInt64(fact.concert_year) > year;
ConcertYearBefore(fact, year:) :- ToInt64(fact.concert_year) < year;
ConcertYearBetween(fact, min_year:, max_year:) :- ToInt64(fact.concert_year) >= min_year, ToInt64(fact.concert_year) <= max_year;
StadiumCapacityIs(fact, capacities:) :- Constraint(StadiumCapacity(fact) in capacities);
StadiumCapacityAbove(fact, min_cap:) :- fact.stadium_capacity > min_cap;
StadiumCapacityBelow(fact, max_cap:) :- fact.stadium_capacity < max_cap;
StadiumCapacityBetween(fact, min_cap:, max_cap:) :- fact.stadium_capacity >= min_cap, fact.stadium_capacity <= max_cap;
StadiumLocationIs(fact, locations:) :- Constraint(StadiumLocation(fact) in locations);
StadiumNameIs(fact, names:) :- Constraint(StadiumName(fact) in names);
SongNameContains(fact, substr:) :- Contains(fact.singer_song_name, substr);
SongReleaseYearIs(fact, years:) :- Constraint(ToInt64(fact.singer_song_release_year) in years);
ConcertThemeContains(fact, substr:) :- Contains(fact.concert_theme, substr);
ConcertNameContains(fact, substr:) :- Contains(fact.concert_name, substr);
SingerNameIs(fact, names:) :- Constraint(SingerName(fact) in names);
SingerNameContains(fact, substr:) :- Contains(fact.singer_name, substr);
