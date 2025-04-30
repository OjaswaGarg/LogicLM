```logica
@Engine("duckdb");

LogicLM(
  name: "Student Analysis",
  title: "Student Demographics and Allergies",
  tagline: "<i>Explore student data and their allergies</i>",
  port: 8089,
  fact_tables: ["StudentInfo", "StudentAllergyInfo"],
  default_fact_table: "StudentInfo",

  dimensions: [
    "StudentId", "LastName", "FirstName", "Age", "Sex", "MajorId", "AdvisorId",
    "CityCode", "AllergyName", "AllergyCategory"
  ],

  measures: [
    "NumStudents", "AvgAge", "MinAge", "MaxAge", "NumMajors", "NumAdvisors",
    "NumCities", "NumAllergies", "NumAllergyTypes"
  ],

  filters: [
    "StudentIs", "LastNameIs", "FirstNameIs", "AgeIs", "AgeOlderThan",
    "AgeYoungerThan", "AgeBetween", "SexIs", "MajorIs", "AdvisorIs",
    "CityIs", "AllergyIs", "AllergyTypeIs"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Dimensions, Measures, and Filters should be predicate calls, e.g., [CityCode(), NumStudents()].",
    "For filters, provide arguments, e.g., AgeIs(age: 20), CityIs(city_code: 'nyc').",
    "Use list syntax for multiple filter values: MajorIs(major_ids: [600, 520]).",
    "Order results using 'order:', e.g., order: [AvgAge() desc].",
    "Use -1 for no limit.",
    "Some measures/dimensions (like AllergyName) are only available when using the 'StudentAllergyInfo' fact table."
  ]
);


StudentInfo(
    student_id: stuid,
    last_name: lname,
    first_name: fname,
    age:,
    sex:,
    major_id: major,
    advisor_id: advisor,
    city_code: city_code
  ) :-
  Student(StuID: stuid, LName: lname, Fname: fname, Age: age, Sex: sex, Major: major, Advisor: advisor, city_code: city_code);


StudentAllergyInfo(
    student_id:, last_name:, first_name:, age:, sex:, major_id:, advisor_id:, city_code:,
    allergy_name:, allergy_category:
  ) :-
  StudentInfo(student_id:, last_name:, first_name:, age:, sex:, major_id:, advisor_id:, city_code:),
  Has_Allergy(StuID: student_id, Allergy: allergy_name),
  Allergy_Type(Allergy: allergy_name, AllergyType: allergy_category);


StudentId(fact) = fact.student_id;
LastName(fact) = fact.last_name;
FirstName(fact) = fact.first_name;
Age(fact) = fact.age;
Sex(fact) = fact.sex;
MajorId(fact) = fact.major_id;
AdvisorId(fact) = fact.advisor_id;
CityCode(fact) = fact.city_code;
AllergyName(fact) = fact.allergy_name;
AllergyCategory(fact) = fact.allergy_category;


NumStudents(fact) = Count(fact.student_id);
AvgAge(fact) = Avg(fact.age);
MinAge(fact) = Min(fact.age);
MaxAge(fact) = Max(fact.age);
NumMajors(fact) = Count(fact.major_id);
NumAdvisors(fact) = Count(fact.advisor_id);
NumCities(fact) = Count(fact.city_code);
NumAllergies(fact) = Count(fact.allergy_name);
NumAllergyTypes(fact) = Count(fact.allergy_category);


StudentIs(fact, student_ids:) :- Constraint(StudentId(fact) in student_ids);
LastNameIs(fact, last_names:) :- Constraint(LastName(fact) in last_names);
FirstNameIs(fact, first_names:) :- Constraint(FirstName(fact) in first_names);
AgeIs(fact, ages:) :- Constraint(Age(fact) in ages);
AgeOlderThan(fact, age_val:) :- Age(fact) > age_val;
AgeYoungerThan(fact, age_val:) :- Age(fact) < age_val;
AgeBetween(fact, min_age:, max_age:) :- Age(fact) >= min_age, Age(fact) <= max_age;
SexIs(fact, sexes:) :- Constraint(Sex(fact) in sexes);
MajorIs(fact, major_ids:) :- Constraint(MajorId(fact) in major_ids);
AdvisorIs(fact, advisor_ids:) :- Constraint(AdvisorId(fact) in advisor_ids);
CityIs(fact, city_codes:) :- Constraint(CityCode(fact) in city_codes);
AllergyIs(fact, allergy_names:) :- Constraint(AllergyName(fact) in allergy_names);
AllergyTypeIs(fact, allergy_types:) :- Constraint(AllergyCategory(fact) in allergy_types);
```