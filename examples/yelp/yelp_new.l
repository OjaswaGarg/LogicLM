@Engine("duckdb");

LogicLM(
  name: "Business Review Analysis",
  title: "Local Business Data Exploration",
  tagline: "<i>Analyze Ratings, Reviews, Locations, and Users</i>",
  port: 8080,
  fact_tables: ["ReviewFact"],
  default_fact_table: "ReviewFact",

  dimensions: [
    "BusinessId", "BusinessName", "City", "State", "IsOpen",
    "UserId", "UserName", "ReviewYear", "ReviewMonth"
  ],

  measures: [
    "NumReviews", "AvgReviewRating", "MinReviewRating", "MaxReviewRating",
    "NumUsersCommenting", "NumBusinessesReviewed", "AvgBusinessRatingOverall",
    "AvgBusinessReviewCount"
  ],

  filters: [
     "BusinessNameIs", "CityIs", "StateIs", "IsOpenIs", "UserNameIs",
     "ReviewYearIs", "ReviewMonthIs", "ReviewRatingIs", "ReviewRatingAbove",
     "ReviewRatingBelow", "ReviewYearBetween"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Dimensions, Measures, and Filters should be predicate calls, e.g., [City(), NumReviews()].",
    "For filters, provide arguments, e.g., ReviewYearIs(years: [2018, 2019]), CityIs(cities: 'Las Vegas').",
    "Use list syntax for multiple filter values: StateIs(states: ['NV', 'AZ']).",
    "Order results using 'order:', e.g., order: [AvgReviewRating() desc].",
    "Use -1 for no limit."
  ]
);


@AttachDatabase("logica_home", "database.db");


ReviewFactT(
    review_id:,
    business_id:,
    user_id:,
    review_rating:,
    review_text:,
    review_year:,
    review_month:,
    business_name:,
    city:,
    state:,
    business_rating:,
    business_review_count:,
    is_open:,
    user_name:
  ) :-
  review(rid: review_id, business_id:, user_id:, rating: review_rating, text: review_text, year: review_year, month: review_month),
  business(business_id:, name: business_name, city:, state:, rating: business_rating, review_count: business_review_count, is_open:),
  user(user_id:, name: user_name);

ReviewFact(r) :- ReviewFactT(..r);


BusinessId(fact) = fact.business_id;
BusinessName(fact) = fact.business_name;
City(fact) = fact.city;
State(fact) = fact.state;
IsOpen(fact) = fact.is_open;
UserId(fact) = fact.user_id;
UserName(fact) = fact.user_name;
ReviewYear(fact) = fact.review_year;
ReviewMonth(fact) = fact.review_month;


NumReviews(fact) = Sum(1);
AvgReviewRating(fact) = Avg(fact.review_rating);
MinReviewRating(fact) = Min(fact.review_rating);
MaxReviewRating(fact) = Max(fact.review_rating);
NumUsersCommenting(fact) = Count(fact.user_id);
NumBusinessesReviewed(fact) = Count(fact.business_id);
AvgBusinessRatingOverall(fact) = Avg(fact.business_rating);
AvgBusinessReviewCount(fact) = Avg(fact.business_review_count);


BusinessNameIs(fact, business_names:) :- Constraint(BusinessName(fact) in business_names);
CityIs(fact, cities:) :- Constraint(City(fact) in cities);
StateIs(fact, states:) :- Constraint(State(fact) in states);
IsOpenIs(fact, open_statuses:) :- Constraint(IsOpen(fact) in open_statuses);
UserNameIs(fact, user_names:) :- Constraint(UserName(fact) in user_names);
ReviewYearIs(fact, years:) :- Constraint(ReviewYear(fact) in years);
ReviewMonthIs(fact, months:) :- Constraint(ReviewMonth(fact) in months);
ReviewRatingIs(fact, ratings:) :- Constraint(fact.review_rating in ratings);
ReviewRatingAbove(fact, min_rating:) :- Constraint(fact.review_rating > min_rating);
ReviewRatingBelow(fact, max_rating:) :- Constraint(fact.review_rating < max_rating);
ReviewYearBetween(fact, start_year:, end_year:) :- Constraint(ReviewYear(fact) >= start_year && ReviewYear(fact) <= end_year);
