@Engine("sqlite");

LogicLM(
  name: "TV Data Analysis",
  title: "TV Channels, Series, and Cartoons",
  tagline: "<i>Explore TV programming data.</i>",
  port: 8090,
  fact_tables: ["CartoonInfo", "SeriesInfo", "ChannelInfo"],
  default_fact_table: "CartoonInfo",

  dimensions: [
    "CartoonId", "CartoonTitle", "CartoonDirectedBy", "CartoonWrittenBy",
    "CartoonOriginalAirDate", "CartoonProductionCode",
    "SeriesId", "SeriesEpisode", "SeriesAirDate", "SeriesRating", "SeriesShare",
    "Series1849RatingShare", "SeriesViewersM", "SeriesWeeklyRank",
    "ChannelId", "ChannelSeriesName", "ChannelCountry", "ChannelLanguage",
    "ChannelContent", "ChannelPAR", "ChannelHDTV", "ChannelPPV", "ChannelPackageOption"
  ],

  measures: [
    "NumCartoons", "NumSeriesEpisodes", "NumChannels",
    "NumChannelsPerCountry", "NumChannelsPerLanguage", "NumCartoonsPerDirector",
    "MinSeriesShare", "MaxSeriesShare", "CountDistinctSeriesNames", "CountDistinctChannelContents"
  ],

  filters: [
     "CartoonTitleIs", "CartoonDirectedByIs", "CartoonWrittenByIs",
     "SeriesEpisodeIs", "ChannelSeriesNameIs", "ChannelCountryIs", "ChannelLanguageIs",
     "ChannelIsHDTV", "ChannelIsNotHDTV",
     "ChannelPlaysCartoonDirectedBy", "ChannelDoesNotPlayCartoonDirectedBy",
     "ChannelPlaysCartoonWrittenBy", "ChannelDoesNotPlayCartoonWrittenBy",
     "CountryHasCartoonWrittenBy", "CountryDoesNotHaveCartoonWrittenBy"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Dimensions, Measures, and Filters should be predicate calls, e.g., [CartoonTitle(), NumCartoonsPerDirector()].",
    "For filters, provide arguments, e.g., CartoonDirectedByIs(directors: ['Ben Jones']), ChannelCountryIs(countries: ['USA', 'Japan']).",
    "Use list syntax for multiple filter values.",
    "Order results using 'order:', e.g., order: [CartoonTitle() asc].",
    "Use -1 for no limit.",
    "Note: Series Rating and Viewers (M) are stored as TEXT; sorting/filtering might be alphabetical. Share and Rank are REAL.",
    "Note: Air Dates are stored as TEXT.",
    "To find the channel for a specific cartoon, use CartoonInfo fact table and filter: query: [ChannelSeriesName()], filters: [CartoonTitleIs(titles: ['The Rise of the Blue Beetle!'])], limit: 1.",
     "To find cartoons/episodes for a specific channel, use CartoonInfo/SeriesInfo fact table and filter: query: [CartoonTitle()], filters: [ChannelSeriesNameIs(names: ['Sky Radio'])]."
  ]
);

TvChannelT(id:, series_name:, country:, language:, content:, pixel_aspect_ratio_par:, hight_definition_tv:, pay_per_view_ppv:, package_option:) :-
  tv_channel(id:, series_name:, country:, language:, content:, pixel_aspect_ratio_par:, hight_definition_tv:, pay_per_view_ppv:, package_option:);

TvSeriesT(id:, episode:, air_date:, rating:, share:, rating_share_18_49: "18_49_rating_share", viewers_m:, weekly_rank:, channel:) :-
  tv_series(id:, episode:, air_date:, rating:, share:, "18_49_rating_share":, viewers_m:, weekly_rank:, channel:);

CartoonT(id:, title:, directed_by:, written_by:, original_air_date:, production_code:, channel:) :-
  cartoon(id:, title:, directed_by:, written_by:, original_air_date:, production_code:, channel:);


CartoonInfoT(
    cartoon_id: cid, cartoon_title: title, cartoon_directed_by: directed_by,
    cartoon_written_by: written_by, cartoon_original_air_date: original_air_date,
    cartoon_production_code: production_code, cartoon_channel_id: cchnl,
    channel_id: chid, channel_series_name: series_name, channel_country: country,
    channel_language: language, channel_content: content, channel_par: par,
    channel_hdtv: hdtv, channel_ppv: ppv, channel_package_option: pkg
  ) :-
  CartoonT(id: cid, title:, directed_by:, written_by:, original_air_date:, production_code:, channel: cchnl),
  TvChannelT(id: chid, series_name:, country:, language:, content:, pixel_aspect_ratio_par: par, hight_definition_tv: hdtv, pay_per_view_ppv: ppv, package_option: pkg),
  chid == cchnl;

SeriesInfoT(
    series_id: sid, series_episode: episode, series_air_date: air_date, series_rating: rating,
    series_share: share, series_1849_rating_share: rating_share_18_49, series_viewers_m: viewers_m,
    series_weekly_rank: weekly_rank, series_channel_id: schnl,
    channel_id: chid, channel_series_name: series_name, channel_country: country,
    channel_language: language, channel_content: content, channel_par: par,
    channel_hdtv: hdtv, channel_ppv: ppv, channel_package_option: pkg
  ) :-
  TvSeriesT(id: sid, episode:, air_date:, rating:, share:, rating_share_18_49:, viewers_m:, weekly_rank:, channel: schnl),
  TvChannelT(id: chid, series_name:, country:, language:, content:, pixel_aspect_ratio_par: par, hight_definition_tv: hdtv, pay_per_view_ppv: ppv, package_option: pkg),
  chid == schnl;

ChannelInfoT(
    channel_id: id, channel_series_name: series_name, channel_country: country,
    channel_language: language, channel_content: content, channel_par: par,
    channel_hdtv: hdtv, channel_ppv: ppv, channel_package_option: pkg
    ) :-
    TvChannelT(id:, series_name:, country:, language:, content:, pixel_aspect_ratio_par: par, hight_definition_tv: hdtv, pay_per_view_ppv: ppv, package_option: pkg);


CartoonInfo(r) :- CartoonInfoT(..r);
SeriesInfo(r) :- SeriesInfoT(..r);
ChannelInfo(r) :- ChannelInfoT(..r);


CartoonId(fact) = fact.cartoon_id;
CartoonTitle(fact) = fact.cartoon_title;
CartoonDirectedBy(fact) = fact.cartoon_directed_by;
CartoonWrittenBy(fact) = fact.cartoon_written_by;
CartoonOriginalAirDate(fact) = fact.cartoon_original_air_date;
CartoonProductionCode(fact) = fact.cartoon_production_code;

SeriesId(fact) = fact.series_id;
SeriesEpisode(fact) = fact.series_episode;
SeriesAirDate(fact) = fact.series_air_date;
SeriesRating(fact) = fact.series_rating;
SeriesShare(fact) = fact.series_share;
Series1849RatingShare(fact) = fact.series_1849_rating_share;
SeriesViewersM(fact) = fact.series_viewers_m;
SeriesWeeklyRank(fact) = fact.series_weekly_rank;

ChannelId(fact) = fact.channel_id;
ChannelSeriesName(fact) = fact.channel_series_name;
ChannelCountry(fact) = fact.channel_country;
ChannelLanguage(fact) = fact.channel_language;
ChannelContent(fact) = fact.channel_content;
ChannelPAR(fact) = fact.channel_par;
ChannelHDTV(fact) = fact.channel_hdtv;
ChannelPPV(fact) = fact.channel_ppv;
ChannelPackageOption(fact) = fact.channel_package_option;


NumCartoons(fact) = Sum(1);
NumSeriesEpisodes(fact) = Sum(1);
NumChannels(fact) = Sum(1);
NumChannelsPerCountry(fact) = Sum(1);
NumChannelsPerLanguage(fact) = Sum(1);
NumCartoonsPerDirector(fact) = Sum(1);
MinSeriesShare(fact) = Min(fact.series_share);
MaxSeriesShare(fact) = Max(fact.series_share);
CountDistinctSeriesNames(fact) = Count(fact.channel_series_name);
CountDistinctChannelContents(fact) = Count(fact.channel_content);


CartoonTitleIs(fact, titles:) :- Constraint(CartoonTitle(fact) in titles);
CartoonDirectedByIs(fact, directors:) :- Constraint(CartoonDirectedBy(fact) in directors);
CartoonWrittenByIs(fact, writers:) :- Constraint(CartoonWrittenBy(fact) in writers);
SeriesEpisodeIs(fact, episodes:) :- Constraint(SeriesEpisode(fact) in episodes);
ChannelSeriesNameIs(fact, names:) :- Constraint(ChannelSeriesName(fact) in names);
ChannelCountryIs(fact, countries:) :- Constraint(ChannelCountry(fact) in countries);
ChannelLanguageIs(fact, languages:) :- Constraint(ChannelLanguage(fact) in languages);
ChannelIsHDTV(fact) :- fact.channel_hdtv != 'No';
ChannelIsNotHDTV(fact) :- fact.channel_hdtv == 'No';


ChannelPlaysCartoonDirectedBy(fact, directors:) :-
  CartoonInfoT(channel_id: fact.channel_id, cartoon_directed_by: director),
  Constraint(director in directors);
ChannelDoesNotPlayCartoonDirectedBy(fact, directors:) :-
  fact_table == "ChannelInfo",
  ~ChannelPlaysCartoonDirectedBy(fact, directors: directors);


ChannelPlaysCartoonWrittenBy(fact, writers:) :-
  CartoonInfoT(channel_id: fact.channel_id, cartoon_written_by: writer),
  Constraint(writer in writers);
ChannelDoesNotPlayCartoonWrittenBy(fact, writers:) :-
  fact_table == "ChannelInfo",
  ~ChannelPlaysCartoonWrittenBy(fact, writers: writers);


CountryHasCartoonWrittenBy(fact, writers:) :-
  fact_table == "ChannelInfo",
  ChannelPlaysCartoonWrittenBy(fact, writers: writers);

CountryDoesNotHaveCartoonWrittenBy(fact, writers:) :-
  fact_table == "ChannelInfo",
  ~ChannelPlaysCartoonWrittenBy(fact, writers: writers);