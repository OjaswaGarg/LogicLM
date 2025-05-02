@Engine("sqlite");

LogicLM(
  name: "Museum Analysis",
  title: "Museum and Visitor Data Exploration",
  tagline: "<i>Analyze visitor demographics, visit patterns, and museum statistics.</i>",
  port: 8089,
  fact_tables: ["VisitFact"],
  default_fact_table: "VisitFact",

  dimensions: [
    "VisitorId", "VisitorName", "VisitorAge", "MembershipLevel",
    "MuseumId", "MuseumName", "NumStaff", "OpenYear",
    "NumTickets", "TotalSpent"
  ],

  measures: [
    "NumVisitors", "NumMuseums", "NumVisits",
    "AvgAge", "AvgStaff", "AvgTickets", "AvgSpent",
    "MinAge", "MaxAge", "MinStaff", "MaxStaff",
    "MinTickets", "MaxTickets", "MinSpent", "MaxSpent",
    "SumTickets", "SumSpent", "CountStaff", "CountMuseums"
  ],

  filters: [
     "VisitorAgeLessThan", "VisitorAgeGreaterThan", "VisitorAgeIs",
     "MembershipLevelIs", "MembershipLevelGreaterThan", "MembershipLevelLessThanOrEqual",
     "MuseumOpenYearBefore", "MuseumOpenYearAfter", "MuseumOpenYearIs", "MuseumOpenYearBetween",
     "MuseumNameIs", "VisitorNameIs", "MuseumHasStaffGreaterThan", "MuseumHasStaffLessThan",
     "VisitorIdIs", "MuseumIdIs"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Dimensions, Measures, and Filters should be predicate calls.",
    "Examples: [VisitorName(), AvgAge()], [MuseumName(), SumSpent(), order: [SumSpent() desc]].",
    "Filter Examples: VisitorAgeLessThan(max_age: 30), MembershipLevelGreaterThan(min_level: 4), MuseumOpenYearBetween(min_year: 2008, max_year: 2013).",
    "Use list syntax for multiple filter values: MembershipLevelIs(levels: [1, 2]).",
    "Note: 'open_year' is text; filters attempt numeric conversion.",
    "Note: 'visitor_id' in 'visit' table is text, 'id' in 'visitor' is int; joins assume compatibility."
  ]
);

SafeYear(year_text) = ToInt(year_text) :- StringIsNumeric(year_text);
SafeYear(year_text) = null :- ~StringIsNumeric(year_text);

VisitFactT(
    museum_id:, visitor_id:, num_of_ticket:, total_spent:,
    museum_name: museum_name, num_of_staff: num_of_staff, open_year: open_year,
    visitor_name: visitor_name, level_of_membership: level_of_membership, age: age
  ) :-
  visit(museum_id:, visitor_id:, num_of_ticket:, total_spent:),
  museum(museum_id: museum_id, name: museum_name, num_of_staff:, open_year:),
  visitor(id: visitor_id, name: visitor_name, level_of_membership: , age: );

VisitFact(r) :- VisitFactT(..r);


VisitorId(fact) = fact.visitor_id;
VisitorName(fact) = fact.visitor_name;
VisitorAge(fact) = fact.age;
MembershipLevel(fact) = fact.level_of_membership;
MuseumId(fact) = fact.museum_id;
MuseumName(fact) = fact.museum_name;
NumStaff(fact) = fact.num_of_staff;
OpenYear(fact) = fact.open_year;
NumTickets(fact) = fact.num_of_ticket;
TotalSpent(fact) = fact.total_spent;

NumVisitors(fact) = Count(fact.visitor_id);
NumMuseums(fact) = Count(fact.museum_id);
NumVisits(fact) = Sum(1);
AvgAge(fact) = Avg(fact.age);
AvgStaff(fact) = Avg(fact.num_of_staff);
AvgTickets(fact) = Avg(fact.num_of_ticket);
AvgSpent(fact) = Avg(fact.total_spent);
MinAge(fact) = Min(fact.age);
MaxAge(fact) = Max(fact.age);
MinStaff(fact) = Min(fact.num_of_staff);
MaxStaff(fact) = Max(fact.num_of_staff);
MinTickets(fact) = Min(fact.num_of_ticket);
MaxTickets(fact) = Max(fact.num_of_ticket);
MinSpent(fact) = Min(fact.total_spent);
MaxSpent(fact) = Max(fact.total_spent);
SumTickets(fact) = Sum(fact.num_of_ticket);
SumSpent(fact) = Sum(fact.total_spent);
CountStaff(fact) = Count(fact.num_of_staff);
CountMuseums(fact) = Count(fact.museum_id);

VisitorAgeLessThan(fact, max_age:) :- VisitorAge(fact) < max_age;
VisitorAgeGreaterThan(fact, min_age:) :- VisitorAge(fact) > min_age;
VisitorAgeIs(fact, ages:) :- Constraint(VisitorAge(fact) in ages);
MembershipLevelIs(fact, levels:) :- Constraint(MembershipLevel(fact) in levels);
MembershipLevelGreaterThan(fact, min_level:) :- MembershipLevel(fact) > min_level;
MembershipLevelLessThanOrEqual(fact, max_level:) :- MembershipLevel(fact) <= max_level;
MuseumOpenYearBefore(fact, year:) :- SafeYear(OpenYear(fact)) < year;
MuseumOpenYearAfter(fact, year:) :- SafeYear(OpenYear(fact)) > year;
MuseumOpenYearIs(fact, years:) :- Constraint(SafeYear(OpenYear(fact)) in years);
MuseumOpenYearBetween(fact, min_year:, max_year:) :-
  y = SafeYear(OpenYear(fact)), y >= min_year, y <= max_year;
MuseumNameIs(fact, names:) :- Constraint(MuseumName(fact) in names);
VisitorNameIs(fact, names:) :- Constraint(VisitorName(fact) in names);
MuseumHasStaffGreaterThan(fact, min_staff:) :- NumStaff(fact) > min_staff;
MuseumHasStaffLessThan(fact, max_staff:) :- NumStaff(fact) < max_staff;
VisitorIdIs(fact, ids:) :- Constraint(VisitorId(fact) in ids);
MuseumIdIs(fact, ids:) :- Constraint(MuseumId(fact) in ids);
