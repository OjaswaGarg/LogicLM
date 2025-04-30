@Engine("duckdb");

LogicLM(
  name: "Apartment Bookings Analysis",
  title: "Apartment Rental Data Exploration",
  tagline: "<i>Analyze bookings, guests, apartments, and buildings.</i>",
  port: 8089,
  fact_tables: ["BookingFact"],
  default_fact_table: "BookingFact",

  dimensions: [
    "BookingId", "BookingStatus",
    "ApartmentId", "ApartmentNumber", "ApartmentType", "BathroomCount", "BedroomCount", "RoomCount",
    "BuildingId", "BuildingShortName", "BuildingFullName", "BuildingManager", "BuildingAddress", "BuildingPhone",
    "GuestId", "GuestGender", "GuestFirstName", "GuestLastName", "GuestDateOfBirth"
  ],

  measures: [
    "NumBookings", "NumGuests", "NumApartments", "NumBuildings",
    "AvgBathroomCount", "AvgBedroomCount", "TotalBathrooms", "TotalBedrooms",
    "MinBedrooms", "MaxBedrooms", "MinBathroomCount", "MaxBathroomCount",
    "MinBookingStartDate", "MaxBookingStartDate", "MinBookingEndDate", "MaxBookingEndDate"
  ],

  filters: [
     "BuildingIs", "ApartmentTypeIs", "BookingStatusIs", "GenderIs",
     "GuestIs", "ApartmentIs", "BuildingShortNameIs", "BuildingFullNameIs",
     "BookingStartsAfter", "BookingStartsBefore", "BookingEndsAfter", "BookingEndsBefore",
     "BookingStartDateBetween", "BookingEndDateBetween",
     "BedroomsAre", "BedroomsMoreThan", "BedroomsLessThan",
     "BathroomsAre", "BathroomsMoreThan", "BathroomsLessThan"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Dimensions, Measures, and Filters should be predicate calls, e.g., [BuildingShortName(), NumBookings()].",
    "For filters, provide arguments, e.g., BedroomsAre(bedrooms: [2, 3]), BookingStatusIs(status: 'Confirmed').",
    "Use list syntax for multiple filter values where applicable: ApartmentTypeIs(types: ['1BR', '2BR']).",
    "Use date strings like 'YYYY-MM-DD' for date filters.",
    "Order results using 'order:', e.g., order: [AvgBathroomCount() desc].",
    "Use -1 for no limit."
  ]
);

@With(BookingFactT);
BookingFactT(
    booking_id:, apt_booking_id:, guest_id:, booking_status_code:, booking_start_date:, booking_end_date:,
    apt_id:, building_id:, apt_type_code:, apt_number:, bathroom_count:, bedroom_count:, room_count:,
    building_short_name:, building_full_name:, building_description:, building_address:, building_manager:, building_phone:,
    gender_code:, guest_first_name:, guest_last_name:, date_of_birth:
  ) :-
  Apartment_Bookings(apt_booking_id:, apt_id: apt_id_booking, guest_id:, booking_status_code:, booking_start_date:, booking_end_date:),
  booking_id == apt_booking_id,
  Apartments(apt_id: apt_id_booking, building_id:, apt_type_code:, apt_number:, bathroom_count:, bedroom_count:, room_count:),
  Apartment_Buildings(building_id:, building_short_name:, building_full_name:, building_description:, building_address:, building_manager:, building_phone:),
  Guests(guest_id:, gender_code:, guest_first_name:, guest_last_name:, date_of_birth:);

BookingFact(r) :- BookingFactT(..r);

BookingId(fact) = fact.booking_id;
BookingStatus(fact) = fact.booking_status_code;
ApartmentId(fact) = fact.apt_id;
ApartmentNumber(fact) = fact.apt_number;
ApartmentType(fact) = fact.apt_type_code;
BathroomCount(fact) = fact.bathroom_count;
BedroomCount(fact) = fact.bedroom_count;
RoomCount(fact) = fact.room_count;
BuildingId(fact) = fact.building_id;
BuildingShortName(fact) = fact.building_short_name;
BuildingFullName(fact) = fact.building_full_name;
BuildingManager(fact) = fact.building_manager;
BuildingAddress(fact) = fact.building_address;
BuildingPhone(fact) = fact.building_phone;
GuestId(fact) = fact.guest_id;
GuestGender(fact) = fact.gender_code;
GuestFirstName(fact) = fact.guest_first_name;
GuestLastName(fact) = fact.guest_last_name;
GuestDateOfBirth(fact) = fact.date_of_birth;

NumBookings(fact) = Sum(1);
NumGuests(fact) = Count(fact.guest_id);
NumApartments(fact) = Count(fact.apt_id);
NumBuildings(fact) = Count(fact.building_id);

AvgBathroomCount(fact) = Avg(fact.bathroom_count);
AvgBedroomCount(fact) = Avg(fact.bedroom_count);
TotalBathrooms(fact) = Sum(fact.bathroom_count);
TotalBedrooms(fact) = Sum(fact.bedroom_count);
MinBedrooms(fact) = Min(fact.bedroom_count);
MaxBedrooms(fact) = Max(fact.bedroom_count);
MinBathroomCount(fact) = Min(fact.bathroom_count);
MaxBathroomCount(fact) = Max(fact.bathroom_count);

MinBookingStartDate(fact) = Min(fact.booking_start_date);
MaxBookingStartDate(fact) = Max(fact.booking_start_date);
MinBookingEndDate(fact) = Min(fact.booking_end_date);
MaxBookingEndDate(fact) = Max(fact.booking_end_date);

BuildingIs(fact, building_ids:) :- Constraint(BuildingId(fact) in building_ids);
ApartmentTypeIs(fact, types:) :- Constraint(ApartmentType(fact) in types);
BookingStatusIs(fact, status_codes:) :- Constraint(BookingStatus(fact) in status_codes);
GenderIs(fact, gender_codes:) :- Constraint(GuestGender(fact) in gender_codes);
GuestIs(fact, guest_ids:) :- Constraint(GuestId(fact) in guest_ids);
ApartmentIs(fact, apt_ids:) :- Constraint(ApartmentId(fact) in apt_ids);
BuildingShortNameIs(fact, names:) :- Constraint(BuildingShortName(fact) in names);
BuildingFullNameIs(fact, names:) :- Constraint(BuildingFullName(fact) in names);

BookingStartsAfter(fact, start_date:) :- fact.booking_start_date > start_date;
BookingStartsBefore(fact, start_date:) :- fact.booking_start_date < start_date;
BookingEndsAfter(fact, end_date:) :- fact.booking_end_date > end_date;
BookingEndsBefore(fact, end_date:) :- fact.booking_end_date < end_date;
BookingStartDateBetween(fact, min_start_date:, max_start_date:) :- fact.booking_start_date >= min_start_date, fact.booking_start_date <= max_start_date;
BookingEndDateBetween(fact, min_end_date:, max_end_date:) :- fact.booking_end_date >= min_end_date, fact.booking_end_date <= max_end_date;

BedroomsAre(fact, bedroom_counts:) :- Constraint(BedroomCount(fact) in bedroom_counts);
BedroomsMoreThan(fact, count:) :- BedroomCount(fact) > count;
BedroomsLessThan(fact, count:) :- BedroomCount(fact) < count;

BathroomsAre(fact, bathroom_counts:) :- Constraint(BathroomCount(fact) in bathroom_counts);
BathroomsMoreThan(fact, count:) :- BathroomCount(fact) > count;
BathroomsLessThan(fact, count:) :- BathroomCount(fact) < count;