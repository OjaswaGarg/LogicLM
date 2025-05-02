@Engine("sqlite");

LogicLM(
  name: "HR Shops Analysis",
  title: "Employee, Shop, Hiring, and Evaluation Data",
  tagline: "<i>Analyze relationships across HR and Shop data.</i>",
  port: 8090,
  fact_tables: ["EmployeeShopInfo", "Employee", "Shop", "Hiring", "Evaluation"],
  default_fact_table: "EmployeeShopInfo",

  dimensions: [
    "EmployeeId", "EmployeeName", "EmployeeAge", "EmployeeCity",
    "ShopId", "ShopName", "ShopLocation", "ShopDistrict", "ShopNumProducts", "ShopManagerName",
    "HiringStartFrom", "HiringIsFullTime",
    "EvaluationYear", "EvaluationBonus"
  ],

  measures: [
    "NumEmployees", "NumDistinctEmployees",
    "NumShops", "NumDistinctShops",
    "NumHiringRecords", "NumEvaluationRecords",
    "NumDistinctLocations",
    "AvgEmployeeAge",
    "MinShopProducts", "MaxShopProducts", "AvgShopProducts",
    "TotalBonus", "MaxBonus", "AvgBonus",
    "NumAwardsPerEmployee", "NumEmployeesPerShop"
  ],

  filters: [
     "EmployeeAgeLessThan", "EmployeeAgeGreaterThan", "EmployeeAgeIs",
     "EmployeeCityIs",
     "ShopLocationIs", "ShopDistrictIs",
     "ShopNumProductsLessThan", "ShopNumProductsGreaterThan",
     "HasEvaluation", "HasNoEvaluation",
     "IsHired", "IsNotHired",
     "ShopHasEmployees", "ShopHasNoEmployees",
     "ShopProductsAboveAvg"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Default Fact Table is 'EmployeeShopInfo' (joined Employee, Hiring, Shop).",
    "Use 'Employee', 'Shop', 'Hiring', 'Evaluation' fact tables for specific queries.",
    "Dimensions/Measures related to Evaluation only work on 'Evaluation' fact table.",
    "Dimensions/Measures specific to Hiring only work on 'Hiring' or 'EmployeeShopInfo'.",
    "Dimensions like EmployeeName are available on 'Employee' and 'EmployeeShopInfo'.",
    "Measures like TotalBonus require the 'Evaluation' fact table.",
    "Example: query: [EmployeeName()], order: [EmployeeAge() asc]",
    "Example: query: [EmployeeCity(), NumDistinctEmployees()], fact_table: 'Employee'",
    "Example: query: [ShopLocation(), NumDistinctShops()], fact_table: 'Shop'",
    "Example: query: [ShopName(), NumEmployeesPerShop()], fact_table: 'EmployeeShopInfo'",
    "Example: query: [EmployeeName(), MaxBonus()], fact_table: 'Evaluation', limit: 1, order: [MaxBonus() desc]",
    "To find shops above average products: query: [ShopName(), ShopNumProducts()], fact_table: 'Shop', having: [ShopProductsAboveAvg()]",
    "To find employees never evaluated: query: [EmployeeName()], fact_table: 'Employee', having: [HasNoEvaluation()]",
    "To find districts with shops <3000 and >10000 products: query: [ShopDistrict()], fact_table: 'Shop', group_by: [ShopDistrict()], having: [MinShopProducts() < 3000, MaxShopProducts() > 10000]"
  ]
);

Employee(employee_id:, name:, age:, city:) :-
    employee(employee_id:, name:, age:, city:);

Shop(shop_id:, name:, location:, district:, number_products:, manager_name:) :-
    shop(shop_id:, name:, location:, district:, number_products:, manager_name:);

Hiring(shop_id:, employee_id:, start_from:, is_full_time:) :-
    hiring(shop_id:, employee_id:, start_from:, is_full_time:);

Evaluation(employee_id:, year_awarded:, bonus:) :-
    evaluation(employee_id: eid_text, year_awarded:, bonus:),
    employee_id == ToInt64(eid_text);

EmployeeShopInfoT(
    employee_id: employee_id, emp_name: name, emp_age: age, emp_city: city,
    shop_id: shop_id, shop_name: name, shop_location: location, shop_district: district,
    shop_num_products: number_products, shop_manager: manager_name,
    hiring_start_from: start_from, hiring_is_full_time: is_full_time
  ) :-
    Employee(employee_id:, name:, age:, city:),
    Hiring(shop_id:, employee_id:employee_id, start_from:, is_full_time:),
    Shop(shop_id:shop_id, name:, location:, district:, number_products:, manager_name:);

EmployeeShopInfo(r) :- EmployeeShopInfoT(..r);

EmployeeId(fact) = fact.employee_id;
EmployeeName(fact) = fact.emp_name ;
EmployeeAge(fact) = fact.emp_age;
EmployeeCity(fact) = fact.emp_city;
ShopId(fact) = fact.shop_id;
ShopName(fact) = fact.shop_name;
ShopLocation(fact) = fact.shop_location;
ShopDistrict(fact) = fact.shop_district;
ShopNumProducts(fact) = fact.shop_num_products;
ShopManagerName(fact) = fact.shop_manager;
HiringStartFrom(fact) = fact.hiring_start_from;
HiringIsFullTime(fact) = fact.hiring_is_full_time;
EvaluationYear(fact) = fact.year_awarded;
EvaluationBonus(fact) = fact.bonus;

NumEmployees(fact) = Sum(1);
NumDistinctEmployees(fact) = Count(Distinct(fact.employee_id));
NumShops(fact) = Sum(1);
NumDistinctShops(fact) = Count(Distinct(fact.shop_id));
NumHiringRecords(fact) = Sum(1);
NumEvaluationRecords(fact) = Sum(1);
NumDistinctLocations(fact) = Count(Distinct(ShopLocation(fact)));
AvgEmployeeAge(fact) = Avg(EmployeeAge(fact));
MinShopProducts(fact) = Min(ShopNumProducts(fact));
MaxShopProducts(fact) = Max(ShopNumProducts(fact));
AvgShopProducts(fact) = Avg(ShopNumProducts(fact));
TotalBonus(fact) = Sum(EvaluationBonus(fact));
MaxBonus(fact) = Max(EvaluationBonus(fact));
AvgBonus(fact) = Avg(EvaluationBonus(fact));
NumAwardsPerEmployee(fact) = Sum(1);
NumEmployeesPerShop(fact) = Count(Distinct(fact.employee_id));


EmployeeAgeLessThan(fact, value:) :- EmployeeAge(fact) < value;
EmployeeAgeGreaterThan(fact, value:) :- EmployeeAge(fact) > value;
EmployeeAgeIs(fact, value:) :- EmployeeAge(fact) == value;
EmployeeCityIs(fact, city_name:) :- EmployeeCity(fact) == city_name;
ShopLocationIs(fact, loc_name:) :- ShopLocation(fact) == loc_name;
ShopDistrictIs(fact, dist_name:) :- ShopDistrict(fact) == dist_name;
ShopNumProductsLessThan(fact, value:) :- ShopNumProducts(fact) < value;
ShopNumProductsGreaterThan(fact, value:) :- ShopNumProducts(fact) > value;

HasEvaluation(fact) :- Evaluation(employee_id: fact.employee_id);
HasNoEvaluation(fact) :- ~Evaluation(employee_id: fact.employee_id);

IsHired(fact) :- Hiring(employee_id: fact.employee_id);
IsNotHired(fact) :- ~Hiring(employee_id: fact.employee_id);

ShopHasEmployees(fact) :- Hiring(shop_id: fact.shop_id);
ShopHasNoEmployees(fact) :- ~Hiring(shop_id: fact.shop_id);

AvgShopProductsGlobally() = Avg{p :- Shop(number_products: p)};
ShopProductsAboveAvg(fact) :- ShopNumProducts(fact) > AvgShopProductsGlobally();