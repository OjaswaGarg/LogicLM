@Engine("duckdb");

LogicLM(
  name: "Vet Clinic Analysis",
  title: "Analysis of Dogs, Owners, Professionals, and Treatments",
  tagline: "<i>Explore clinic data including treatments, costs, breeds, and demographics.</i>",
  port: 8090,
  fact_tables: ["DogFact", "TreatmentFact", "ProfessionalFact", "OwnerFact", "ChargeFact"],
  default_fact_table: "DogFact",

  dimensions: [
    "DogId", "DogName", "DogAge", "DogAgeStr", "DogWeightStr", "DogGender", "DogAbandonedYN", "DogDateArrived", "DogDateDeparted", "DogDateOfBirth",
    "OwnerId", "OwnerFirstName", "OwnerLastName", "OwnerCity", "OwnerState", "OwnerZipCode", "OwnerEmail", "OwnerHomePhone", "OwnerCellNumber",
    "BreedCode", "BreedName",
    "SizeCode", "SizeDescription",
    "ProfessionalId", "ProfessionalFirstName", "ProfessionalLastName", "ProfessionalRoleCode", "ProfessionalCity", "ProfessionalState", "ProfessionalZipCode", "ProfessionalEmail", "ProfessionalHomePhone", "ProfessionalCellNumber",
    "TreatmentId", "TreatmentDate", "TreatmentCost",
    "TreatmentTypeCode", "TreatmentTypeDescription",
    "ChargeType", "ChargeAmount"
  ],

  measures: [
    "NumDogs", "NumOwners", "NumProfessionals", "NumTreatments",
    "AvgDogAge", "MinDogAge", "MaxDogAge",
    "AvgTreatmentCost", "MinTreatmentCost", "MaxTreatmentCost", "TotalTreatmentCost",
    "TotalTreatmentCostPerOwner", "TotalTreatmentCostPerDog", "TotalTreatmentCostPerType",
    "NumDogsPerOwner", "NumDogsPerBreed",
    "NumTreatmentsPerProfessional", "NumTreatmentTypesPerProfessional",
    "NumProfessionalsWhoTreated", "NumProfessionalsWhoDidNotTreat",
    "NumDogsWithTreatments", "NumDogsWithoutTreatments",
    "NumOwnersWithDogs", "NumOwnersWithoutDogs",
    "MaxChargeAmount",
    "CountDistinctStatesOwners", "CountDistinctStatesProfessionals"
  ],

  filters: [
    "OwnerStateIs", "ProfessionalStateIs",
    "OwnerStateContains", "ProfessionalCityContains",
    "DogAgeBelow", "DogAgeAbove", "DogAgeIs",
    "TreatmentCostLessThan", "TreatmentCostGreaterThan", "TreatmentCostIs",
    "TreatmentCostBelowAverage",
    "PerformedTreatments", "PerformedNoTreatments",
    "OwnsDogs", "OwnsNoDogs",
    "PerformedNumTreatmentsMoreThan", "PerformedNumTreatmentTypesMoreThan",
    "ProfessionalStateInList",
    "BreedNameIs", "SizeDescriptionIs",
    "IsAbandoned",
    "DogNameIs", "OwnerFirstNameIs", "ProfessionalFirstNameIs",
    "FirstNameIsOwnerOrProfessional", "FirstNameIsNotDog",
    "TreatmentDateIs", "TreatmentDateBefore", "TreatmentDateAfter"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Dimensions, Measures, and Filters are predicate calls, e.g., [OwnerState(), NumDogs()].",
    "Provide arguments for filters, e.g., OwnerStateIs(state_val: 'CA'), DogAgeBelow(max_age: 5).",
    "Use list syntax for multiple filter values, e.g., ProfessionalStateInList(states: ['HI', 'WI']).",
    "Order results using 'order:', e.g., order: [AvgDogAge() desc]. Use -1 for no limit.",
    "To find extrema (e.g., owner with most dogs), sort and limit, e.g., query: [OwnerId(), OwnerFirstName(), NumDogsPerOwner()], order: [NumDogsPerOwner() desc], limit: 1.",
    "DogAge requires conversion from text; invalid ages may become null.",
    "Use 'having:' for conditions on aggregated measures, e.g., query: [ProfessionalId(), NumTreatmentsPerProfessional()], having: [NumTreatmentsPerProfessional() > 2]."
  ]
);

OwnersP(owner_id:, first_name:, last_name:, street:, city:, state:, zip_code:, email_address:, home_phone:, cell_number:) :-
  owners(owner_id:, first_name:, last_name:, street:, city:, state:, zip_code:, email_address:, home_phone:, cell_number:);

DogsP(dog_id:, owner_id:, abandoned_yn:, breed_code:, size_code:, name:, age_str:, date_of_birth:, gender:, weight_str:, date_arrived:, date_adopted:, date_departed:) :-
  dogs(dog_id: dog_id, owner_id: owner_id, abandoned_yn: abandoned_yn, breed_code: breed_code, size_code: size_code, name: name, age: age_str, date_of_birth: date_of_birth, gender: gender, weight: weight_str, date_arrived: date_arrived, date_adopted: date_adopted, date_departed: date_departed);

BreedsP(breed_code:, breed_name:) :-
  breeds(breed_code:, breed_name:);

SizesP(size_code:, size_description:) :-
  sizes(size_code:, size_description:);

ProfessionalsP(professional_id:, role_code:, first_name:, street:, city:, state:, zip_code:, last_name:, email_address:, home_phone:, cell_number:) :-
  professionals(professional_id:, role_code:, first_name:, street:, city:, state:, zip_code:, last_name:, email_address:, home_phone:, cell_number:);

TreatmentsP(treatment_id:, dog_id:, professional_id:, treatment_type_code:, date_of_treatment:, cost_of_treatment:) :-
  treatments(treatment_id:, dog_id:, professional_id:, treatment_type_code:, date_of_treatment:, cost_of_treatment:);

TreatmentTypesP(treatment_type_code:, treatment_type_description:) :-
  treatment_types(treatment_type_code:, treatment_type_description:);

ChargesP(charge_id:, charge_type:, charge_amount:) :-
  charges(charge_id:, charge_type:, charge_amount:);

StringIsNumeric(s) :- s != null, REGEXP_MATCH(s, '^[0-9]+(\.[0-9]+)?$');
SafeDogAge(age_str) = ToInt64(age_str) :- StringIsNumeric(age_str);
SafeDogAge(age_str) = null :- ~StringIsNumeric(age_str);

DogFactT(
    dog_id:, dog_name:, dog_age_str:, dog_weight_str:, dog_gender:, dog_abandoned_yn:, dog_date_arrived:, dog_date_adopted:, dog_date_departed:, dog_date_of_birth:,
    owner_id:, owner_first_name:, owner_last_name:, owner_street:, owner_city:, owner_state:, owner_zip_code:, owner_email:, owner_home_phone:, owner_cell_number:,
    breed_code:, breed_name:,
    size_code:, size_description:
  ) :-
  DogsP(dog_id: dog_id, owner_id: owner_id, abandoned_yn: dog_abandoned_yn, breed_code: breed_code, size_code: size_code, name: dog_name, age_str: dog_age_str, weight_str: dog_weight_str, gender: dog_gender, date_arrived: dog_date_arrived, date_adopted: dog_date_adopted, date_departed: dog_date_departed, date_of_birth: dog_date_of_birth),
  OwnersP(owner_id: owner_id, first_name: owner_first_name, last_name: owner_last_name, street: owner_street, city: owner_city, state: owner_state, zip_code: owner_zip_code, email_address: owner_email, home_phone: owner_home_phone, cell_number: owner_cell_number),
  BreedsP(breed_code: breed_code, breed_name: breed_name),
  SizesP(size_code: size_code, size_description: size_description);

DogFact(r) :- DogFactT(..r);

TreatmentFactT(
    treatment_id:, date_of_treatment:, cost_of_treatment:,
    dog_id:, dog_name:, dog_age_str:, dog_gender:, dog_abandoned_yn:,
    owner_id:, owner_first_name:, owner_last_name:, owner_city:, owner_state:, owner_zip_code:,
    breed_code:, breed_name:,
    size_code:, size_description:,
    professional_id:, prof_first_name:, prof_last_name:, prof_role_code:, prof_city:, prof_state:, prof_zip_code:, prof_email:, prof_cell_number:,
    treatment_type_code:, treatment_type_description:
  ) :-
  TreatmentsP(treatment_id: treatment_id, dog_id: dog_id, professional_id: professional_id, treatment_type_code: treatment_type_code, date_of_treatment: date_of_treatment, cost_of_treatment: cost_of_treatment),
  DogsP(dog_id: dog_id, owner_id: owner_id, breed_code: breed_code, size_code: size_code, name: dog_name, age_str: dog_age_str, gender: dog_gender, abandoned_yn: dog_abandoned_yn),
  OwnersP(owner_id: owner_id, first_name: owner_first_name, last_name: owner_last_name, city: owner_city, state: owner_state, zip_code: owner_zip_code),
  BreedsP(breed_code: breed_code, breed_name: breed_name),
  SizesP(size_code: size_code, size_description: size_description),
  ProfessionalsP(professional_id: professional_id, first_name: prof_first_name, last_name: prof_last_name, role_code: prof_role_code, city: prof_city, state: prof_state, zip_code: prof_zip_code, email_address: prof_email, cell_number: prof_cell_number),
  TreatmentTypesP(treatment_type_code: treatment_type_code, treatment_type_description: treatment_type_description);

TreatmentFact(r) :- TreatmentFactT(..r);

ProfessionalFactT(
    professional_id:, role_code:, first_name:, street:, city:, state:, zip_code:, last_name:, email_address:, home_phone:, cell_number:
  ) :- ProfessionalsP(professional_id:, role_code:, first_name:, street:, city:, state:, zip_code:, last_name:, email_address:, home_phone:, cell_number:);
ProfessionalFact(r) :- ProfessionalFactT(..r);

OwnerFactT(
    owner_id:, first_name:, last_name:, street:, city:, state:, zip_code:, email_address:, home_phone:, cell_number:
  ) :- OwnersP(owner_id:, first_name:, last_name:, street:, city:, state:, zip_code:, email_address:, home_phone:, cell_number:);
OwnerFact(r) :- OwnerFactT(..r);

ChargeFactT(charge_id:, charge_type:, charge_amount:) :- ChargesP(charge_id:, charge_type:, charge_amount:);
ChargeFact(r) :- ChargeFactT(..r);

DogId(fact) = fact.dog_id;
DogName(fact) = fact.dog_name;
DogAgeStr(fact) = fact.dog_age_str;
DogAge(fact) = SafeDogAge(fact.dog_age_str);
DogWeightStr(fact) = fact.dog_weight_str;
DogGender(fact) = fact.dog_gender;
DogAbandonedYN(fact) = fact.dog_abandoned_yn;
DogDateArrived(fact) = fact.dog_date_arrived;
DogDateDeparted(fact) = fact.dog_date_departed;
DogDateOfBirth(fact) = fact.dog_date_of_birth;
OwnerId(fact) = fact.owner_id;
OwnerFirstName(fact) = fact.owner_first_name;
OwnerLastName(fact) = fact.owner_last_name;
OwnerCity(fact) = fact.owner_city;
OwnerState(fact) = fact.owner_state;
OwnerZipCode(fact) = fact.owner_zip_code;
OwnerEmail(fact) = fact.owner_email;
OwnerHomePhone(fact) = fact.owner_home_phone;
OwnerCellNumber(fact) = fact.owner_cell_number;
BreedCode(fact) = fact.breed_code;
BreedName(fact) = fact.breed_name;
SizeCode(fact) = fact.size_code;
SizeDescription(fact) = fact.size_description;
ProfessionalId(fact) = fact.professional_id;
ProfessionalFirstName(fact) = fact.prof_first_name;
ProfessionalLastName(fact) = fact.prof_last_name;
ProfessionalRoleCode(fact) = fact.prof_role_code;
ProfessionalCity(fact) = fact.prof_city;
ProfessionalState(fact) = fact.prof_state;
ProfessionalZipCode(fact) = fact.prof_zip_code;
ProfessionalEmail(fact) = fact.prof_email;
ProfessionalHomePhone(fact) = fact.prof_home_phone;
ProfessionalCellNumber(fact) = fact.prof_cell_number;
TreatmentId(fact) = fact.treatment_id;
TreatmentDate(fact) = fact.date_of_treatment;
TreatmentCost(fact) = fact.cost_of_treatment;
TreatmentTypeCode(fact) = fact.treatment_type_code;
TreatmentTypeDescription(fact) = fact.treatment_type_description;
ChargeType(fact) = fact.charge_type;
ChargeAmount(fact) = fact.charge_amount;

NumDogs(fact) = Count(fact.dog_id);
NumOwners(fact) = Count(fact.owner_id);
NumProfessionals(fact) = Count(fact.professional_id);
NumTreatments(fact) = Count(fact.treatment_id);
AvgDogAge(fact) = Avg(DogAge(fact));
MinDogAge(fact) = Min(DogAge(fact));
MaxDogAge(fact) = Max(DogAge(fact));
AvgTreatmentCost(fact) = Avg(fact.cost_of_treatment);
MinTreatmentCost(fact) = Min(fact.cost_of_treatment);
MaxTreatmentCost(fact) = Max(fact.cost_of_treatment);
TotalTreatmentCost(fact) = Sum(fact.cost_of_treatment);
TotalTreatmentCostPerOwner(fact) = Sum(fact.cost_of_treatment);
TotalTreatmentCostPerDog(fact) = Sum(fact.cost_of_treatment);
TotalTreatmentCostPerType(fact) = Sum(fact.cost_of_treatment);
NumDogsPerOwner(fact) = Count(fact.dog_id);
NumDogsPerBreed(fact) = Count(fact.dog_id);
NumTreatmentsPerProfessional(fact) = Count(fact.treatment_id);
NumTreatmentTypesPerProfessional(fact) = Count(fact.treatment_type_code);
NumProfessionalsWhoTreated(fact) = Count(fact.professional_id) :- TreatmentsP(professional_id: fact.professional_id);
NumProfessionalsWhoDidNotTreat(fact) = Count(fact.professional_id) :- ~TreatmentsP(professional_id: fact.professional_id);
NumDogsWithTreatments(fact) = Count(fact.dog_id) :- TreatmentsP(dog_id: fact.dog_id);
NumDogsWithoutTreatments(fact) = Count(fact.dog_id) :- ~TreatmentsP(dog_id: fact.dog_id);
NumOwnersWithDogs(fact) = Count(fact.owner_id) :- DogsP(owner_id: fact.owner_id);
NumOwnersWithoutDogs(fact) = Count(fact.owner_id) :- ~DogsP(owner_id: fact.owner_id);
MaxChargeAmount(fact) = Max(fact.charge_amount);
CountDistinctStatesOwners(fact) = Count(fact.owner_state);
CountDistinctStatesProfessionals(fact) = Count(fact.prof_state);

OwnerStateIs(fact, state_val:) :- fact.owner_state == state_val;
ProfessionalStateIs(fact, state_val:) :- fact.prof_state == state_val;
OwnerStateContains(fact, substr:) :- Contains(fact.owner_state, substr);
ProfessionalCityContains(fact, substr:) :- Contains(fact.prof_city, substr);
DogAgeBelow(fact, max_age:) :- DogAge(fact) < max_age;
DogAgeAbove(fact, min_age:) :- DogAge(fact) > min_age;
DogAgeIs(fact, age_val:) :- DogAge(fact) == age_val;
TreatmentCostLessThan(fact, max_cost:) :- fact.cost_of_treatment < max_cost;
TreatmentCostGreaterThan(fact, min_cost:) :- fact.cost_of_treatment > min_cost;
TreatmentCostIs(fact, cost_val:) :- fact.cost_of_treatment == cost_val;
GlobalAvgTreatmentCost() = Avg(cost_of_treatment) :- TreatmentsP(cost_of_treatment:);
TreatmentCostBelowAverage(fact) :- fact.cost_of_treatment < GlobalAvgTreatmentCost();
PerformedTreatments(fact) :- TreatmentsP(professional_id: fact.professional_id) | TreatmentsP(dog_id: fact.dog_id);
PerformedNoTreatments(fact) :- ~TreatmentsP(professional_id: fact.professional_id) | ~TreatmentsP(dog_id: fact.dog_id);
OwnsDogs(fact) :- DogsP(owner_id: fact.owner_id);
OwnsNoDogs(fact) :- ~DogsP(owner_id: fact.owner_id);
TreatmentsByProfessional(professional_id:) += 1 :- TreatmentsP(professional_id:);
PerformedNumTreatmentsMoreThan(fact, min_count:) :- TreatmentsByProfessional(professional_id: fact.professional_id) > min_count;
TreatmentTypesByProfessional(professional_id:, treatment_type_code:) distinct :- TreatmentsP(professional_id:, treatment_type_code:);
NumTreatmentTypesByProfessionalAgg(professional_id:) += 1 :- TreatmentTypesByProfessional(professional_id:);
PerformedNumTreatmentTypesMoreThan(fact, min_count:) :- NumTreatmentTypesByProfessionalAgg(professional_id: fact.professional_id) > min_count;
ProfessionalStateInList(fact, states:) :- fact.prof_state in states;
BreedNameIs(fact, breed_name_val:) :- fact.breed_name == breed_name_val;
SizeDescriptionIs(fact, size_desc_val:) :- fact.size_description == size_desc_val;
IsAbandoned(fact) :- fact.dog_abandoned_yn == '1';
DogNameIs(fact, name_val:) :- fact.dog_name == name_val;
OwnerFirstNameIs(fact, name_val:) :- fact.owner_first_name == name_val;
ProfessionalFirstNameIs(fact, name_val:) :- fact.prof_first_name == name_val;
OwnerFirstNames(name:) distinct :- OwnersP(first_name: name);
ProfessionalFirstNames(name:) distinct :- ProfessionalsP(first_name: name);
DogNames(name:) distinct :- DogsP(name:);
FirstNameIsOwnerOrProfessional(fact) :- OwnerFirstNames(name: fact.owner_first_name) | ProfessionalFirstNames(name: fact.prof_first_name);
FirstNameIsNotDog(fact) :- ~DogNames(name: fact.owner_first_name), ~DogNames(name: fact.prof_first_name);
TreatmentDateIs(fact, date_val:) :- fact.date_of_treatment == date_val;
TreatmentDateBefore(fact, date_val:) :- fact.date_of_treatment < date_val;
TreatmentDateAfter(fact, date_val:) :- fact.date_of_treatment > date_val;