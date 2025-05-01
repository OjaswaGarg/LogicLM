@Engine("duckdb");

LogicLM(
  name: "OrchestraDB Analysis",
  title: "Conductors, Orchestras, and Performances",
  tagline: "<i>Explore the classical music world.</i>",
  port: 8090,
  fact_tables: ["ConductorOrchestraInfo", "Conductor", "Orchestra", "Performance", "Show"],
  default_fact_table: "ConductorOrchestraInfo",

  dimensions: [
    "ConductorId", "ConductorName", "ConductorAge", "ConductorNationality", "ConductorYearsWork",
    "OrchestraId", "OrchestraName", "OrchestraRecordCompany", "OrchestraFoundedYear", "OrchestraFormat",
    "PerformanceId", "PerformanceType", "PerformanceDate", "PerformanceShare",
    "ShowId", "ShowAttendance"
  ],

  measures: [
    "NumConductors", "NumOrchestras", "NumPerformances", "NumShows",
    "AvgShowAttendance", "MaxPerformanceShare", "MinPerformanceShare",
    "NumDistinctNationalities",
    "NumConductedOrchestras",
    "NumOrchestrasByRecordCompany",
    "NumOrchestrasByFormat",
    "NumPerformancesByOrchestra"
  ],

  filters: [
    "NationalityIs", "NationalityIsNot",
    "PerformanceTypeIs", "PerformanceTypeIsNot",
    "FoundedYearIs", "FoundedYearBefore", "FoundedYearAfter",
    "OrchestraFormatIs",
    "HasPerformances", "HasNoPerformances",
    "ConductedOrchestraFoundedAfter"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Dimensions, Measures, Filters are predicate calls, e.g., [ConductorName(), NumConductedOrchestras()].",
    "Filter arguments: NationalityIs(nationality_value: 'USA'), FoundedYearAfter(year: 2008).",
    "Use list syntax for multiple filter values: OrchestraFormatIs(formats: ['CD', 'DVD']).",
    "Order results using 'order:', e.g., order: [ConductorAge() asc].",
    "Use -1 for no limit.",
    "To find extrema (e.g., oldest conductor), sort and limit: query: [ConductorName()], order: [ConductorAge() desc], limit: 1.",
    "To find groups with counts (e.g., conductors with >1 orchestra), use measures and 'having': query: [ConductorName(), NumConductedOrchestras()], having: [NumConductedOrchestras() > 1]."
  ]
);

Conductor(conductor_id:, name:, age:, nationality:, year_of_work:) :-
  conductor(conductor_id:, name:, age:, nationality:, year_of_work:);

Orchestra(orchestra_id:, orchestra:, conductor_id:, record_company:, year_of_founded:, major_record_format:) :-
  orchestra(orchestra_id:, orchestra:, conductor_id:, record_company:, year_of_founded:, major_record_format:);

Performance(performance_id:, orchestra_id:, type:, date:, official_ratings_millions:, weekly_rank:, share:) :-
  performance(performance_id:, orchestra_id:, type:, date:, official_ratings_millions:, weekly_rank:, share:);

Show(show_id:, performance_id:, if_first_show:, result:, attendance:) :-
  show(show_id:, performance_id:, if_first_show:, result:, attendance:);


ConductorOrchestraInfoT(
    conductor_id:, name: conductor_name, age:, nationality:, year_of_work:,
    orchestra_id:, orchestra: orchestra_name, record_company:, year_of_founded:, major_record_format:
  ) :-
  Conductor(conductor_id:, name:, age:, nationality:, year_of_work:),
  Orchestra(orchestra_id:, orchestra:, conductor_id:, record_company:, year_of_founded:, major_record_format:);

ConductorOrchestraInfo(r) :- ConductorOrchestraInfoT(..r);


ConductorId(fact) = fact.conductor_id;
ConductorName(fact) = fact.conductor_name;
ConductorAge(fact) = fact.age;
ConductorNationality(fact) = fact.nationality;
ConductorYearsWork(fact) = fact.year_of_work;
OrchestraId(fact) = fact.orchestra_id;
OrchestraName(fact) = fact.orchestra_name;
OrchestraRecordCompany(fact) = fact.record_company;
OrchestraFoundedYear(fact) = fact.year_of_founded;
OrchestraFormat(fact) = fact.major_record_format;

PerformanceId(fact) = fact.performance_id;
PerformanceType(fact) = fact.type;
PerformanceDate(fact) = fact.date;
PerformanceShare(fact) = ToFloat(fact.share);

ShowId(fact) = fact.show_id;
ShowAttendance(fact) = fact.attendance;

NumConductors() = Count() :- Conductor();
NumOrchestras() = Count() :- Orchestra();
NumPerformances() = Count() :- Performance();
NumShows() = Count() :- Show();

AvgShowAttendance() = Avg(attendance) :- Show();
MaxPerformanceShare() = Max(ToFloat(share)) :- Performance();
MinPerformanceShare() = Min(ToFloat(share)) :- Performance();
NumDistinctNationalities() = Count(nationality) :- Conductor();

NumConductedOrchestras(fact) = Sum(1);
NumOrchestrasByRecordCompany(fact) = Sum(1);
NumOrchestrasByFormat(fact) = Sum(1);
NumPerformancesByOrchestra(fact) = Sum(1);


NationalityIs(fact, nationality_value:) :- fact.nationality == nationality_value;
NationalityIsNot(fact, nationality_value:) :- fact.nationality != nationality_value;

PerformanceTypeIs(fact, type_value:) :- fact.type == type_value;
PerformanceTypeIsNot(fact, type_value:) :- fact.type != type_value;

FoundedYearIs(fact, year_value:) :- fact.year_of_founded == year_value;
FoundedYearBefore(fact, year_value:) :- fact.year_of_founded < year_value;
FoundedYearAfter(fact, year_value:) :- fact.year_of_founded > year_value;

OrchestraFormatIs(fact, formats:) :- Constraint(OrchestraFormat(fact) in formats);

HasPerformances(fact) :- Performance(orchestra_id: fact.orchestra_id);
HasNoPerformances(fact) :- ~Performance(orchestra_id: fact.orchestra_id);

ConductedOrchestraFoundedAfter(fact, year:) :- fact.year_of_founded > year;
