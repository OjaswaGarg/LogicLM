@Engine("sqlite");
# LogicLM Configuration (for interactive exploration)
LogicLM(
    name: "Car Database Exploration",
    title: "Car Data Analysis",
    tagline: "Explore car data by continent, country, maker, and model.",
    port: 8080,  -- Choose a port
    fact_tables: ["CarsFact"],
    default_fact_table: "CarsFact",
    dimensions: [
        "ContinentName", "CountryName", "MakerName", "ModelName", "Year"
    ],
    measures: [
        "NumberOfModels", "AvgMPG", "AvgHorsepower", "NumberOfCars"
    ],
    filters: [
        "FilterByContinent", "FilterByCountry", "FilterByMaker", "FilterByYear"
    ]
);


# Fact Table (combining relevant data)
CarsFact(
    continent_id:, continent_name:,
    country_id:, country_name:,
    maker_id:, maker_name:,
    model_id:, model_name:,
    mpg:, horsepower:, year:
) :-
    continents(contid: continent_id, continent: continent_name),
    countries(countryid: country_id, countryname: country_name, continent: continent_id),
    car_makers(id: maker_id, fullname: maker_name, country: country_id),
    model_list(modelid: model_id, maker: maker_id, model: model_name),
    cars_data(id: car_id, mpg:, cylinders:, edispl:, horsepower:, weight:, accelerate:, year:, model: model_id);   



# Dimensions
ContinentName(fact) = fact.continent_name;
CountryName(fact) = fact.country_name;
MakerName(fact) = fact.maker_name;
ModelName(fact) = fact.model_name;
Year(fact) = fact.year;

# Measures
NumberOfModels(fact) = CountDistinct(fact.model_name);
AvgMPG(fact) = Avg(SafeCast(fact.mpg, 'DOUBLE'));  -- Handle potential text MPG
AvgHorsepower(fact) = Avg(SafeCast(fact.horsepower, 'DOUBLE')); -- Handle potential text Horsepower
NumberOfCars(fact) = Count(fact.id);  -- Assuming id is unique in cars_data



# Filters
FilterByContinent(fact, continents:) :- Constraint(fact.continent_name in continents);
FilterByCountry(fact, countries:) :- Constraint(fact.country_name in countries);
FilterByMaker(fact, makers:) :- Constraint(fact.maker_name in makers);
FilterByYear(fact, years:) :- Constraint(fact.year in years);




# Predicates to answer specific questions (outside LogicLM config)

NumberOfContinents(count?Count=1) :- continents();

CountriesPerContinent(continent_id:, continent_name:, num_countries?Count=1) :-
    continents(contid: continent_id, continent: continent_name),
    countries(continent: continent_id);

NumberOfCountries(count?Count=1) :- countries();


ModelsPerMaker(maker_name:, maker_id:, num_models?Count=1) :-
    car_makers(fullname: maker_name, id: maker_id),
    model_list(maker: maker_id);

ModelWithMinHP(model_name:) :-
    cars_data(model: model_id, horsepower: hp),
    hp == Min{horsepower :- cars_data(horsepower:)}, #Find minimum horsepower
    model_list(modelid: model_id, model: model_name);
