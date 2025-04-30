
@Engine("duckdb");

GetValueOrDefault(value, default_value) = value :- value is not null;
GetValueOrDefault(value, default_value) = default_value :- value is null;

CalculateBA(h, ab) = SafeDiv(ToFloat(h), ToFloat(ab)) :- ab > 0;
CalculateBA(h, ab) = 0.0 :- ab == 0 or ab is null;

CalculateSLG(h, dbl, tpl, hr, ab) = SafeDiv(ToFloat(h + dbl + 2 * tpl + 3 * hr), ToFloat(ab)) :- ab > 0;
CalculateSLG(h, dbl, tpl, hr, ab) = 0.0 :- ab == 0 or ab is null;

CalculateOBP(h, bb, hbp, ab, sf) = SafeDiv(ToFloat(h + bb + hbp), ToFloat(ab + bb + hbp + sf)) :- (ab + bb + hbp + sf) > 0;
CalculateOBP(h, bb, hbp, ab, sf) = 0.0 :- (ab + bb + hbp + sf) == 0 or (ab + bb + hbp + sf) is null;

CalculateERA(er, ipouts) = SafeDiv(ToFloat(er * 27), ToFloat(ipouts)) :- ipouts > 0;
CalculateERA(er, ipouts) = null :- ipouts == 0 or ipouts is null;

CalculateWHIP(bb, h, ipouts) = SafeDiv(ToFloat(bb + h) * 3, ToFloat(ipouts)) :- ipouts > 0;
CalculateWHIP(bb, h, ipouts) = null :- ipouts == 0 or ipouts is null;

CalculateFPCT(po, a, e) = SafeDiv(ToFloat(po + a), ToFloat(po + a + e)) :- (po + a + e) > 0;
CalculateFPCT(po, a, e) = null :- (po + a + e) == 0 or (po + a + e) is null;


LogicLM(
  name: "Baseball Stats Analysis",
  title: "Historical Baseball Player/Team Data Exploration",
  tagline: "<i>Analyze player stats, team performance, awards, and more across years.</i>",
  port: 8089,
  fact_tables: ["PlayerSeason"],
  default_fact_table: "PlayerSeason",

  dimensions: [
    "PlayerId", "PlayerFullName", "BirthYear", "BirthCountry", "Bats", "Throws",
    "TeamId", "TeamName", "LeagueId", "Year", "Stint"
  ],

  measures: [
    "NumPlayers", "NumPlayerSeasons",
    "TotalGames", "TotalGamesStarted", "TotalAB", "TotalR", "TotalH", "Total2B", "Total3B", "TotalHR", "TotalRBI",
    "TotalSB", "TotalBB", "TotalSO", "TotalIBB", "TotalHBP",
    "AvgBA", "AvgOBP", "AvgSLG",
    "TotalPitchingW", "TotalPitchingL", "TotalPitchingG", "TotalPitchingGS", "TotalPitchingCG", "TotalPitchingSHO", "TotalPitchingSV",
    "TotalPitchingIPouts", "TotalPitchingH", "TotalPitchingER", "TotalPitchingHR", "TotalPitchingBB", "TotalPitchingSO",
    "AvgERA", "AvgWHIP",
    "TotalFieldingPO", "TotalFieldingA", "TotalFieldingE", "TotalFieldingDP",
    "AvgFPCT",
    "TotalSalary"
  ],

  filters: [
     "PlayerIs", "TeamIs", "LeagueIs", "YearIs", "YearBetween", "YearAfter", "YearBefore",
     "BatsIs", "ThrowsIs", "BirthCountryIs",
     "GamesPlayedMoreThan", "GamesPlayedLessThan",
     "AtBatsMoreThan", "HitsMoreThan", "HomeRunsMoreThan", "RbiMoreThan",
     "StrikeoutsMoreThan", "StrikeoutsLessThan",
     "WinsMoreThan", "LossesMoreThan", "SavesMoreThan",
     "EraLessThan", "EraMoreThan",
     "SalaryMoreThan", "SalaryLessThan"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Dimensions, Measures, and Filters should be predicate calls, e.g., [PlayerFullName(), TotalHR()].",
    "For filters, provide arguments, e.g., YearIs(year: 1998), HomeRunsMoreThan(hr: 30).",
    "Use list syntax for multiple filter values: LeagueIs(league_ids: ['AL', 'NL']).",
    "Order results using 'order:', e.g., order: [AvgBA() desc].",
    "Use -1 for limit to get all results.",
    "ERA and WHIP may be null if Innings Pitched (IPouts) is zero.",
    "BA, OBP, SLG are 0.0 if Plate Appearances / At Bats are zero.",
    "Salary data may not be available for all players/years."
  ]
);


@With(PlayerSeasonT);
PlayerSeasonT(
    player_id:, year:, stint:,
    name_first:, name_last:, birth_year:, birth_country:, bats:, throws:,
    team_id:, league_id:, team_name:,
    g_all:, gs:, g_batting:,
    batting_g:, batting_ab:, batting_r:, batting_h:, batting_double:, batting_triple:, batting_hr:, batting_rbi:,
    batting_sb:, batting_cs:, batting_bb:, batting_so:, batting_ibb:, batting_hbp:, batting_sh:, batting_sf:, batting_gidp:,
    pitching_w:, pitching_l:, pitching_g:, pitching_gs:, pitching_cg:, pitching_sho:, pitching_sv:,
    pitching_ipouts:, pitching_h:, pitching_er:, pitching_hr:, pitching_bb:, pitching_so:,
    pitching_baopp:, pitching_era:, pitching_ibb:, pitching_wp:, pitching_hbp:, pitching_bk:, pitching_bfp:, pitching_gf:, pitching_r:,
    fielding_pos:, fielding_g:, fielding_gs:, fielding_po:, fielding_a:, fielding_e:, fielding_dp:,
    salary:
  ) :-
  player(player_id:, name_first:, name_last:, birth_year:, birth_country:, bats:, throws:),
  appearances(player_id:, year:, team_id:, league_id:, g_all:, gs:, g_batting:, stint:),
  team(team_id:, year:, league_id:, name: team_name),
  MaybeBatting(player_id:, year:, stint:,
               g: batting_g, ab: batting_ab, r: batting_r, h: batting_h, double: batting_double, triple: batting_triple, hr: batting_hr, rbi: batting_rbi,
               sb: batting_sb, cs: batting_cs, bb: batting_bb, so: batting_so, ibb: batting_ibb, hbp: batting_hbp, sh: batting_sh, sf: batting_sf, g_idp: batting_gidp),
  MaybePitching(player_id:, year:, stint:,
                w: pitching_w, l: pitching_l, g: pitching_g, gs: pitching_gs, cg: pitching_cg, sho: pitching_sho, sv: pitching_sv,
                ipouts: pitching_ipouts, h: pitching_h, er: pitching_er, hr: pitching_hr, bb: pitching_bb, so: pitching_so,
                baopp: pitching_baopp, era: pitching_era, ibb: pitching_ibb, wp: pitching_wp, hbp: pitching_hbp, bk: pitching_bk, bfp: pitching_bfp, gf: pitching_gf, r: pitching_r),
  MaybeFielding(player_id:, year:, stint:,
                pos: fielding_pos, g: fielding_g, gs: fielding_gs, po: fielding_po, a: fielding_a, e: fielding_e, dp: fielding_dp),
  MaybeSalary(player_id:, year:, team_id:, league_id:, salary: salary);


MaybeBatting(player_id:, year:, stint:, g:, ab:, r:, h:, double:, triple:, hr:, rbi:, sb:, cs:, bb:, so:, ibb:, hbp:, sh:, sf:, g_idp:) distinct :-
  batting(player_id:, year:, stint:, g:, ab:, r:, h:, double:, triple:, hr:, rbi:, sb:, cs:, bb:, so:, ibb:, hbp:, sh:, sf:, g_idp:);
MaybeBatting(player_id:, year:, stint:, g: null, ab: null, r: null, h: null, double: null, triple: null, hr: null, rbi: null, sb: null, cs: null, bb: null, so: null, ibb: null, hbp: null, sh: null, sf: null, g_idp: null) distinct :-
  appearances(player_id:, year:, stint:),
  ~batting(player_id:, year:, stint:);


MaybePitching(player_id:, year:, stint:, w:, l:, g:, gs:, cg:, sho:, sv:, ipouts:, h:, er:, hr:, bb:, so:, baopp:, era:, ibb:, wp:, hbp:, bk:, bfp:, gf:, r:) distinct :-
  pitching(player_id:, year:, stint:, w:, l:, g:, gs:, cg:, sho:, sv:, ipouts:, h:, er:, hr:, bb:, so:, baopp:, era:, ibb:, wp:, hbp:, bk:, bfp:, gf:, r:);
MaybePitching(player_id:, year:, stint:, w: null, l: null, g: null, gs: null, cg: null, sho: null, sv: null, ipouts: null, h: null, er: null, hr: null, bb: null, so: null, baopp: null, era: null, ibb: null, wp: null, hbp: null, bk: null, bfp: null, gf: null, r: null) distinct :-
  appearances(player_id:, year:, stint:),
  ~pitching(player_id:, year:, stint:);


MaybeFielding(player_id:, year:, stint:, pos:, g:, gs:, po:, a:, e:, dp:) distinct :-
  fielding(player_id:, year:, stint:, pos:, g:, gs:, po:, a:, e:, dp:);
MaybeFielding(player_id:, year:, stint:, pos: null, g: null, gs: null, po: null, a: null, e: null, dp: null) distinct :-
  appearances(player_id:, year:, stint:),
  ~fielding(player_id:, year:, stint:);


MaybeSalary(player_id:, year:, team_id:, league_id:, salary:) distinct :-
  salary(player_id:, year:, team_id:, league_id:, salary:);
MaybeSalary(player_id:, year:, team_id:, league_id:, salary: null) distinct :-
  appearances(player_id:, year:, team_id:, league_id:),
  ~salary(player_id:, year:, team_id:, league_id:);


PlayerSeason(r) :- PlayerSeasonT(..r);

PlayerId(fact) = fact.player_id;
PlayerFullName(fact) = fact.name_first ++ " " ++ fact.name_last;
BirthYear(fact) = fact.birth_year;
BirthCountry(fact) = fact.birth_country;
Bats(fact) = fact.bats;
Throws(fact) = fact.throws;
TeamId(fact) = fact.team_id;
TeamName(fact) = fact.team_name;
LeagueId(fact) = fact.league_id;
Year(fact) = fact.year;
Stint(fact) = fact.stint;

NumPlayers(fact) = Count(fact.player_id);
NumPlayerSeasons(fact) = Sum(1);
TotalGames(fact) = Sum(GetValueOrDefault(fact.g_all, 0));
TotalGamesStarted(fact) = Sum(GetValueOrDefault(fact.gs, 0));
TotalAB(fact) = Sum(GetValueOrDefault(fact.batting_ab, 0));
TotalR(fact) = Sum(GetValueOrDefault(fact.batting_r, 0));
TotalH(fact) = Sum(GetValueOrDefault(fact.batting_h, 0));
Total2B(fact) = Sum(GetValueOrDefault(fact.batting_double, 0));
Total3B(fact) = Sum(GetValueOrDefault(fact.batting_triple, 0));
TotalHR(fact) = Sum(GetValueOrDefault(fact.batting_hr, 0));
TotalRBI(fact) = Sum(GetValueOrDefault(fact.batting_rbi, 0));
TotalSB(fact) = Sum(GetValueOrDefault(fact.batting_sb, 0));
TotalBB(fact) = Sum(GetValueOrDefault(fact.batting_bb, 0));
TotalSO(fact) = Sum(GetValueOrDefault(fact.batting_so, 0));
TotalIBB(fact) = Sum(GetValueOrDefault(fact.batting_ibb, 0));
TotalHBP(fact) = Sum(GetValueOrDefault(fact.batting_hbp, 0));

AvgBA(fact) = CalculateBA(Sum(GetValueOrDefault(fact.batting_h, 0)), Sum(GetValueOrDefault(fact.batting_ab, 0)));
AvgOBP(fact) = CalculateOBP(Sum(GetValueOrDefault(fact.batting_h, 0)), Sum(GetValueOrDefault(fact.batting_bb, 0)), Sum(GetValueOrDefault(fact.batting_hbp, 0)), Sum(GetValueOrDefault(fact.batting_ab, 0)), Sum(GetValueOrDefault(fact.batting_sf, 0)));
AvgSLG(fact) = CalculateSLG(Sum(GetValueOrDefault(fact.batting_h, 0)), Sum(GetValueOrDefault(fact.batting_double, 0)), Sum(GetValueOrDefault(fact.batting_triple, 0)), Sum(GetValueOrDefault(fact.batting_hr, 0)), Sum(GetValueOrDefault(fact.batting_ab, 0)));

TotalPitchingW(fact) = Sum(GetValueOrDefault(fact.pitching_w, 0));
TotalPitchingL(fact) = Sum(GetValueOrDefault(fact.pitching_l, 0));
TotalPitchingG(fact) = Sum(GetValueOrDefault(fact.pitching_g, 0));
TotalPitchingGS(fact) = Sum(GetValueOrDefault(fact.pitching_gs, 0));
TotalPitchingCG(fact) = Sum(GetValueOrDefault(fact.pitching_cg, 0));
TotalPitchingSHO(fact) = Sum(GetValueOrDefault(fact.pitching_sho, 0));
TotalPitchingSV(fact) = Sum(GetValueOrDefault(fact.pitching_sv, 0));
TotalPitchingIPouts(fact) = Sum(GetValueOrDefault(fact.pitching_ipouts, 0));
TotalPitchingH(fact) = Sum(GetValueOrDefault(fact.pitching_h, 0));
TotalPitchingER(fact) = Sum(GetValueOrDefault(fact.pitching_er, 0));
TotalPitchingHR(fact) = Sum(GetValueOrDefault(fact.pitching_hr, 0));
TotalPitchingBB(fact) = Sum(GetValueOrDefault(fact.pitching_bb, 0));
TotalPitchingSO(fact) = Sum(GetValueOrDefault(fact.pitching_so, 0));

AvgERA(fact) = CalculateERA(Sum(GetValueOrDefault(fact.pitching_er, 0)), Sum(GetValueOrDefault(fact.pitching_ipouts, 0)));
AvgWHIP(fact) = CalculateWHIP(Sum(GetValueOrDefault(fact.pitching_bb, 0)), Sum(GetValueOrDefault(fact.pitching_h, 0)), Sum(GetValueOrDefault(fact.pitching_ipouts, 0)));

TotalFieldingPO(fact) = Sum(GetValueOrDefault(fact.fielding_po, 0));
TotalFieldingA(fact) = Sum(GetValueOrDefault(fact.fielding_a, 0));
TotalFieldingE(fact) = Sum(GetValueOrDefault(fact.fielding_e, 0));
TotalFieldingDP(fact) = Sum(GetValueOrDefault(fact.fielding_dp, 0));

AvgFPCT(fact) = CalculateFPCT(Sum(GetValueOrDefault(fact.fielding_po, 0)), Sum(GetValueOrDefault(fact.fielding_a, 0)), Sum(GetValueOrDefault(fact.fielding_e, 0)));

TotalSalary(fact) = Sum(GetValueOrDefault(fact.salary, 0));

PlayerIs(fact, player_ids:) :- Constraint(PlayerId(fact) in player_ids);
TeamIs(fact, team_ids:) :- Constraint(TeamId(fact) in team_ids);
LeagueIs(fact, league_ids:) :- Constraint(LeagueId(fact) in league_ids);
YearIs(fact, years:) :- Constraint(Year(fact) in years);
YearBetween(fact, min_year:, max_year:) :- Year(fact) >= min_year, Year(fact) <= max_year;
YearAfter(fact, year_val:) :- Year(fact) > year_val;
YearBefore(fact, year_val:) :- Year(fact) < year_val;
BatsIs(fact, bats_codes:) :- Constraint(Bats(fact) in bats_codes);
ThrowsIs(fact, throws_codes:) :- Constraint(Throws(fact) in throws_codes);
BirthCountryIs(fact, countries:) :- Constraint(BirthCountry(fact) in countries);

GamesPlayedMoreThan(fact, g_val:) :- GetValueOrDefault(fact.g_all, 0) > g_val;
GamesPlayedLessThan(fact, g_val:) :- GetValueOrDefault(fact.g_all, 0) < g_val;
AtBatsMoreThan(fact, ab_val:) :- GetValueOrDefault(fact.batting_ab, 0) > ab_val;
HitsMoreThan(fact, h_val:) :- GetValueOrDefault(fact.batting_h, 0) > h_val;
HomeRunsMoreThan(fact, hr_val:) :- GetValueOrDefault(fact.batting_hr, 0) > hr_val;
RbiMoreThan(fact, rbi_val:) :- GetValueOrDefault(fact.batting_rbi, 0) > rbi_val;
StrikeoutsMoreThan(fact, so_val:) :- GetValueOrDefault(fact.batting_so, 0) > so_val;
StrikeoutsLessThan(fact, so_val:) :- GetValueOrDefault(fact.batting_so, 0) < so_val;

WinsMoreThan(fact, w_val:) :- GetValueOrDefault(fact.pitching_w, 0) > w_val;
LossesMoreThan(fact, l_val:) :- GetValueOrDefault(fact.pitching_l, 0) > l_val;
SavesMoreThan(fact, sv_val:) :- GetValueOrDefault(fact.pitching_sv, 0) > sv_val;

EraLessThan(fact, era_val:) :- CalculateERA(fact.pitching_er, fact.pitching_ipouts) < era_val, fact.pitching_ipouts > 0;
EraMoreThan(fact, era_val:) :- CalculateERA(fact.pitching_er, fact.pitching_ipouts) > era_val, fact.pitching_ipouts > 0;

SalaryMoreThan(fact, sal_val:) :- GetValueOrDefault(fact.salary, 0) > sal_val;
SalaryLessThan(fact, sal_val:) :- GetValueOrDefault(fact.salary, 0) < sal_val;
