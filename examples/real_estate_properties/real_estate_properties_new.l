@Engine("sqlite");

LogicLM(
  name: "Property Analysis",
  title: "Property and Features Exploration",
  tagline: "<i>Analyze properties, types, features, and sales data.</i>",
  port: 8090,
  fact_tables: ["PropertyDetails", "AvailableFeaturesWithType"],
  default_fact_table: "PropertyDetails",

  dimensions: [
    "PropertyName", "PropertyAddress", "RoomCount", "PropertyTypeDescription",
    "AgreedSellingPrice", "PropertyTypeCode",
    "FeatureName", "FeatureTypeName", "FeatureId"
  ],

  measures: [
    "NumProperties", "AvgRoomCount", "TotalAgreedSellingPrice", "MinAgreedSellingPrice", "MaxAgreedSellingPrice",
    "NumAvailableFeatures"
  ],

  filters: [
     "FeatureNameIs",
     "PropertyTypeDescriptionIs",
     "PropertyTypeDescriptionIn",
     "PropertyTypeCodeIn",
     "RoomCountGreaterThan",
     "RoomCountLessThan",
     "AgreedPriceAbove",
     "AgreedPriceBelow"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Dimensions, Measures, and Filters should be predicate calls.",
    "Example Query: [PropertyTypeDescription(), NumProperties()].",
    "Example Filter: RoomCountGreaterThan(count: 3), PropertyTypeCodeIn(codes: ['HSE', 'APT']).",
    "Use list syntax for multiple filter values: PropertyTypeDescriptionIn(descriptions: ['House', 'Apartment']).",
    "Order results using 'order:', e.g., order: [AgreedSellingPrice() desc].",
    "Use -1 for no limit.",
    "To count features, switch context: context: AvailableFeaturesWithType, query: [NumAvailableFeatures()].",
    "To find 'AirCon' type: context: AvailableFeaturesWithType, query: [FeatureTypeName()], filter: [FeatureNameIs(name: 'AirCon')]."
  ]
);

RefFeatureTypes(feature_type_code:, feature_type_name:) :-
  Ref_Feature_Types(feature_type_code:, feature_type_name:);

RefPropertyTypes(property_type_code:, property_type_description:) :-
  Ref_Property_Types(property_type_code:, property_type_description:);

AvailableFeaturesRaw(feature_id:, feature_type_code:, feature_name:, feature_description:) :-
  Other_Available_Features(feature_id:, feature_type_code:, feature_name:, feature_description:);

PropertiesRaw(
    property_id:, property_type_code:, date_on_market:, date_sold:, property_name:,
    property_address:, room_count:, vendor_requested_price:, buyer_offered_price:,
    agreed_selling_price:, other_property_details:
  ) :-
  Properties(
    property_id:, property_type_code:, date_on_market:, date_sold:, property_name:,
    property_address:, room_count:, vendor_requested_price:, buyer_offered_price:,
    agreed_selling_price:, other_property_details:
  );

PropertyDetailsT(
  property_id:, property_type_code:, date_on_market:, date_sold:, property_name:,
  property_address:, room_count:, vendor_requested_price:, buyer_offered_price:,
  agreed_selling_price:, other_property_details:,
  property_type_description:
) :-
  PropertiesRaw(
    property_id:, property_type_code:, date_on_market:, date_sold:, property_name:,
    property_address:, room_count:, vendor_requested_price:, buyer_offered_price:,
    agreed_selling_price:, other_property_details:
  ),
  RefPropertyTypes(property_type_code:, property_type_description:);

PropertyDetails(r) :- PropertyDetailsT(..r);

AvailableFeaturesWithTypeT(
  feature_id:, feature_type_code:, feature_name:, feature_description:,
  feature_type_name:
) :-
  AvailableFeaturesRaw(feature_id:, feature_type_code:, feature_name:, feature_description:),
  RefFeatureTypes(feature_type_code:, feature_type_name:);

AvailableFeaturesWithType(r) :- AvailableFeaturesWithTypeT(..r);

PropertyName(fact) = fact.property_name;
PropertyAddress(fact) = fact.property_address;
RoomCount(fact) = fact.room_count;
PropertyTypeDescription(fact) = fact.property_type_description;
AgreedSellingPrice(fact) = fact.agreed_selling_price;
PropertyTypeCode(fact) = fact.property_type_code;

FeatureName(fact) = fact.feature_name;
FeatureTypeName(fact) = fact.feature_type_name;
FeatureId(fact) = fact.feature_id;

NumProperties(fact) = Sum(1);
AvgRoomCount(fact) = Avg(fact.room_count);
TotalAgreedSellingPrice(fact) = Sum(fact.agreed_selling_price);
MinAgreedSellingPrice(fact) = Min(fact.agreed_selling_price);
MaxAgreedSellingPrice(fact) = Max(fact.agreed_selling_price);

NumAvailableFeatures(fact) = Sum(1);

FeatureNameIs(fact, name:) :- fact.feature_name == name;
PropertyTypeDescriptionIs(fact, desc:) :- fact.property_type_description == desc;
PropertyTypeDescriptionIn(fact, descriptions:) :- Constraint(fact.property_type_description in descriptions);
PropertyTypeCodeIn(fact, codes:) :- Constraint(fact.property_type_code in codes);
RoomCountGreaterThan(fact, count:) :- fact.room_count > count;
RoomCountLessThan(fact, count:) :- fact.room_count < count;
AgreedPriceAbove(fact, price:) :- fact.agreed_selling_price > price;
AgreedPriceBelow(fact, price:) :- fact.agreed_selling_price < price;