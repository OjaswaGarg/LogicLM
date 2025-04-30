@Engine("duckdb");
# LogicLM Configuration (Example)
LogicLM(
    name: "Car Database Analysis",
    title: "Car Data Exploration",
    tagline: "Explore car manufacturers, models, and specifications.",
    port: 8080,  # Choose a port for the LogicLM interface
    fact_tables: ["CarFacts"],
    default_fact_table: "CarFacts",
    dimensions: ["Continent", "CountryName", "Maker", "Model", "Year", "Cylinders"],
    measures: ["CountryCount", "ModelCount", "AvgMPG", "AvgHorsepower", "AvgWeight"],
    filters: ["ContinentFilter", "CountryFilter", "MakerFilter", "YearFilter"],
    suffix_lines: [
        "Use Table() chart type by default.",
        "Use parameter names for filters (e.g., ContinentFilter(continents: ['Europe'])).",
        "Specify order after a space (e.g., order: [Maker() asc]).",
        "Use -1 for no limit."
    ]
);

@With(CarFactsT);
CarFactsT(
    continent_id:, continent_name:, country_id:, country_name:,
    maker_id:, maker_name:, maker_fullname:, model_id:, model_name:,
    mpg:, cylinders:, edispl:, horsepower:, weight:, accelerate:, year:
) :-
    continents(contid: continent_id, continent: continent_name),
    countries(countryid: country_id, countryname: country_name, continent: continent_id),
    car_makers(id: maker_id, maker: maker_name, fullname: maker_fullname, country: country_id),
    model_list(modelid: model_id, maker: maker_id, model: model_name),
    cars_data(id:, model: model_id, mpg:, cylinders:, edispl:, horsepower:, weight:, accelerate:, year:);

CarFacts(r) :- CarFactsT(..r);


# Dimensions
Continent(fact) = fact.continent_name;
CountryName(fact) = fact.country_name;
Maker(fact) = fact.maker_fullname;
Model(fact) = fact.model_name;
Year(fact) = fact.year;
Cylinders(fact) = fact.cylinders;

# Measures
CountryCount(fact) = Count(fact.country_id);
ModelCount(fact) = Count(fact.model_id);

AvgMPG(fact) = Avg(ToFloat64(fact.mpg)); # Convert mpg to a numeric type before averaging
AvgHorsepower(fact) = Avg(ToFloat64(fact.horsepower)); # Convert horsepower to numeric
AvgWeight(fact) = Avg(fact.weight);

# Filters
ContinentFilter(fact, continents:) :- Constraint(fact.continent_name in continents);
CountryFilter(fact, countries:) :- Constraint(fact.country_name in countries);
MakerFilter(fact, makers:) :- Constraint(fact.maker_fullname in makers);
YearFilter(fact, years:) :- Constraint(fact.year in years);
