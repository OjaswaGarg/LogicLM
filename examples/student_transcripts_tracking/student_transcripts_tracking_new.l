@Engine("duckdb");

LogicLM(
  name: "University DB Analysis",
  title: "Student, Course, and Enrollment Data",
  tagline: "<i>Explore university records including students, courses, degrees, enrollments, and transcripts.</i>",
  port: 8090,
  fact_tables: ["FactTable", "Students", "Addresses", "Courses", "Departments", "DegreePrograms", "Sections", "Semesters", "StudentEnrolment", "StudentEnrolmentCourses", "Transcripts", "TranscriptContents"],
  default_fact_table: "FactTable",

  dimensions: [
    "AddressId", "AddressLine1", "AddressLine2", "AddressCity", "AddressZipCode", "AddressState", "AddressCountry",
    "CourseId", "CourseName", "CourseDescription",
    "DepartmentId", "DepartmentName", "DepartmentDescription",
    "DegreeProgramId", "DegreeName", "DegreeDescription",
    "SectionId", "SectionName", "SectionDescription",
    "SemesterId", "SemesterName",
    "StudentId", "StudentFirstName", "StudentMiddleName", "StudentLastName", "StudentPhone", "StudentEmail", "StudentSSN", "StudentRegDate", "StudentLeftDate", "StudentCurrentAddressId", "StudentPermanentAddressId",
    "StudentEnrolmentId", "StudentCourseId",
    "TranscriptId", "TranscriptDate"
  ],

  measures: [
    "NumCourses", "NumDepartments", "NumDepartmentsOfferingDegrees", "NumDegreePrograms", "NumDistinctDegreeNames",
    "NumSections", "NumSemesters", "NumStudents", "NumTranscripts",
    "NumDegreesPerDepartment", "NumSectionsPerCourse", "NumStudentsPerSemester", "NumStudentsPerDegree",
    "NumEnrollmentsPerStudent", "NumCoursesPerTranscript", "MaxEnrollmentsPerStudent",
    "MaxTimesCourseInTranscript", "MinCoursesPerTranscript", "AvgTranscriptDate"
  ],

  filters: [
     "AddressCityIs", "AddressStateIs", "AddressCountryIs",
     "CourseNameContains", "DepartmentNameContains",
     "DegreeNameContains",
     "SectionNameIs",
     "SemesterHasNoStudents", "SemesterHasMastersAndBachelors",
     "StudentLivesInState", "StudentInCountryPermanently", "StudentHasPhoneNumber",
     "StudentFirstNameIs", "StudentLastNameIs", "PermanentAddressDiffersFromCurrent",
     "StudentNotEnrolled", "StudentEnrolledInBachelor", "StudentEnrolledInTwoProgramsInSemester",
     "CourseHasEnrollments",
     "TranscriptHasAtLeastNCourses"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Dimensions, Measures, and Filters should be predicate calls, e.g., [DepartmentName(), NumDegreesPerDepartment()].",
    "For filters, provide arguments, e.g., AddressCityIs(city: 'Port Chelsea'), TranscriptHasAtLeastNCourses(min_courses: 2).",
    "Use list syntax for multiple filter values if applicable.",
    "Order results using 'order:', e.g., order: [StudentRegDate() asc].",
    "Use -1 for no limit.",
    "To find extrema (e.g., department with most degrees), use measures and order: query: [DepartmentName(), NumDegreesPerDepartment()], order: [NumDegreesPerDepartment() desc], limit: 1."
  ]
);

Addresses(address_id:, line_1:, line_2:, line_3:, city:, zip_postcode:, state_province_county:, country:, other_address_details:) :-
  addresses(address_id:, line_1:, line_2:, line_3:, city:, zip_postcode:, state_province_county:, country:, other_address_details:);

Courses(course_id:, course_name:, course_description:, other_details:) :-
  courses(course_id:, course_name:, course_description:, other_details:);

Departments(department_id:, department_name:, department_description:, other_details:) :-
  departments(department_id:, department_name:, department_description:, other_details:);

DegreePrograms(degree_program_id:, department_id:, degree_summary_name:, degree_summary_description:, other_details:) :-
  degree_programs(degree_program_id:, department_id:, degree_summary_name:, degree_summary_description:, other_details:);

Sections(section_id:, course_id:, section_name:, section_description:, other_details:) :-
  sections(section_id:, course_id:, section_name:, section_description:, other_details:);

Semesters(semester_id:, semester_name:, semester_description:, other_details:) :-
  semesters(semester_id:, semester_name:, semester_description:, other_details:);

Students(student_id:, current_address_id:, permanent_address_id:, first_name:, middle_name:, last_name:, cell_mobile_number:, email_address:, ssn:, date_first_registered:, date_left:, other_student_details:) :-
  students(student_id:, current_address_id:, permanent_address_id:, first_name:, middle_name:, last_name:, cell_mobile_number:, email_address:, ssn:, date_first_registered:, date_left:, other_student_details:);

StudentEnrolment(student_enrolment_id:, degree_program_id:, semester_id:, student_id:, other_details:) :-
  student_enrolment(student_enrolment_id:, degree_program_id:, semester_id:, student_id:, other_details:);

StudentEnrolmentCourses(student_course_id:, course_id:, student_enrolment_id:) :-
  student_enrolment_courses(student_course_id:, course_id:, student_enrolment_id:);

Transcripts(transcript_id:, transcript_date:, other_details:) :-
  transcripts(transcript_id:, transcript_date:, other_details:);

TranscriptContents(student_course_id:, transcript_id:) :-
  transcript_contents(student_course_id:, transcript_id:);

FactTableT(
    student_id:, first_name:, middle_name:, last_name:, cell_mobile_number:, email_address:, ssn:, date_first_registered:, date_left:,
    current_address_id:, permanent_address_id:,
    current_addr_line1:, current_addr_line2:, current_addr_city:, current_addr_zip:, current_addr_state:, current_addr_country:,
    permanent_addr_line1:, permanent_addr_line2:, permanent_addr_city:, permanent_addr_zip:, permanent_addr_state:, permanent_addr_country:,
    student_enrolment_id:, degree_program_id:, semester_id:,
    degree_summary_name:, degree_summary_description:, department_id:,
    department_name:, department_description:,
    semester_name:,
    student_course_id:, course_id:,
    course_name:, course_description:
  ) :-
  Students(student_id:, current_address_id:, permanent_address_id:, first_name:, middle_name:, last_name:, cell_mobile_number:, email_address:, ssn:, date_first_registered:, date_left:),
  Addresses(address_id: current_address_id, line_1: current_addr_line1, line_2: current_addr_line2, city: current_addr_city, zip_postcode: current_addr_zip, state_province_county: current_addr_state, country: current_addr_country),
  Addresses(address_id: permanent_address_id, line_1: permanent_addr_line1, line_2: permanent_addr_line2, city: permanent_addr_city, zip_postcode: permanent_addr_zip, state_province_county: permanent_addr_state, country: permanent_addr_country),
  StudentEnrolment(student_enrolment_id:, degree_program_id:, semester_id:, student_id:),
  DegreePrograms(degree_program_id:, department_id:, degree_summary_name:, degree_summary_description:),
  Departments(department_id:, department_name:, department_description:),
  Semesters(semester_id:, semester_name:),
  StudentEnrolmentCourses(student_course_id:, course_id:, student_enrolment_id:),
  Courses(course_id:, course_name:, course_description:);

FactTable(r) :- FactTableT(..r);

AddressId(fact) = fact.current_address_id;
AddressLine1(fact) = fact.current_addr_line1;
AddressLine2(fact) = fact.current_addr_line2;
AddressCity(fact) = fact.current_addr_city;
AddressZipCode(fact) = fact.current_addr_zip;
AddressState(fact) = fact.current_addr_state;
AddressCountry(fact) = fact.current_addr_country;

CourseId(fact) = fact.course_id;
CourseName(fact) = fact.course_name;
CourseDescription(fact) = fact.course_description;

DepartmentId(fact) = fact.department_id;
DepartmentName(fact) = fact.department_name;
DepartmentDescription(fact) = fact.department_description;

DegreeProgramId(fact) = fact.degree_program_id;
DegreeName(fact) = fact.degree_summary_name;
DegreeDescription(fact) = fact.degree_summary_description;

SectionId(s) = s.section_id :- Sections(..s);
SectionName(s) = s.section_name :- Sections(..s);
SectionDescription(s) = s.section_description :- Sections(..s);

SemesterId(fact) = fact.semester_id;
SemesterName(fact) = fact.semester_name;

StudentId(fact) = fact.student_id;
StudentFirstName(fact) = fact.first_name;
StudentMiddleName(fact) = fact.middle_name;
StudentLastName(fact) = fact.last_name;
StudentPhone(fact) = fact.cell_mobile_number;
StudentEmail(fact) = fact.email_address;
StudentSSN(fact) = fact.ssn;
StudentRegDate(fact) = fact.date_first_registered;
StudentLeftDate(fact) = fact.date_left;
StudentCurrentAddressId(fact) = fact.current_address_id;
StudentPermanentAddressId(fact) = fact.permanent_address_id;

StudentEnrolmentId(fact) = fact.student_enrolment_id;
StudentCourseId(fact) = fact.student_course_id;

TranscriptId(t) = t.transcript_id :- Transcripts(..t);
TranscriptDate(t) = t.transcript_date :- Transcripts(..t);

NumCourses() = Count(c.course_id) :- Courses(..c);
NumDepartments() = Count(d.department_id) :- Departments(..d);
NumDepartmentsOfferingDegrees() = Count(Distinct(dp.department_id)) :- DegreePrograms(..dp);
NumDegreePrograms() = Count(dp.degree_program_id) :- DegreePrograms(..dp);
NumDistinctDegreeNames() = Count(Distinct(dp.degree_summary_name)) :- DegreePrograms(..dp);
NumSections() = Count(s.section_id) :- Sections(..s);
NumSemesters() = Count(s.semester_id) :- Semesters(..s);
NumStudents() = Count(s.student_id) :- Students(..s);
NumTranscripts() = Count(t.transcript_id) :- Transcripts(..t);

NumDegreesPerDepartment(fact) = Count(fact.degree_program_id);
NumSectionsPerCourse(course_id_val) = Count(s.section_id) :- Sections(course_id: course_id_val, ..s);
NumStudentsPerSemester(fact) = Count(fact.student_id);
NumStudentsPerDegree(fact) = Count(fact.student_id);
NumEnrollmentsPerStudent(student_id_val) = Count(se.student_enrolment_id) :- StudentEnrolment(student_id: student_id_val, ..se);
NumCoursesPerTranscript(transcript_id_val) = Count(tc.student_course_id) :- TranscriptContents(transcript_id: transcript_id_val, ..tc);

MaxEnrollmentsPerStudent() = Max(enroll_count) :- enroll_count = NumEnrollmentsPerStudent(sid), Students(student_id: sid);
MaxTimesCourseInTranscript() = Max(transcript_count) :- transcript_count = NumTimesCourseInTranscript(scid), StudentEnrolmentCourses(student_course_id: scid);
MinCoursesPerTranscript() = Min(course_count) :- course_count = NumCoursesPerTranscript(tid), Transcripts(transcript_id: tid);
AvgTranscriptDate() = Avg(t.transcript_date) :- Transcripts(..t);
NumTimesCourseInTranscript(sc_id) = Count(tc.transcript_id) :- TranscriptContents(student_course_id: sc_id, ..tc);

AddressCityIs(fact, city:) :- fact.current_addr_city == city;
AddressStateIs(fact, state:) :- fact.current_addr_state == state;
AddressCountryIs(fact, country:) :- fact.current_addr_country == country;

CourseNameContains(fact, substr:) :- Contains(fact.course_name, substr);
DepartmentNameContains(fact, substr:) :- Contains(fact.department_name, substr);
DegreeNameContains(fact, substr:) :- Contains(fact.degree_summary_name, substr);
SectionNameIs(s, name:) :- s.section_name == name, Sections(..s);

SemesterHasNoStudents(semester_id_val) :- Semesters(semester_id: semester_id_val), ~StudentEnrolment(semester_id: semester_id_val);
SemesterHasMastersAndBachelors(semester_id_val) :-
  StudentEnrolment(semester_id: semester_id_val, degree_program_id: dpid1), DegreePrograms(degree_program_id: dpid1, degree_summary_name: n1), Contains(n1, "Bachelor"),
  StudentEnrolment(semester_id: semester_id_val, degree_program_id: dpid2), DegreePrograms(degree_program_id: dpid2, degree_summary_name: n2), Contains(n2, "Master");

StudentLivesInState(fact, state:) :- fact.current_addr_state == state;
StudentInCountryPermanently(s, country:) :- Students(..s), Addresses(address_id: s.permanent_address_id, country: country);
StudentHasPhoneNumber(s, phone:) :- Students(..s), s.cell_mobile_number == phone;
StudentFirstNameIs(fact, name:) :- fact.first_name == name;
StudentLastNameIs(fact, name:) :- fact.last_name == name;
PermanentAddressDiffersFromCurrent(fact) :- fact.current_address_id != fact.permanent_address_id;
StudentNotEnrolled(s) :- Students(..s), ~StudentEnrolment(student_id: s.student_id);
StudentEnrolledInBachelor(fact) :- Contains(fact.degree_summary_name, "Bachelor");

IsEnrolledInMultipleProgramsInSemester(s_id, sem_id) :-
  Count(Distinct(se.degree_program_id)) >= 2 :- StudentEnrolment(student_id: s_id, semester_id: sem_id, ..se);
StudentEnrolledInTwoProgramsInSemester(fact) :- IsEnrolledInMultipleProgramsInSemester(fact.student_id, fact.semester_id);

CourseHasEnrollments(course_id_val) :- StudentEnrolmentCourses(course_id: course_id_val);
TranscriptHasAtLeastNCourses(transcript_id_val, min_courses:) :- NumCoursesPerTranscript(transcript_id_val) >= min_courses;