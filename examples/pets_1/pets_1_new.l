@Engine("sqlite");

LogicLM(
  name: "Student Pet Analysis",
  title: "Student and Pet Dataset Exploration",
  tagline: "<i>Analyze student demographics and their pets.</i>",
  port: 8090,
  fact_tables: ["FactTable", "Student"],
  default_fact_table: "FactTable",

  dimensions: [
    "StudentId", "StudentFName", "StudentLName", "StudentAge", "StudentSex",
    "StudentMajor", "StudentAdvisor", "StudentCityCode",
    "PetId", "PetType", "PetAge", "PetWeight"
  ],

  measures: [
    "NumPets", "NumStudents", "NumDistinctPetTypes",
    "AvgPetAge", "MaxPetAge", "MinPetAge",
    "AvgPetWeight", "MaxPetWeight", "MinPetWeight",
    "AvgStudentAge", "MaxStudentAge", "MinStudentAge",
    "NumPetsPerStudent"
  ],
  fact_tables_of_measures: ["NumStudents"->"Student","AvgStudentAge"->"Student","MaxStudentAge"->"Student","MinStudentAge"->"Student"],


  filters: [
     "PetWeightGreaterThan", "PetWeightLessThan",
     "PetAgeIs", "PetAgeGreaterThan", "PetAgeLessThan",
     "PetTypeIs",
     "StudentAgeIs", "StudentAgeGreaterThan", "StudentAgeLessThan",
     "StudentSexIs",
     "StudentLNameIs",
     "HasPetType", "DoesNotHavePetType",
     "HasAnyPet", "DoesNotHaveAnyPet"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Dimensions, Measures, and Filters are predicate calls, e.g., [StudentFName(), AvgStudentAge()].",
    "Provide filter arguments, e.g., PetWeightGreaterThan(min_w: 10), PetTypeIs(pet_types: ['Cat', 'Dog']).",
    "Use list syntax for multiple filter values.",
    "Order results using 'order:', e.g., order: [AvgPetWeight() desc].",
    "Use -1 for no limit.",
    "To find youngest dog's weight: query: [PetWeight()], filter: [PetTypeIs(pet_types:['Dog'])], order: [PetAge() asc], limit: 1.",
    "To find students with > 1 pet: query: [StudentFName(), StudentSex(), NumPetsPerStudent()], having: [NumPetsPerStudent() > 1].",
    "To query students without pets, change fact table: fact_table: 'Student', filter: [DoesNotHaveAnyPet()].",
    "Queries on FactTable only include students WITH pets."
  ]
);

Student(stuid:, lname:, fname:, age:, sex:, major:, advisor:, city_code:) :-
  student(StuID: stuid, lname:, Fname: fname, Age: age, Sex: sex, Major: major, Advisor: advisor, city_code:);

Pets(petid:, pettype:, pet_age:, weight:) :-
  pets(PetID: petid, pettype:, pet_age:, weight:);

Has_Pet(stuid:, petid:) :-
  has_pet(stuid:, petid:);

FactDataPre(
    student_id:, student_lname:, student_fname:, student_age:, student_sex:, student_major:, student_advisor:, student_city_code:,
    pet_id:, pet_type:, pet_age:, pet_weight:
  ) :-
  Student(stuid: student_id, lname: student_lname, fname: student_fname, age: student_age, sex: student_sex, major: student_major, advisor: student_advisor, city_code: student_city_code),
  Has_Pet(stuid: student_id, petid: pet_id),
  Pets(petid: pet_id, pettype: pet_type, pet_age:, weight: pet_weight);

FactTable(r) :- FactDataPre(..r);

StudentId(fact) = fact.student_id;
StudentLName(fact) = fact.student_lname;
StudentFName(fact) = fact.student_fname;
StudentAge(fact) = fact.student_age;
StudentSex(fact) = fact.student_sex;
StudentMajor(fact) = fact.student_major;
StudentAdvisor(fact) = fact.student_advisor;
StudentCityCode(fact) = fact.student_city_code;
PetId(fact) = fact.pet_id;
PetType(fact) = fact.pet_type;
PetAge(fact) = fact.pet_age;
PetWeight(fact) = fact.pet_weight;

NumPets(fact) = Sum(1);
NumStudents(fact) = Count(fact.student_id);
NumDistinctPetTypes(fact) = Count(fact.pet_type);
AvgPetAge(fact) = Avg(fact.pet_age);
MaxPetAge(fact) = Max(fact.pet_age);
MinPetAge(fact) = Min(fact.pet_age);
AvgPetWeight(fact) = Avg(fact.pet_weight);
MaxPetWeight(fact) = Max(fact.pet_weight);
MinPetWeight(fact) = Min(fact.pet_weight);
AvgStudentAge(fact) = Avg(fact.student_age);
MaxStudentAge(fact) = Max(fact.student_age);
MinStudentAge(fact) = Min(fact.student_age);
NumPetsPerStudent(fact) = Sum(1);

PetWeightGreaterThan(fact, min_w:) :- fact.pet_weight > min_w;
PetWeightLessThan(fact, max_w:) :- fact.pet_weight < max_w;
PetAgeIs(fact, ages:) :- Constraint(PetAge(fact) in ages);
PetAgeGreaterThan(fact, min_age:) :- fact.pet_age > min_age;
PetAgeLessThan(fact, max_age:) :- fact.pet_age < max_age;
PetTypeIs(fact, pet_types:) :- Constraint(PetType(fact) in pet_types);
StudentAgeIs(fact, ages:) :- Constraint(StudentAge(fact) in ages);
StudentAgeGreaterThan(fact, min_age:) :- fact.student_age > min_age;
StudentAgeLessThan(fact, max_age:) :- fact.student_age < max_age;
StudentSexIs(fact, sexes:) :- Constraint(StudentSex(fact) in sexes);
StudentLNameIs(fact, lnames:) :- Constraint(StudentLName(fact) in lnames);

HasPetType(fact, pet_types:) :-
  Has_Pet(stuid: fact.stuid, petid:),
  Pets(petid:, pettype: pt),
  Constraint(pt in pet_types);

DoesNotHavePetType(fact, pet_types:) :-
  ~(
      Has_Pet(stuid: fact.stuid, petid:),
      Pets(petid:, pettype: pt),
      Constraint(pt in pet_types)
    );

HasAnyPet(fact) :- Has_Pet(stuid: fact.stuid);

DoesNotHaveAnyPet(fact) :- ~Has_Pet(stuid: fact.stuid);