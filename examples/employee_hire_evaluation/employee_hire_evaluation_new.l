@Engine("duckdb");

LogicLM(
  name: "HR Analysis",
  title: "Employee and Shop Data Exploration",
  tagline: "<i>Analyze employee demographics, hiring, evaluations, and shop details.</i>",
  port: 8089,
  fact_tables: ["Employee", "Shop", "Hiring", "Evaluation", "EmployeeHiringInfo"],
  default_fact_table: "EmployeeHiringInfo",

  dimensions: [
    "EmployeeId", "EmployeeName", "EmployeeAge", "EmployeeCity",
    "ShopId", "ShopName", "ShopLocation", "ShopDistrict", "ManagerName",
    "HiringStartFrom", "HiringIsFullTime",
    "EvaluationYear",
    "NumProducts"
  ],

  measures: [
    "NumEmployees", "NumShops", "NumHiringRecords", "NumEvaluations",
    "MinEmployeeAge", "MaxEmployeeAge", "AvgEmployeeAge",
    "MinNumProducts", "MaxNumProducts", "AvgNumProducts", "TotalNumProducts",
    "MinBonus", "MaxBonus", "AvgBonus", "TotalBonus",
    "NumDistinctCities", "NumDistinctLocations", "NumDistinctDistricts",
    "NumEmployeesHired",
    "NumAwardsPerEmployee"
  ],

  filters: [
    "EmployeeCityIs", "EmployeeAgeLessThan", "EmployeeAgeMoreThan", "EmployeeAgeBetween",
    "ShopLocationIs", "ShopDistrictIs", "ShopHasProductsLessThan", "ShopHasProductsMoreThan",
    "ShopHasProductsBetween",
    "HiredFullTime", "HiredPartTime",
    "EvaluationYearIs", "BonusMoreThan", "BonusLessThan"
  ],

  suffix_lines: [
    "Use predicates like Employee(), Shop(), Hiring(), Evaluation(), EmployeeHiringInfo() as fact tables.",
    "Dimensions, Measures, and Filters are predicate calls, e.g., [EmployeeCity(), NumEmployees()].",
    "For filters, provide arguments, e.g., EmployeeAgeLessThan(age: 30), ShopDistrictIs(district_name: 'Central').",
    "Use list syntax for multiple filter values: EmployeeCityIs(cities: ['London', 'Paris']).",
    "Order results using 'order:', e.g., order: [EmployeeAge() asc].",
    "Use -1 for no limit.",
    "Example: 'Count employees per city': Run [EmployeeCity(), NumEmployees()] on Employee() table.",
    "Example: 'Shops sorted by product count': Run [ShopName(), ShopLocation(), ShopDistrict(), NumProducts()] on Shop() table, order: [NumProducts() desc].",
    "Example: 'Employees with no awards': Run [EmployeeName()] on Employee() table where: ~HasEvaluation()."
  ]
);

Employee(employee_id:, name:, age:, city:) :-
  employee(employee_id:, name:, age:, city:);

Shop(shop_id:, name:, location:, district:, number_products:, manager_name:) :-
  shop(shop_id:, name:, location:, district:, number_products:, manager_name:);

Hiring(shop_id:, employee_id:, start_from:, is_full_time:) :-
  hiring(shop_id:, employee_id:, start_from:, is_full_time:);

Evaluation(employee_id:, year_awarded:, bonus:) :-
  evaluation(employee_id:, year_awarded:, bonus:);

EmployeeHiringInfoT(
    employee_id:, employee_name:, employee_age:, employee_city:,
    shop_id:, shop_name:, shop_location:, shop_district:,
    hiring_start_from:, hiring_is_full_time:
  ) :-
  Employee(employee_id:, name: employee_name, age: employee_age, city: employee_city),
  Hiring(shop_id:, employee_id:, start_from: hiring_start_from, is_full_time: hiring_is_full_time),
  Shop(shop_id:, name: shop_name, location: shop_location, district: shop_district);

EmployeeHiringInfo(r) :- EmployeeHiringInfoT(..r);

EmployeeId(e) = e.employee_id;
EmployeeName(e) = x :-
  x == (
    if e.name != null then
      e.name
    else
      e.employee_name
  );
EmployeeAge(e) = x :-
  x == (
    if e.age != null then
      e.age
    else
      e.employee_age
  );

EmployeeCity(e) = x :-
  x == (
    if e.city != null then
      e.city
    else
      e.employee_city
  );

ShopId(s) = s.shop_id;
ShopName(s) = x :-
  x == (
    if s.name != null then
      s.name
    else
      s.shop_name
  );

ShopLocation(s) = x :-
  x == (
    if s.location != null then
      s.location
    else
      s.shop_location
  );

ShopDistrict(s) = x :-
  x == (
    if s.district != null then
      s.district
    else
      s.shop_district
  );
NumProducts(s) = s.number_products;
ManagerName(s) = s.manager_name;

HiringStartFrom(h) = x :-
  x == (
    if h.start_from != null then
      h.start_from
    else
      h.hiring_start_from
  );

HiringIsFullTime(h) = x :-
  x == (
    if h.is_full_time != null then
      h.is_full_time
    else
      h.hiring_is_full_time
  );

EvaluationYear(ev) = ev.year_awarded;

NumEmployees(e) = Count(e.employee_id);
NumShops(s) = Count(1);
NumHiringRecords(h) = Count(1);
NumEvaluations(ev) = Count(1);

MinEmployeeAge(e) = Min(EmployeeAge(e));
MaxEmployeeAge(e) = Max(EmployeeAge(e));
AvgEmployeeAge(e) = Avg(EmployeeAge(e));

MinNumProducts(s) = Min(s.number_products);
MaxNumProducts(s) = Max(s.number_products);
AvgNumProducts(s) = Avg(s.number_products);
TotalNumProducts(s) = Sum(s.number_products);

MinBonus(ev) = Min(ev.bonus);
MaxBonus(ev) = Max(ev.bonus);
AvgBonus(ev) = Avg(ev.bonus);
TotalBonus(ev) = Sum(ev.bonus);

NumDistinctCities(e) = Count(EmployeeCity(e));
NumDistinctLocations(s) = Count(ShopLocation(s));
NumDistinctDistricts(s) = Count(ShopDistrict(s));

NumEmployeesHired(h) = Count(h.employee_id);

NumAwardsPerEmployee(ev) = Count(ev.year_awarded);

EmployeeCityIs(e, cities:) :- Constraint(EmployeeCity(e) in cities);
EmployeeAgeLessThan(e, age:) :- EmployeeAge(e) < age;
EmployeeAgeMoreThan(e, age:) :- EmployeeAge(e) > age;
EmployeeAgeBetween(e, min_age:, max_age:) :- EmployeeAge(e) >= min_age, EmployeeAge(e) <= max_age;

ShopLocationIs(s, locations:) :- Constraint(ShopLocation(s) in locations);
ShopDistrictIs(s, districts:) :- Constraint(ShopDistrict(s) in districts);
ShopHasProductsLessThan(s, count:) :- s.number_products < count;
ShopHasProductsMoreThan(s, count:) :- s.number_products > count;
ShopHasProductsBetween(s, min_count:, max_count:) :- s.number_products >= min_count, s.number_products <= max_count;

HiredFullTime(h) :- HiringIsFullTime(h) == true;
HiredPartTime(h) :- HiringIsFullTime(h) == false;

EvaluationYearIs(ev, years:) :- Constraint(ev.year_awarded in years);
BonusMoreThan(ev, amount:) :- ev.bonus > amount;
BonusLessThan(ev, amount:) :- ev.bonus < amount;

HasEvaluation(employee_id:) :- Evaluation(employee_id:);

ShopHiresEmployee(shop_id:) :- Hiring(shop_id:);

ShopWithLess3k(district:) distinct :- Shop(district:, number_products:), number_products < 3000;
ShopWithMore10k(district:) distinct :- Shop(district:, number_products:), number_products > 10000;

DistrictWithProductRange(district:) :- ShopWithLess3k(district:), ShopWithMore10k(district:);
