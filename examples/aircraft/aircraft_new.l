@Engine("duckdb");

LogicLM(
  name: "Aviation Data Explorer",
  title: "Pilot, Aircraft, Match, and Airport Analysis",
  tagline: "<i>Explore relationships between pilots, aircraft, matches, and airports.</i>",
  port: 8089,
  fact_tables: ["Pilot", "Aircraft", "Match", "Airport", "AirportAircraft"],
  default_fact_table: "Match",

  dimensions: [
    "PilotId", "PilotName", "PilotAge",
    "AircraftId", "AircraftName", "AircraftDescription", "AircraftMaxGrossWeight", "AircraftTotalDiskArea", "AircraftMaxDiskLoading",
    "MatchRound", "MatchLocation", "MatchCountry", "MatchDate", "MatchFastestQualifying", "MatchWinningPilotId", "MatchWinningAircraftId",
    "AirportId", "AirportName", "AirportTotalPassengers", "AirportPctChange2007", "AirportIntlPassengers", "AirportDomPassengers", "AirportTransitPassengers", "AirportAircraftMovements", "AirportFreightMetricTonnes",
    "AirportAircraftLinkId", "AirportAircraftAirportId", "AirportAircraftAircraftId"
  ],

  measures: [
    "NumRows",
    "NumPilots", "NumAircraft", "NumMatches", "NumAirports", "NumAirportAircraftLinks",
    "AvgPilotAge", "MinPilotAge", "MaxPilotAge",
    "AvgAirportTotalPassengers", "SumAirportTotalPassengers", "MinAirportTotalPassengers", "MaxAirportTotalPassengers",
    "AvgAirportIntlPassengers", "SumAirportIntlPassengers",
    "AvgAirportDomPassengers", "SumAirportDomPassengers",
    "AvgAirportTransitPassengers", "SumAirportTransitPassengers",
    "AvgAirportAircraftMovements", "SumAirportAircraftMovements",
    "AvgAirportFreight", "SumAirportFreight"
  ],

  filters: [
     "PilotIdIs", "PilotNameIs", "PilotAgeIs", "PilotAgeGreaterThan", "PilotAgeLessThan",
     "AircraftIdIs", "AircraftNameIs", "AircraftDescriptionContains",
     "MatchRoundIs", "MatchLocationIs", "MatchCountryIs", "MatchDateIs", "MatchWinningPilotIdIs", "MatchWinningAircraftIdIs",
     "AirportIdIs", "AirportNameIs", "AirportTotalPassengersGreaterThan", "AirportTotalPassengersLessThan",
     "AirportAircraftMovementsGreaterThan", "AirportAircraftMovementsLessThan",
     "AirportAircraftAirportIdIs", "AirportAircraftAircraftIdIs"
  ],

  suffix_lines: [
    "Select a Fact Table (e.g., Pilot, Aircraft, Match, Airport, AirportAircraft) as the primary focus.",
    "Dimensions, Measures, and Filters are predicate calls, e.g., [PilotName(), NumRows()].",
    "Provide arguments for filters, e.g., PilotAgeGreaterThan(age: 40), AirportNameIs(names: ['Heathrow', 'JFK']).",
    "Use list syntax for multiple filter values: MatchCountryIs(country_names: ['USA', 'UK']).",
    "Order results using 'order:', e.g., order: [AvgPilotAge() desc].",
    "Use -1 for no limit.",
    "Note: Some aircraft fields (Weight, Area, Loading) and Match keys (Pilot, Aircraft) are stored as text in the source schema."
  ]
);

Pilot(pilot_id:, name:, age:) :-
  pilot(Pilot_Id: pilot_id, Name: name, Age: age);

Aircraft(aircraft_id:, aircraft_name:, description:, max_gross_weight:, total_disk_area:, max_disk_loading:) :-
  aircraft(aircraft_id: aircraft_id, aircraft: aircraft_name, description:, max_gross_weight:, total_disk_area:, max_disk_loading:);

Match(round:, location:, country:, date:, fastest_qualifying:, winning_pilot_id:, winning_aircraft_id:) :-
  match(round:, location:, country:, date:, fastest_qualifying:, winning_pilot: winning_pilot_id, winning_aircraft: winning_aircraft_id);

Airport(airport_id:, airport_name:, total_passengers:, pct_change_2007:, international_passengers:, domestic_passengers:, transit_passengers:, aircraft_movements:, freight_metric_tonnes:) :-
  airport(airport_id:, airport_name:, total_passengers:, "%_change_2007": pct_change_2007, international_passengers:, domestic_passengers:, transit_passengers:, aircraft_movements:, freight_metric_tonnes:);

AirportAircraft(link_id:, airport_id:, aircraft_id:) :-
  airport_aircraft(id: link_id, airport_id:, aircraft_id:);

PilotId(fact) = fact.pilot_id;
PilotName(fact) = fact.name;
PilotAge(fact) = fact.age;
AircraftId(fact) = fact.aircraft_id;
AircraftName(fact) = fact.aircraft_name;
AircraftDescription(fact) = fact.description;
AircraftMaxGrossWeight(fact) = fact.max_gross_weight;
AircraftTotalDiskArea(fact) = fact.total_disk_area;
AircraftMaxDiskLoading(fact) = fact.max_disk_loading;
MatchRound(fact) = fact.round;
MatchLocation(fact) = fact.location;
MatchCountry(fact) = fact.country;
MatchDate(fact) = fact.date;
MatchFastestQualifying(fact) = fact.fastest_qualifying;
MatchWinningPilotId(fact) = fact.winning_pilot_id;
MatchWinningAircraftId(fact) = fact.winning_aircraft_id;
AirportId(fact) = fact.airport_id;
AirportName(fact) = fact.airport_name;
AirportTotalPassengers(fact) = fact.total_passengers;
AirportPctChange2007(fact) = fact.pct_change_2007;
AirportIntlPassengers(fact) = fact.international_passengers;
AirportDomPassengers(fact) = fact.domestic_passengers;
AirportTransitPassengers(fact) = fact.transit_passengers;
AirportAircraftMovements(fact) = fact.aircraft_movements;
AirportFreightMetricTonnes(fact) = fact.freight_metric_tonnes;
AirportAircraftLinkId(fact) = fact.link_id;
AirportAircraftAirportId(fact) = fact.airport_id;
AirportAircraftAircraftId(fact) = fact.aircraft_id;

NumRows() = Count();
NumPilots() = Count() :- Pilot();
NumAircraft() = Count() :- Aircraft();
NumMatches() = Count() :- Match();
NumAirports() = Count() :- Airport();
NumAirportAircraftLinks() = Count() :- AirportAircraft();

AvgPilotAge() = Avg(age);
MinPilotAge() = Min(age);
MaxPilotAge() = Max(age);
AvgAirportTotalPassengers() = Avg(total_passengers);
SumAirportTotalPassengers() = Sum(total_passengers);
MinAirportTotalPassengers() = Min(total_passengers);
MaxAirportTotalPassengers() = Max(total_passengers);
AvgAirportIntlPassengers() = Avg(international_passengers);
SumAirportIntlPassengers() = Sum(international_passengers);
AvgAirportDomPassengers() = Avg(domestic_passengers);
SumAirportDomPassengers() = Sum(domestic_passengers);
AvgAirportTransitPassengers() = Avg(transit_passengers);
SumAirportTransitPassengers() = Sum(transit_passengers);
AvgAirportAircraftMovements() = Avg(aircraft_movements);
SumAirportAircraftMovements() = Sum(aircraft_movements);
AvgAirportFreight() = Avg(freight_metric_tonnes);
SumAirportFreight() = Sum(freight_metric_tonnes);

PilotIdIs(ids:) :- Constraint(pilot_id in ids);
PilotNameIs(names:) :- Constraint(name in names);
PilotAgeIs(ages:) :- Constraint(age in ages);
PilotAgeGreaterThan(age_val:) :- age > age_val;
PilotAgeLessThan(age_val:) :- age < age_val;
AircraftIdIs(ids:) :- Constraint(aircraft_id in ids);
AircraftNameIs(names:) :- Constraint(aircraft_name in names);
AircraftDescriptionContains(substr:) :- Contains(description, substr);
MatchRoundIs(rounds:) :- Constraint(round in rounds);
MatchLocationIs(locs:) :- Constraint(location in locs);
MatchCountryIs(countries:) :- Constraint(country in countries);
MatchDateIs(dates:) :- Constraint(date in dates);
MatchWinningPilotIdIs(ids:) :- Constraint(winning_pilot_id in ids);
MatchWinningAircraftIdIs(ids:) :- Constraint(winning_aircraft_id in ids);
AirportIdIs(ids:) :- Constraint(airport_id in ids);
AirportNameIs(names:) :- Constraint(airport_name in names);
AirportTotalPassengersGreaterThan(val:) :- total_passengers > val;
AirportTotalPassengersLessThan(val:) :- total_passengers < val;
AirportAircraftMovementsGreaterThan(val:) :- aircraft_movements > val;
AirportAircraftMovementsLessThan(val:) :- aircraft_movements < val;
AirportAircraftAirportIdIs(ids:) :- Constraint(airport_id in ids);
AirportAircraftAircraftIdIs(ids:) :- Constraint(aircraft_id in ids);