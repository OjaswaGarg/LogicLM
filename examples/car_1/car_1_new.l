
@Engine("duckdb");

LogicLM(
  name: "Cars Analysis",
  title: "Automobile Dataset Exploration",
  tagline: "<i>Analyze MPG, Horsepower, Origins, and more!</i>",
  port: 8088,
  fact_tables: ["FactTable"],
  default_fact_table: "FactTable",

  dimensions: [
    "CarId", "ContinentName", "CountryName", "MakerFullName", "MakerShortName",
    "ModelName", "MakeName", "Year", "Cylinders", "ContinentId", "CountryId",
    "MakerId", "ModelId"
  ],

  measures: [
    "NumCars", "NumModels", "NumMakers", "NumCountries", "NumContinents",
    "AvgMpg", "AvgHorsepower", "AvgWeight", "AvgEdispl", "AvgAccelerate",
    "MinHorsepower", "MaxHorsepower", "MinWeight", "MaxWeight",
    "MinAccelerate", "MaxAccelerate", "MinMpg", "MaxMpg", "MinYear", "MaxYear",
    "TotalWeight"
  ],

  filters: [
     "ContinentIs", "CountryIs", "MakerIs", "ModelIs", "MakeIs", "YearIs",
     "YearAfter", "YearBefore", "YearBetween", "CylindersIs", "CylindersMoreThan",
     "CylindersLessThan", "HorsepowerMoreThan", "HorsepowerLessThan", "WeightMoreThan",
     "WeightLessThan", "WeightBetween", "AccelerateMoreThan", "AccelerateLessThan",
     "MpgMoreThan", "MpgLessThan"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Dimensions, Measures, and Filters should be predicate calls, e.g., [MakerFullName(), NumCars()].",
    "For filters, provide arguments, e.g., YearIs(years: [1970]), WeightBetween(min_w: 3000, max_w: 4000).",
    "Use list syntax for multiple filter values: CountryIs(country_names: ['USA', 'Japan']).",
    "Order results using 'order:', e.g., order: [AvgMpg() desc].",
    "Use -1 for no limit.",
    "Remember that MPG and Horsepower are stored as text; queries attempt conversion but may yield nulls if data is non-numeric."
  ]
);

SafeHorsepower(hp_text) = ToFloat(hp_text) :- StringIsNumeric(hp_text);
SafeHorsepower(hp_text) = null :- ~StringIsNumeric(hp_text);
SafeMpg(mpg_text) = ToFloat(mpg_text) :- StringIsNumeric(mpg_text);
SafeMpg(mpg_text) = null :- ~StringIsNumeric(mpg_text);

@With(FactTableT);
FactTableT(
    car_id:,
    mpg_str:,
    cylinders:,
    edispl:,
    horsepower_str:,
    weight:,
    accelerate:,
    year:,
    make_name:,
    model_name:,
    model_id:,
    maker_id:,
    maker_short_name:,
    maker_full_name:,
    country_id:,
    country_name:,
    continent_id:,
    continent_name:
  ) :-
  cars_data(id: car_id, mpg: mpg_str, cylinders:, edispl:, horsepower: horsepower_str, weight:, accelerate:, year:),
  car_names(makeid: car_id, model: model_name, make: make_name),
  model_list(modelid: model_id, maker: maker_id, model: model_name),
  car_makers(id: maker_id, maker: maker_short_name, fullname: maker_full_name, country: country_id_str),
  countries(countryid: country_id, countryname: country_name, continent: continent_id),
  continents(contid: continent_id, continent: continent_name),
  country_id == ToInt64(country_id_str);

FactTable(r) :- FactTableT(..r);

CarId(fact) = fact.car_id;
ContinentName(fact) = fact.continent_name;
CountryName(fact) = fact.country_name;
MakerFullName(fact) = fact.maker_full_name;
MakerShortName(fact) = fact.maker_short_name;
ModelName(fact) = fact.model_name;
MakeName(fact) = fact.make_name;
Year(fact) = fact.year;
Cylinders(fact) = fact.cylinders;
ContinentId(fact) = fact.continent_id;
CountryId(fact) = fact.country_id;
MakerId(fact) = fact.maker_id;
ModelId(fact) = fact.model_id;

NumCars(fact) = Sum(1);
NumModels(fact) = Count(fact.model_name);
NumMakers(fact) = Count(fact.maker_id);
NumCountries(fact) = Count(fact.country_id);
NumContinents(fact) = Count(fact.continent_id);

AvgMpg(fact) = Avg(SafeMpg(fact.mpg_str));
AvgHorsepower(fact) = Avg(SafeHorsepower(fact.horsepower_str));
AvgWeight(fact) = Avg(fact.weight);
AvgEdispl(fact) = Avg(fact.edispl);
AvgAccelerate(fact) = Avg(fact.accelerate);

MinHorsepower(fact) = Min(SafeHorsepower(fact.horsepower_str));
MaxHorsepower(fact) = Max(SafeHorsepower(fact.horsepower_str));
MinWeight(fact) = Min(fact.weight);
MaxWeight(fact) = Max(fact.weight);
MinAccelerate(fact) = Min(fact.accelerate);
MaxAccelerate(fact) = Max(fact.accelerate);
MinMpg(fact) = Min(SafeMpg(fact.mpg_str));
MaxMpg(fact) = Max(SafeMpg(fact.mpg_str));
MinYear(fact) = Min(fact.year);
MaxYear(fact) = Max(fact.year);
TotalWeight(fact) = Sum(fact.weight);

ContinentIs(fact, continent_names:) :- Constraint(ContinentName(fact) in continent_names);
CountryIs(fact, country_names:) :- Constraint(CountryName(fact) in country_names);
MakerIs(fact, maker_names:) :- Constraint(MakerFullName(fact) in maker_names);
ModelIs(fact, model_names:) :- Constraint(ModelName(fact) in model_names);
MakeIs(fact, make_names:) :- Constraint(MakeName(fact) in make_names);
YearIs(fact, years:) :- Constraint(Year(fact) in years);
CylindersIs(fact, cylinders_list:) :- Constraint(Cylinders(fact) in cylinders_list);

YearAfter(fact, year:) :- fact.year > year;
YearBefore(fact, year:) :- fact.year < year;
YearBetween(fact, min_year:, max_year:) :- fact.year >= min_year, fact.year <= max_year;

CylindersMoreThan(fact, cylinders:) :- fact.cylinders > cylinders;
CylindersLessThan(fact, cylinders:) :- fact.cylinders < cylinders;

HorsepowerMoreThan(fact, hp:) :- SafeHorsepower(fact.horsepower_str) > hp;
HorsepowerLessThan(fact, hp:) :- SafeHorsepower(fact.horsepower_str) < hp;

WeightMoreThan(fact, weight:) :- fact.weight > weight;
WeightLessThan(fact, weight:) :- fact.weight < weight;
WeightBetween(fact, min_w:, max_w:) :- fact.weight >= min_w, fact.weight <= max_w;

AccelerateMoreThan(fact, acc:) :- fact.accelerate > acc;
AccelerateLessThan(fact, acc:) :- fact.accelerate < acc;

MpgMoreThan(fact, mpg_val:) :- SafeMpg(fact.mpg_str) > mpg_val;
MpgLessThan(fact, mpg_val:) :- SafeMpg(fact.mpg_str) < mpg_val;