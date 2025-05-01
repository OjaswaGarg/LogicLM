@Engine("sqlite");
@AttachDatabase("logica_home", "social.db");

LogicLM(
  name: "Highschool Social Network Analysis",
  title: "Highschooler Friendships and Likes",
  tagline: "<i>Explore student demographics, friendships, and popularity.</i>",
  port: 8090,
  fact_tables: ["FactTable", "HighschoolerRaw", "FriendRaw", "LikesRaw"],
  default_fact_table: "FactTable",

  dimensions: [
    "StudentId", "StudentName", "StudentGrade"
  ],

  measures: [
    "NumHighschoolers", "NumFriends", "NumLikes", "AvgGrade", "MinGrade", "MaxGrade"
  ],

  filters: [
     "GradeIs", "GradeIsOneOf", "NameIs",
     "GradeAbove", "GradeBelow",
     "HasFriends", "HasNoFriends",
     "IsLiked", "IsNotLiked",
     "HasLikes", "HasNoLikes"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Dimensions, Measures, and Filters are predicate calls, e.g., [StudentName(), NumFriends()].",
    "For filters, provide arguments, e.g., GradeIs(grades: [9]), NameIs(names: ['Kyle']).",
    "Use list syntax for multiple filter values: GradeIs(grades: [9, 10]).",
    "Order results using 'order:', e.g., order: [NumFriends() desc].",
    "Use -1 for no limit.",
    "Find specific details using filters, e.g., Kyle's grade: query: [StudentGrade()], filters: [NameIs(names: ['Kyle'])].",
    "Find aggregates per group, e.g., students per grade: query: [StudentGrade(), NumHighschoolers()].",
    "Find extrema, e.g., grade with most students: query: [StudentGrade(), NumHighschoolers()], order: [NumHighschoolers() desc], limit: 1.",
    "Filter aggregated results using 'having:', e.g., grades with >= 4 students: query: [StudentGrade(), NumHighschoolers()], having: [NumHighschoolers() >= 4]."
  ]
);

HighschoolerRaw(id:, name:, grade:) :- highschooler(ID: id, name:, grade:);
FriendRaw(student_id:, friend_id:) :- friend(student_id:, friend_id:);
LikesRaw(student_id:, liked_id:) :- likes(student_id:, liked_id:);

FactTable(id:, name:, grade:) :- HighschoolerRaw(id:, name:, grade:);

StudentId(fact) = fact.id;
StudentName(fact) = fact.name;
StudentGrade(fact) = fact.grade;

NumHighschoolers(fact) = Sum(1);
AvgGrade(fact) = Avg(fact.grade);
MinGrade(fact) = Min(fact.grade);
MaxGrade(fact) = Max(fact.grade);

NumFriends(fact) = Count{f :- FriendRaw(student_id: fact.id, friend_id: f)};
NumLikes(fact) = Count{l :- LikesRaw(liked_id: fact.id, student_id: l)};

GradeIs(fact, grades:) :- Constraint(StudentGrade(fact) in grades);
GradeIsOneOf(fact, grades:) :- Constraint(StudentGrade(fact) in grades);
NameIs(fact, names:) :- Constraint(StudentName(fact) in names);
GradeAbove(fact, min_grade:) :- fact.grade > min_grade;
GradeBelow(fact, max_grade:) :- fact.grade < max_grade;

HasFriends(fact) :- NumFriends(fact) > 0;
HasNoFriends(fact) :- NumFriends(fact) == 0;

IsLiked(fact) :- NumLikes(fact) > 0;
IsNotLiked(fact) :- NumLikes(fact) == 0;

HasLikes(fact) :- NumLikes(fact) > 0;
HasNoLikes(fact) :- NumLikes(fact) == 0;