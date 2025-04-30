```yodaql
@Engine("duckdb");

LogicLM(
  name: "Academic Publications Analysis",
  title: "Explore Research Papers, Authors, and Venues",
  tagline: "<i>Analyze authors, venues, domains, citations, and keywords!</i>",
  port: 8089,
  fact_tables: ["PublicationFact"],
  default_fact_table: "PublicationFact",

  dimensions: [
    "PublicationId", "PublicationTitle", "PublicationYear",
    "AuthorId", "AuthorName", "AuthorHomepage",
    "OrganizationId", "OrganizationName", "OrganizationHomepage", "OrganizationContinent",
    "ConferenceId", "ConferenceName", "ConferenceHomepage",
    "JournalId", "JournalName", "JournalHomepage",
    "DomainId", "DomainName",
    "KeywordId", "KeywordText"
  ],

  measures: [
    "NumPublications", "NumAuthors", "NumOrganizations",
    "NumConferences", "NumJournals", "NumDomains", "NumKeywords",
    "TotalCitations", "AvgCitations", "MinCitations", "MaxCitations",
    "TotalReferences", "AvgReferences", "MinReferences", "MaxReferences",
    "MinPublicationYear", "MaxPublicationYear"
  ],

  filters: [
    "PublicationYearIs", "PublicationYearBefore", "PublicationYearAfter", "PublicationYearBetween",
    "AuthorIs", "AuthorNameContains",
    "OrganizationIs", "OrganizationContinentIs",
    "ConferenceIs",
    "JournalIs",
    "DomainIs",
    "KeywordIs",
    "CitationsMoreThan", "CitationsLessThan", "CitationsBetween",
    "ReferencesMoreThan", "ReferencesLessThan", "ReferencesBetween"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Dimensions, Measures, and Filters should be predicate calls, e.g., [AuthorName(), NumPublications()].",
    "For filters, provide arguments, e.g., PublicationYearIs(years: [2020, 2021]), CitationsMoreThan(count: 10).",
    "Use list syntax for multiple filter values: OrganizationIs(organization_ids: [101, 102]).",
    "Order results using 'order:', e.g., order: [AvgCitations() desc].",
    "Use -1 for no limit."
  ]
);


@With(PublicationFactT);
PublicationFactT(
    publication_id:, publication_title:, publication_year:,
    citation_num:, reference_num:, abstract:,
    conference_id:, journal_id:,
    author_id:, author_name:, author_homepage:,
    organization_id:, organization_name:, organization_homepage:, organization_continent:
  ) :-
  publication(pid: publication_id, title: publication_title, year: publication_year, citation_num:, reference_num:, abstract:, cid: conference_id, jid: journal_id),
  writes(pid: publication_id, aid: author_id),
  author(aid: author_id, name: author_name, homepage: author_homepage, oid: organization_id),
  organization(oid: organization_id, name: organization_name, homepage: organization_homepage, continent: organization_continent);

PublicationFact(r) :- PublicationFactT(..r);


PublicationId(fact) = fact.publication_id;
PublicationTitle(fact) = fact.publication_title;
PublicationYear(fact) = fact.publication_year;
AuthorId(fact) = fact.author_id;
AuthorName(fact) = fact.author_name;
AuthorHomepage(fact) = fact.author_homepage;
OrganizationId(fact) = fact.organization_id;
OrganizationName(fact) = fact.organization_name;
OrganizationHomepage(fact) = fact.organization_homepage;
OrganizationContinent(fact) = fact.organization_continent;

ConferenceId(fact) = ToInt(fact.conference_id) :- fact.conference_id != null;
ConferenceId(fact) = null :- fact.conference_id == null;

JournalId(fact) = fact.journal_id;


ConferenceName(fact) = conf.name :-
  cid = ConferenceId(fact), cid != null,
  conference(cid: cid, name:);
ConferenceName(fact) = null :- ConferenceId(fact) == null;

ConferenceHomepage(fact) = conf.homepage :-
  cid = ConferenceId(fact), cid != null,
  conference(cid: cid, homepage:);
ConferenceHomepage(fact) = null :- ConferenceId(fact) == null;


JournalName(fact) = jnl.name :-
  jid = JournalId(fact), jid != null,
  journal(jid: jid, name:);
JournalName(fact) = null :- JournalId(fact) == null;

JournalHomepage(fact) = jnl.homepage :-
  jid = JournalId(fact), jid != null,
  journal(jid: jid, homepage:);
JournalHomepage(fact) = null :- JournalId(fact) == null;


DomainId(fact) = dom.did :-
  domain_publication(pid: fact.publication_id, did:);
DomainId(fact) = null :- ~domain_publication(pid: fact.publication_id);


DomainName(fact) = dom.name :-
  did = DomainId(fact), did != null,
  domain(did: did, name:);
DomainName(fact) = null :- DomainId(fact) == null;


KeywordId(fact) = kw.kid :-
  publication_keyword(pid: fact.publication_id, kid:);
KeywordId(fact) = null :- ~publication_keyword(pid: fact.publication_id);


KeywordText(fact) = kw.keyword :-
  kid = KeywordId(fact), kid != null,
  keyword(kid: kid, keyword:);
KeywordText(fact) = null :- KeywordId(fact) == null;


NumPublications(fact) = Count(fact.publication_id);
NumAuthors(fact) = Count(fact.author_id);
NumOrganizations(fact) = Count(fact.organization_id);


NumConferences(fact) = Count(ConferenceId(fact)) :- ConferenceId(fact) != null;
NumConferences(fact) = 0 :- ConferenceId(fact) == null;


NumJournals(fact) = Count(JournalId(fact)) :- JournalId(fact) != null;
NumJournals(fact) = 0 :- JournalId(fact) == null;


NumDomains(fact) = Count(DomainId(fact)) :- DomainId(fact) != null;
NumDomains(fact) = 0 :- DomainId(fact) == null;


NumKeywords(fact) = Count(KeywordId(fact)) :- KeywordId(fact) != null;
NumKeywords(fact) = 0 :- KeywordId(fact) == null;


TotalCitations(fact) = Sum(fact.citation_num);
AvgCitations(fact) = Avg(fact.citation_num);
MinCitations(fact) = Min(fact.citation_num);
MaxCitations(fact) = Max(fact.citation_num);
TotalReferences(fact) = Sum(fact.reference_num);
AvgReferences(fact) = Avg(fact.reference_num);
MinReferences(fact) = Min(fact.reference_num);
MaxReferences(fact) = Max(fact.reference_num);
MinPublicationYear(fact) = Min(fact.publication_year);
MaxPublicationYear(fact) = Max(fact.publication_year);


PublicationYearIs(fact, years:) :- Constraint(PublicationYear(fact) in years);
PublicationYearBefore(fact, year:) :- PublicationYear(fact) < year;
PublicationYearAfter(fact, year:) :- PublicationYear(fact) > year;
PublicationYearBetween(fact, min_year:, max_year:) :- PublicationYear(fact) >= min_year, PublicationYear(fact) <= max_year;


AuthorIs(fact, author_ids:) :- Constraint(AuthorId(fact) in author_ids);
AuthorNameContains(fact, substr:) :- StringContains(AuthorName(fact), substr);


OrganizationIs(fact, organization_ids:) :- Constraint(OrganizationId(fact) in organization_ids);
OrganizationContinentIs(fact, continents:) :- Constraint(OrganizationContinent(fact) in continents);


ConferenceIs(fact, conference_ids:) :- cid = ConferenceId(fact), cid != null, Constraint(cid in conference_ids);


JournalIs(fact, journal_ids:) :- jid = JournalId(fact), jid != null, Constraint(jid in journal_ids);


DomainIs(fact, domain_ids:) :-
  domain_publication(pid: fact.publication_id, did: did_p),
  Constraint(did_p in domain_ids);


KeywordIs(fact, keyword_ids:) :-
  publication_keyword(pid: fact.publication_id, kid: kid_p),
  Constraint(kid_p in keyword_ids);


CitationsMoreThan(fact, count:) :- fact.citation_num > count;
CitationsLessThan(fact, count:) :- fact.citation_num < count;
CitationsBetween(fact, min_count:, max_count:) :- fact.citation_num >= min_count, fact.citation_num <= max_count;


ReferencesMoreThan(fact, count:) :- fact.reference_num > count;
ReferencesLessThan(fact, count:) :- fact.reference_num < count;
ReferencesBetween(fact, min_count:, max_count:) :- fact.reference_num >= min_count, fact.reference_num <= max_count;

```