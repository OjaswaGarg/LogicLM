@Engine("duckdb");

LogicLM(
  name: "Naval Battle Analysis",
  title: "Analysis of Battles, Ships, and Consequences",
  tagline: "<i>Explore historical naval engagements and their outcomes.</i>",
  port: 8090,
  fact_tables: ["Battle", "Ship", "Death"],
  default_fact_table: "Battle",

  dimensions: [
    "BattleId", "BattleName", "BattleDate", "BulgarianCommander", "LatinCommander", "BattleResult",
    "ShipId", "ShipName", "ShipTonnage", "ShipType", "ShipLocation", "ShipDisposition", "LostInBattleId",
    "DeathId", "DeathNote", "DeathKilled", "DeathInjured", "CausedByShipId"
  ],

  measures: [
    "NumBattles", "NumDistinctBattleResults",
    "NumShips",
    "NumDeathIncidents", "MaxKilledPerIncident", "MinKilledPerIncident", "AvgInjuredPerIncident",
    "SumKilled", "SumInjured"
  ],

  filters: [
     "BattleResultIs",
     "BulgarianCommanderIs", "BulgarianCommanderIsNot", "LatinCommanderIs",
     "ShipDispositionIs", "ShipTonnageIs", "ShipTypeIs", "ShipLocationIs", "ShipNameIs",
     "DeathNoteContains", "KilledGreaterThan", "InjuredGreaterThan"
  ],

   suffix_lines: [
    "Default chart type is Table().",
    "Specify dimensions, measures, filters as predicates: [BattleName(), SumKilled()].",
    "Provide arguments for filters: ShipTonnageIs(value: '225'), DeathNoteContains(value: 'East').",
    "Use 'order:' for sorting: order: [BattleDate() asc].",
    "Use 'limit:' to restrict rows: limit: 10.",
    "Use 'having:' for post-aggregation filters on measures, e.g., having: [SumKilled() > 10].",
    "Joins between Battle, Ship, and Death are handled based on context. E.g., requesting BattleName and SumKilled implies joining Battle -> Ship -> Death via appropriate keys.",
    "To count captured ships, use query: [NumShips()], filters: [ShipDispositionIs(value: 'Captured')].",
    "To find ships causing deaths with specific tonnage, query Ship dimensions/measures with filter TonnageIs(value: 't') and Death dimensions/measures.",
    "To find battles losing a specific ship type, query Battle dimensions with filter ShipTypeIs(value: 'Brig').",
    "To find battles losing specific ships (e.g., 'Lettice' AND 'HMS Atalanta'), query Battle dimensions with multiple ShipNameIs filters: [ShipNameIs(value: 'Lettice'), ShipNameIs(value: 'HMS Atalanta')]. The tool should interpret this as needing both ships linked to the same battle."
  ]
);

Battle(id:, name:, date:, bulgarian_commander:, latin_commander:, result:) :-
  battle(id:, name:, date:, bulgarian_commander:, latin_commander:, result:);

Ship(lost_in_battle:, id:, name:, tonnage:, ship_type:, location:, disposition_of_ship:) :-
  ship(lost_in_battle:, id:, name:, tonnage:, ship_type:, location:, disposition_of_ship:);

Death(caused_by_ship_id:, id:, note:, killed:, injured:) :-
  death(caused_by_ship_id:, id:, note:, killed:, injured:);


BattleId(fact) = fact.id;
BattleName(fact) = fact.name;
BattleDate(fact) = fact.date;
BulgarianCommander(fact) = fact.bulgarian_commander;
LatinCommander(fact) = fact.latin_commander;
BattleResult(fact) = fact.result;

ShipId(fact) = fact.id;
ShipName(fact) = fact.name;
ShipTonnage(fact) = fact.tonnage;
ShipType(fact) = fact.ship_type;
ShipLocation(fact) = fact.location;
ShipDisposition(fact) = fact.disposition_of_ship;
LostInBattleId(fact) = fact.lost_in_battle;

DeathId(fact) = fact.id;
DeathNote(fact) = fact.note;
DeathKilled(fact) = fact.killed;
DeathInjured(fact) = fact.injured;
CausedByShipId(fact) = fact.caused_by_ship_id;


NumBattles(fact) = Count(BattleId(fact));
NumDistinctBattleResults(fact) = Count(BattleResult(fact));
NumShips(fact) = Count(ShipId(fact));
NumDeathIncidents(fact) = Count(DeathId(fact));

MaxKilledPerIncident(fact) = Max(DeathKilled(fact));
MinKilledPerIncident(fact) = Min(DeathKilled(fact));
AvgInjuredPerIncident(fact) = Avg(DeathInjured(fact));

SumKilled(fact) = Sum(DeathKilled(fact));
SumInjured(fact) = Sum(DeathInjured(fact));


BattleResultIs(fact, value:) :- BattleResult(fact) == value;
BulgarianCommanderIs(fact, value:) :- BulgarianCommander(fact) == value;
BulgarianCommanderIsNot(fact, value:) :- BulgarianCommander(fact) != value;
LatinCommanderIs(fact, value:) :- LatinCommander(fact) == value;
ShipDispositionIs(fact, value:) :- ShipDisposition(fact) == value;
ShipTonnageIs(fact, value:) :- ShipTonnage(fact) == value;
ShipTypeIs(fact, value:) :- ShipType(fact) == value;
ShipLocationIs(fact, value:) :- ShipLocation(fact) == value;
ShipNameIs(fact, value:) :- ShipName(fact) == value;
DeathNoteContains(fact, value:) :- Contains(DeathNote(fact), value);
KilledGreaterThan(fact, value:) :- DeathKilled(fact) > value;
InjuredGreaterThan(fact, value:) :- DeathInjured(fact) > value;