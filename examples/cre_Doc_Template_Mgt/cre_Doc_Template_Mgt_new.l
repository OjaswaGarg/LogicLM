@Engine("duckdb");

LogicLM(
  name: "Document Template Analysis",
  title: "Documents, Templates, and Paragraphs",
  tagline: "<i>Analyze document structures, template usage, and content.</i>",
  port: 8090,
  fact_tables: ["Documents", "Templates", "Paragraphs", "RefTemplateTypes", "DocWithTemplateInfo"],
  default_fact_table: "Documents",

  dimensions: [
    "DocumentId", "DocumentName", "DocumentDescription", "DocumentTemplateId",
    "TemplateId", "TemplateVersion", "TemplateTypeCode", "TemplateDetails",
    "TemplateTypeDescription", "TemplateTypeCodeFromRef",
    "ParagraphId", "ParagraphText", "ParagraphDocId", "ParagraphOtherDetails"
  ],

  measures: [
    "NumRows", "MinVersionNumber", "MaxVersionNumber"
  ],

  filters: [
     "DocDescContainsW", "DocNameIs", "TemplateTypeCodeIs", "TemplateTypeCodeIn",
     "TemplateVersionGreaterThan", "TemplateTypeDescIs", "TemplateTypeCodeIsRef",
     "ParagraphTextContains", "ParagraphTextIs", "DocIdIs",
     "TemplateIsUsed", "TemplateIsNotUsed",
     "TemplateTypeIsUsed", "TemplateTypeIsNotUsed",
     "DocHasMinParagraphs", "DocHasParagraphCountBetween",
     "DocContainsParagraphText", "DocContainsAllParagraphTexts"
  ],

  suffix_lines: [
    "Use Table() chart type by default.",
    "Select the appropriate Fact Table for your query (Documents, Templates, Paragraphs, RefTemplateTypes, DocWithTemplateInfo).",
    "Dimensions, Measures, and Filters are predicate calls, e.g., [DocumentName(), NumRows()].",
    "Provide arguments for filters, e.g., DocNameIs(name_value: 'Robbin CV'), TemplateTypeCodeIn(code_values: ['PP', 'PPT']).",
    "Order results using 'order:', e.g., order: [DocumentId() asc].",
    "Use -1 for no limit.",
    "To count distinct items (e.g., templates used), use a dimension like TemplateId() and the Count aggregation in the UI.",
    "To count items per group (e.g., docs per template), group by a dimension (TemplateId()) and use NumRows().",
    "Use DocWithTemplateInfo fact table for queries combining Document, Template, and Type information.",
    "Filter DocContainsAllParagraphTexts(text_values: ['Brazil', 'Ireland']) checks if a document contains paragraphs with EACH of the specified texts."
  ]
);

RefTemplateTypes(template_type_code:, template_type_description:) :-
  ref_template_types(template_type_code:, template_type_description:);

Templates(template_id:, version_number:, template_type_code:, date_effective_from:, date_effective_to:, template_details:) :-
  templates(template_id:, version_number:, template_type_code:, date_effective_from:, date_effective_to:, template_details:);

Documents(document_id:, template_id:, document_name:, document_description:, other_details:) :-
  documents(document_id:, template_id:, document_name:, document_description:, other_details:);

Paragraphs(paragraph_id:, document_id:, paragraph_text:, other_details:) :-
  paragraphs(paragraph_id:, document_id:, paragraph_text:, other_details:);

DocWithTemplateInfoT(
    document_id:, template_id:, document_name:, document_description:, doc_other_details:,
    version_number:, template_type_code:, date_effective_from:, date_effective_to:, template_details:,
    template_type_description:
  ) :-
  Documents(document_id:, template_id:, document_name:, document_description:, other_details: doc_other_details),
  template_id != null,
  Templates(template_id:, version_number:, template_type_code:, date_effective_from:, date_effective_to:, template_details:),
  RefTemplateTypes(template_type_code:, template_type_description:);

DocWithTemplateInfo(r) :- DocWithTemplateInfoT(..r);


DocumentId(fact) = fact.document_id;
DocumentName(fact) = fact.document_name;
DocumentDescription(fact) = fact.document_description;
DocumentTemplateId(fact) = fact.template_id;

TemplateId(fact) = fact.template_id;
TemplateVersion(fact) = fact.version_number;
TemplateTypeCode(fact) = fact.template_type_code;
TemplateDetails(fact) = fact.template_details;
TemplateTypeCodeFromRef(fact) = fact.template_type_code;
TemplateTypeDescription(fact) = fact.template_type_description;

ParagraphId(fact) = fact.paragraph_id;
ParagraphText(fact) = fact.paragraph_text;
ParagraphDocId(fact) = fact.document_id;
ParagraphOtherDetails(fact) = fact.other_details;


NumRows(fact) = Sum(1);
MinVersionNumber(fact) = Min(fact.version_number);
MaxVersionNumber(fact) = Max(fact.version_number);


DocDescContainsW(fact) :- Contains(DocumentDescription(fact), "w");
DocNameIs(fact, name_value:) :- DocumentName(fact) == name_value;
TemplateTypeCodeIs(fact, code_value:) :- TemplateTypeCode(fact) == code_value;
TemplateTypeCodeIn(fact, code_values:) :- TemplateTypeCode(fact) in code_values;
TemplateVersionGreaterThan(fact, version_value:) :- TemplateVersion(fact) > version_value;
TemplateTypeDescIs(fact, desc_value:) :- TemplateTypeDescription(fact) == desc_value;
TemplateTypeCodeIsRef(fact, code_value:) :- TemplateTypeCodeFromRef(fact) == code_value;
ParagraphTextContains(fact, text_value:) :- Contains(ParagraphText(fact), text_value);
ParagraphTextIs(fact, text_value:) :- ParagraphText(fact) == text_value;
DocIdIs(fact, id_value:) :- DocumentId(fact) == id_value;

TemplateIsUsed(fact) :- Documents(template_id: TemplateId(fact));
TemplateIsNotUsed(fact) :- ~Documents(template_id: TemplateId(fact));
TemplateTypeIsUsed(fact) :- DocWithTemplateInfo(template_type_code: TemplateTypeCodeFromRef(fact));
TemplateTypeIsNotUsed(fact) :- ~DocWithTemplateInfo(template_type_code: TemplateTypeCodeFromRef(fact));

DocHasMinParagraphs(fact, min_count:) :-
  count = Count({p.paragraph_id :- Paragraphs(document_id: DocumentId(fact), paragraph_id: p.paragraph_id)}),
  count >= min_count;

DocHasParagraphCountBetween(fact, min_count:, max_count:) :-
  count = Count({p.paragraph_id :- Paragraphs(document_id: DocumentId(fact), paragraph_id: p.paragraph_id)}),
  count >= min_count, count <= max_count;

DocContainsParagraphText(fact, text_value:) :-
  Paragraphs(document_id: DocumentId(fact), paragraph_text: p_text),
  Contains(p_text, text_value);

DocContainsAllParagraphTexts(fact, text_values:) :-
  check = Min({
    1 :- txt in text_values, Paragraphs(document_id: DocumentId(fact), paragraph_text: p_text), Contains(p_text, txt)
  }),
  check == 1;