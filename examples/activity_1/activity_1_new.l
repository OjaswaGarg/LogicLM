```yodaql
@Engine("duckdb");

LogicLM(
  name: "UniversityAnalysis",
  title: "University Data Exploration",
  tagline: "<i>Analyze Students, Faculty, and Activities</i>",
  port: 8089,
  fact_tables: ["StudentFactTable", "FacultyFactTable", "ActivityFactTable", "ParticipationFactTable"],
  default_fact_table: "StudentFactTable",

  dimensions: [
    "StudentId", "StudentLName", "StudentFName", "StudentAge", "StudentSex", "StudentMajor", "StudentAdvisorId", "StudentCityCode",
    "StudentAdvisorLName", "StudentAdvisorFName", "StudentAdvisorRank",
    "ActivityId", "ActivityName",
    "FacultyId", "FacultyLName", "FacultyFName", "FacultyRank", "FacultySex", "FacultyBuilding"
  ],

  measures: [
    "NumStudents", "NumFaculty", "NumActivities", "NumParticipations",
    "AvgStudentAge", "MinStudentAge", "MaxStudentAge",
    "NumDistinctMajors", "NumDistinctCities", "NumDistinctAdvisors"
  ],

  filters: [
     "StudentLNameIs", "StudentFNameIs", "StudentMajorIs", "StudentCityCodeIs", "StudentSexIs",
     "StudentAgeIs", "StudentAgeOlderThan", "StudentAgeYoungerThan", "StudentAgeBetween",
     "StudentAdvisorLNameIs", "StudentAdvisorRankIs",
     "ActivityNameIs",
     "FacultyLNameIs", "FacultyFNameIs", "FacultyRankIs", "FacultyBuildingIs", "FacultySexIs",
     "StudentParticipatesInActivity", "FacultyParticipatesInActivity"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Specify the fact table using 'from:', e.g., from: FacultyFactTable().",
    "Dimensions, Measures, and Filters should be predicate calls, e.g., [StudentLName(), NumStudents()].",
    "For filters, provide arguments, e.g., StudentAgeIs(ages: [18, 19]), FacultyRankIs(ranks: ['Professor']).",
    "Use list syntax for multiple filter values: StudentCityCodeIs(city_codes: ['nyc', 'pit']).",
    "Order results using 'order:', e.g., order: [AvgStudentAge() desc].",
    "Use -1 for no limit.",
    "Joining information (like advisor names or activities) is done via functions; results might be null if related data is missing."
  ]
);


StudentFactTable(r) :- Student(..r);
FacultyFactTable(r) :- Faculty(..r);
ActivityFactTable(r) :- Activity(..r);
ParticipationFactTable(stuid:, actid:) :- Participates_in(stuid:, actid:);


StudentId(fact) = fact.StuID;
StudentLName(fact) = fact.LName;
StudentFName(fact) = fact.Fname;
StudentAge(fact) = fact.Age;
StudentSex(fact) = fact.Sex;
StudentMajor(fact) = fact.Major;
StudentAdvisorId(fact) = fact.Advisor;
StudentCityCode(fact) = fact.city_code;

FacultyId(fact) = fact.FacID;
FacultyLName(fact) = fact.lname;
FacultyFName(fact) = fact.Fname;
FacultyRank(fact) = fact.Rank;
FacultySex(fact) = fact.Sex;
FacultyBuilding(fact) = fact.Building;

ActivityId(fact) = fact.actid;
ActivityName(fact) = fact.activity_name;


AdvisorLNameLookup(advisor_id) = lname :- Faculty(FacID: advisor_id, lname:);
StudentAdvisorLName(fact) = AdvisorLNameLookup(fact.Advisor);

AdvisorFNameLookup(advisor_id) = fname :- Faculty(FacID: advisor_id, Fname: fname);
StudentAdvisorFName(fact) = AdvisorFNameLookup(fact.Advisor);

AdvisorRankLookup(advisor_id) = rank :- Faculty(FacID: advisor_id, Rank: rank);
StudentAdvisorRank(fact) = AdvisorRankLookup(fact.Advisor);

ActivityNameLookup(actid) = activity_name :- Activity(actid: actid, activity_name:);


NumStudents(fact) = Count(fact.StuID);
NumFaculty(fact) = Count(fact.FacID);
NumActivities(fact) = Count(fact.actid);
NumParticipations(fact) = Count(1);
AvgStudentAge(fact) = Avg(fact.Age);
MinStudentAge(fact) = Min(fact.Age);
MaxStudentAge(fact) = Max(fact.Age);
NumDistinctMajors(fact) = Count(fact.Major);
NumDistinctCities(fact) = Count(fact.city_code);
NumDistinctAdvisors(fact) = Count(fact.Advisor);


StudentLNameIs(fact, lnames:) :- Constraint(StudentLName(fact) in lnames);
StudentFNameIs(fact, fnames:) :- Constraint(StudentFName(fact) in fnames);
StudentMajorIs(fact, majors:) :- Constraint(StudentMajor(fact) in majors);
StudentCityCodeIs(fact, city_codes:) :- Constraint(StudentCityCode(fact) in city_codes);
StudentSexIs(fact, sexes:) :- Constraint(StudentSex(fact) in sexes);
StudentAgeIs(fact, ages:) :- Constraint(StudentAge(fact) in ages);
StudentAgeOlderThan(fact, age_val:) :- StudentAge(fact) > age_val;
StudentAgeYoungerThan(fact, age_val:) :- StudentAge(fact) < age_val;
StudentAgeBetween(fact, min_age:, max_age:) :- StudentAge(fact) >= min_age, StudentAge(fact) <= max_age;
StudentAdvisorLNameIs(fact, lnames:) :- Constraint(StudentAdvisorLName(fact) in lnames);
StudentAdvisorRankIs(fact, ranks:) :- Constraint(StudentAdvisorRank(fact) in ranks);

ActivityNameIs(fact, names:) :- Constraint(ActivityName(fact) in names);

FacultyLNameIs(fact, lnames:) :- Constraint(FacultyLName(fact) in lnames);
FacultyFNameIs(fact, fnames:) :- Constraint(FacultyFName(fact) in fnames);
FacultyRankIs(fact, ranks:) :- Constraint(FacultyRank(fact) in ranks);
FacultyBuildingIs(fact, buildings:) :- Constraint(FacultyBuilding(fact) in buildings);
FacultySexIs(fact, sexes:) :- Constraint(FacultySex(fact) in sexes);


StudentParticipatesInActivity(fact, activity_names:) :-
  Participates_in(stuid: fact.StuID, actid: activity_id_val),
  activity_actual_name == ActivityNameLookup(activity_id_val),
  activity_actual_name in activity_names;

FacultyParticipatesInActivity(fact, activity_names:) :-
  Faculty_Participates_in(FacID: fact.FacID, actid: activity_id_val),
  activity_actual_name == ActivityNameLookup(activity_id_val),
  activity_actual_name in activity_names;
```