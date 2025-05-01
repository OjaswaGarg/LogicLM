@Engine("duckdb");

LogicLM(
  name: "Teacher Course Analysis",
  title: "Teacher and Course Arrangement Exploration",
  tagline: "<i>Analyze teachers, courses, and their assignments.</i>",
  port: 8090,
  fact_tables: ["TeacherCourseInfo", "Teacher"],
  default_fact_table: "TeacherCourseInfo",

  dimensions: [
    "TeacherId", "TeacherName", "TeacherAge", "TeacherHometown",
    "CourseId", "CourseName", "CourseStartingDate", "CourseGrade"
  ],

  measures: [
    "NumTeachers", "NumCoursesTaught", "NumArrangements",
    "AvgTeacherAge", "MinTeacherAge", "MaxTeacherAge"
  ],

  filters: [
     "HometownIs", "HometownIsNot", "AgeIs",
     "CourseNameIs", "IsNotArranged"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Dimensions, Measures, and Filters should be predicate calls, e.g., [TeacherName(), NumCoursesTaught()].",
    "For filters, provide arguments, e.g., AgeIs(values: ['32', '33']), HometownIsNot(values: ['Little Lever Urban District']).",
    "Use list syntax for multiple filter values: HometownIs(values: ['London', 'Paris']).",
    "Order results using 'order:', e.g., order: [TeacherName() asc].",
    "Use -1 for no limit.",
    "To find the youngest teacher's hometown: query: [TeacherHometown()], order: [MinTeacherAge() asc], limit: 1.",
    "To find the most common hometown: query: [TeacherHometown(), NumTeachers()], order: [NumTeachers() desc], limit: 1.",
    "To find hometowns with >= 2 teachers: query: [TeacherHometown(), NumTeachers()], having: [NumTeachers() >= 2].",
    "To find teachers teaching >= 2 courses: query: [TeacherName(), NumCoursesTaught()], having: [NumCoursesTaught() >= 2].",
    "To find teachers not arranged: query: [TeacherName()], filters: [IsNotArranged()], fact_table: 'Teacher'.",
    "Note: Teacher Age is stored as TEXT. Aggregations like Avg/Min/Max attempt conversion."
  ]
);

Teacher(teacher_id:, name:, age:, hometown:) :-
  teacher(teacher_id:, name:, age:, hometown:);

Course(course_id:, staring_date:, course:) :-
  course(course_id:, staring_date:, course:);

CourseArrange(course_id:, teacher_id:, grade:) :-
  course_arrange(course_id:, teacher_id:, grade:);

TeacherCourseInfoT(
    teacher_id:, teacher_name: name, teacher_age: age, teacher_hometown: hometown,
    course_id:, course_name: course, course_starting_date: staring_date,
    grade:
  ) :-
  CourseArrange(course_id:, teacher_id:, grade:),
  Teacher(teacher_id:, name:, age:, hometown:),
  Course(course_id:, staring_date:, course:);

TeacherCourseInfo(r) :- TeacherCourseInfoT(..r);

TeacherId(fact) = fact.teacher_id;
TeacherName(fact) = fact.teacher_name;
TeacherAge(fact) = fact.teacher_age;
TeacherHometown(fact) = fact.teacher_hometown;
CourseId(fact) = fact.course_id;
CourseName(fact) = fact.course_name;
CourseStartingDate(fact) = fact.course_starting_date;
CourseGrade(fact) = fact.grade;

NumTeachers(fact) = Count(fact.teacher_id);
NumCoursesTaught(fact) = Count(fact.course_id);
NumArrangements(fact) = Sum(1);

SafeAge(age_text) = ToFloat(age_text) :- StringIsNumeric(age_text);
SafeAge(age_text) = null :- ~StringIsNumeric(age_text);

AvgTeacherAge(fact) = Avg(SafeAge(fact.teacher_age));
MinTeacherAge(fact) = Min(SafeAge(fact.teacher_age));
MaxTeacherAge(fact) = Max(SafeAge(fact.teacher_age));

HometownIs(fact, values:) :- Constraint(TeacherHometown(fact) in values);
HometownIsNot(fact, values:) :- Constraint(TeacherHometown(fact) not in values);
AgeIs(fact, values:) :- Constraint(TeacherAge(fact) in values);
CourseNameIs(fact, values:) :- Constraint(CourseName(fact) in values);

IsNotArranged(fact) :- ~CourseArrange(teacher_id: fact.teacher_id);