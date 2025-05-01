@Engine("duckdb");

LogicLM(
  name: "Airline Flight Analysis",
  title: "Flight Network Exploration",
  tagline: "<i>Query airlines, airports, and flight routes.</i>",
  port: 8090,
  fact_tables: ["FactTable"],
  default_fact_table: "FactTable",

  dimensions: [
    "AirlineId", "AirlineName", "AirlineAbbreviation", "AirlineCountry",
    "SourceAirportCode", "SourceAirportName", "SourceCity", "SourceCountry",
    "DestAirportCode", "DestAirportName", "DestCity", "DestCountry",
    "FlightNumber"
  ],

  measures: [
    "NumFlights", "NumDistinctAirlines", "NumDistinctSourceAirports", "NumDistinctDestAirports",
    "TotalNumAirlines", "TotalNumAirports", "TotalNumFlights"
  ],

  filters: [
     "AirlineNameIs", "AirlineAbbreviationIs", "AirlineCountryIs",
     "SourceAirportCodeIs", "SourceAirportNameIs", "SourceCityIs", "SourceCountryIs",
     "DestAirportCodeIs", "DestAirportNameIs", "DestCityIs", "DestCountryIs"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Dimensions, Measures, and Filters should be predicate calls, e.g., [AirlineName(), NumFlights()].",
    "For filters, provide arguments, e.g., AirlineNameIs(name: 'JetBlue Airways'), SourceCityIs(city: 'Aberdeen').",
    "Use list syntax for multiple filter values: SourceCityIs(city: ['Aberdeen', 'Abilene']).",
    "Order results using 'order:', e.g., order: [NumFlights() desc].",
    "Use -1 for no limit.",
    "To find airlines from a specific airport, query dimensions=[AirlineName()] with filter SourceAirportCodeIs(...).",
    "To find airports without flights, query the separate AirportWithoutFlights() predicate.",
    "To find airlines flying from A and B, or A but not B, requires combining results from multiple queries.",
    "To find airlines with >N flights, group by airline and use 'having': query: [AirlineName(), NumFlights()], having: [NumFlights() > N]."
  ]
);

AirlinesData(uid:, airline:, abbreviation:, country:) :-
  airlines(uid:, airline:, abbreviation:, country:);

AirportsData(city:, airport_code:, airport_name:, country:, country_abbrev:) :-
  airports(city:, airport_code:, airport_name:, country:, country_abbrev:);

FlightsData(airline_id:, flight_no:, source_airport:, dest_airport:) :-
  flights(airline: airline_id, flightno: flight_no, sourceairport: source_airport, destairport: dest_airport);

FactDataPre(
    flight_airline_id:, flight_no:,
    airline_name:, airline_abbreviation:, airline_country:,
    source_airport_code:, source_airport_name:, source_city:, source_country:,
    dest_airport_code:, dest_airport_name:, dest_city:, dest_country:
  ) :-
  FlightsData(airline_id: flight_airline_id, flight_no:, source_airport: source_airport_code, dest_airport: dest_airport_code),
  AirlinesData(uid: flight_airline_id, airline: airline_name, abbreviation: airline_abbreviation, country: airline_country),
  AirportsData(city: source_city, airport_code: source_airport_code, airport_name: source_airport_name, country: source_country),
  AirportsData(city: dest_city, airport_code: dest_airport_code, airport_name: dest_airport_name, country: dest_country);

FactTable(r) :- FactDataPre(..r);

AirlineId(fact) = fact.flight_airline_id;
AirlineName(fact) = fact.airline_name;
AirlineAbbreviation(fact) = fact.airline_abbreviation;
AirlineCountry(fact) = fact.airline_country;
SourceAirportCode(fact) = fact.source_airport_code;
SourceAirportName(fact) = fact.source_airport_name;
SourceCity(fact) = fact.source_city;
SourceCountry(fact) = fact.source_country;
DestAirportCode(fact) = fact.dest_airport_code;
DestAirportName(fact) = fact.dest_airport_name;
DestCity(fact) = fact.dest_city;
DestCountry(fact) = fact.dest_country;
FlightNumber(fact) = fact.flight_no;

NumFlights(fact) = Sum(1);
NumDistinctAirlines(fact) = Count(fact.flight_airline_id);
NumDistinctSourceAirports(fact) = Count(fact.source_airport_code);
NumDistinctDestAirports(fact) = Count(fact.dest_airport_code);

TotalNumAirlines() = Count(uid) :- AirlinesData(uid:);
TotalNumAirports() = Count(airport_code) :- AirportsData(airport_code:);
TotalNumFlights() = Count(1) :- FlightsData();

AirlineNameIs(fact, name:) :- fact.airline_name == name;
AirlineAbbreviationIs(fact, abbr:) :- fact.airline_abbreviation == abbr;
AirlineCountryIs(fact, country:) :- fact.airline_country == country;
SourceAirportCodeIs(fact, code:) :- fact.source_airport_code == code;
SourceAirportNameIs(fact, name:) :- fact.source_airport_name == name;
SourceCityIs(fact, city:) :- fact.source_city in city;
SourceCountryIs(fact, country:) :- fact.source_country == country;
DestAirportCodeIs(fact, code:) :- fact.dest_airport_code == code;
DestAirportNameIs(fact, name:) :- fact.dest_airport_name == name;
DestCityIs(fact, city:) :- fact.dest_city in city;
DestCountryIs(fact, country:) :- fact.dest_country == country;

AirportHasFlights(code) :- FlightsData(source_airport: code);
AirportHasFlights(code) :- FlightsData(dest_airport: code);

AirportWithoutFlights(airport_code:, airport_name:, city:, country:) :-
  AirportsData(airport_code:, airport_name:, city:, country:),
  ~AirportHasFlights(airport_code);