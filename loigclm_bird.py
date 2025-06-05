#!/usr/bin/python
#
# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


import sys
import json

import olap
import ai
import server
import time
import re
import pandas as pd
import os
import traceback


from logica.common import logica_lib
from logica.type_inference.research import infer
from logica.parser_py import parse
import run_sql_db
import collections
from logica.compiler import universe

_QUESTION_FILE_NAME="/usr/local/google/home/ojaswagarg/LogicLM/Bird/Data/dev.json"
_DATABASE_FILE_NAME="/usr/local/google/home/ojaswagarg/LogicLM/Bird/Data/dev_databases/"
_LOGICA_ANSWERS_OUTPUT="/usr/local/google/home/ojaswagarg/LogicLM/Bird/answers_snip2.json"
_LOGICA_ANSWERS_OUTPUT_CLEANED ="/usr/local/google/home/ojaswagarg/LogicLM/Bird/answers_snip2_cleaned.json"
_LOGICA_GENERATED_QUERIES="/usr/local/google/home/ojaswagarg/LogicLM/Bird/generated_query_snip2.txt"
_LOGICA_ACTUAL_QUERIES="/usr/local/google/home/ojaswagarg/LogicLM/Bird/actual_query_snip2.txt"
_GOLDEN_SQL="/usr/local/google/home/ojaswagarg/LogicLM/Bird/dev_gold.sql"
_COMPARE_OUTPUT="/usr/local/google/home/ojaswagarg/LogicLM/Bird/predict_dev.json"


def cleanup_schema(sql_schema):
  lines = sql_schema.strip().split('\n')
  filtered_lines = [line for line in lines if not line.lower().startswith("insert into")]
  sql_schema = "\n".join(filtered_lines)
  sql_schema = re.sub(r'\(([^;]+?)\)', lowercase_inside_parentheses, sql_schema, flags=re.DOTALL)
  converted_schema = re.sub(r'"([^"]+)"', lowercase_quotes, sql_schema)
  converted_schema = re.sub(r'\n\s*\n', '\n', converted_schema)
  return converted_schema


def cleanup_content(content):
    lines = content.strip().split('\n')
    filtered_lines = [line for line in lines if not line.lower().startswith("```")]
    content_filtered = "\n".join(filtered_lines)
    return content_filtered

def write_list_to_file(string_list, filename):
  """Writes a list of strings to a specified file, with each string on a new line.

  Args:
    string_list: A list of strings to be written to the file.
    filename: The name of the file to write to.
  """
  try:
    with open(filename, 'w') as file:
      for line in string_list:
        file.write(line + '\n')
    print(f"Successfully wrote {len(string_list)} lines to '{filename}'.")
  except Exception as e:
    print(f"An error occurred while writing to '{filename}': {e}")

def create_and_write_file(filepath, content):
    """Creates a file at the specified filepath (including parent directories) and writes the given content to it."""
    lines = content.strip().split('\n')
    filtered_lines = [line for line in lines if not line.lower().startswith("```")]
    content_filtered = "\n".join(filtered_lines)
    
    try:
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        with open(filepath, 'w') as f:
            f.write(content_filtered)
        print(f"File '{filepath}' created and the following content was written:\n'{content_filtered}'")
    except Exception as e:
        print(f"An error occurred while creating or writing to the file: {e}")

def Understand(config, user_request):
  mind = ai.AI.Get()
  template = ai.GetPromptTemplate(config)
  json_str = mind(template.replace('__USER_REQUEST__', user_request))
  try:
    json_obj = json.loads(json_str)
    print(json_obj)
  except Exception as e:
    print('Failed parsing:', json_str)
    raise e
  return json_obj


def JsonConfigFromLogicLMPredicate(config_filename):
  def RunPredicate(predicate):
    return logica_lib.RunPredicateToPandas(config_filename, predicate)
  config = RunPredicate('LogicLM').iloc[0].to_dict()
  engine = RunPredicate('@Engine')['col0'][0]
  rules = parse.ParseFile(open(config_filename).read())['rule']
  types = infer.TypesInferenceEngine(rules, 'duckdb')
  types.InferTypes()
  fact_tables = config['fact_tables']
  if isinstance(fact_tables,str):
    fact_tables = json.loads(fact_tables)
  config['fact_tables'] = [{'fact_table': f} for f in fact_tables]
  fact_tables_of_measures={}
  if 'fact_tables_of_measures' in config:
    if isinstance(config['fact_tables_of_measures'],str):
      config['fact_tables_of_measures'] = json.loads(config['fact_tables_of_measures'])
    for f in config['fact_tables_of_measures']:
      fact_tables_of_measures[f['arg']]=f['value']
  def Params(p):
    if p not in types.predicate_signature:
      assert False, 'Unknown predicate %s, known: %s' % (
          p, '\n'.join(types.predicate_signature.keys()))
    return [{'field_name': f}
            for f in types.predicate_signature[p].keys()
            if not isinstance(f, int) and f != 'logica_value']
  def BuildCalls(role, field,fact_table={}):
    field_content=config[field]
    if isinstance(field_content,str):
      field_content=json.loads(field_content)
    output=[{role: {'predicate_name': p,
                    'parameters': Params(p)}}
            for p in field_content]
    if fact_table=={}:
      return output
    for o in output:
      if o[role]['predicate_name'] in fact_table:
        o['fact_table']=fact_table[o[role]['predicate_name']]
    return output

  config['dimensions'] = BuildCalls('function', 'dimensions')
  config['measures'] = BuildCalls('aggregating_function', 'measures',fact_tables_of_measures)
  if 'filters' in config:
    config['filters'] = BuildCalls('predicate', 'filters')
  chart_types = [
      "PieChart", "LineChart", "BarChart", "StackedBarChart", "Table",
      "TotalsCard", "VennDiagram", "GeoMap", "QueryOnly"
  ]
  chart_data = [{"predicate": {"predicate_name": chart, "parameters": []}}
                for chart in chart_types]
  if 'suffix_lines' in config:
    config['suffix_lines'] = list(config['suffix_lines'])
  config['chart_types'] = chart_data
  config['logica_program'] = config_filename
  if 'dashboard' not in config:
    config['dashboard'] = []
  config['dialect'] = engine
  return config



def read_csv_to_string_with_encoding_fix(file_path):
    """
    Reads a CSV file from a given path and returns its content as a single string,
    attempting different encodings if utf-8 fails.

    Args:
        file_path (str): The path to the CSV file.

    Returns:
        str: The entire content of the CSV file as a string,
             or None if the file cannot be read with common encodings.
    """
    encodings_to_try = ['utf-8', 'latin-1', 'cp1252'] # Add more if needed

    for encoding in encodings_to_try:
        try:
            with open(file_path, 'r', newline='', encoding=encoding) as file:
                content = file.read()
            return content
        except UnicodeDecodeError as e:
            #print(f"Failed to read with {encoding}: {e}")
            continue # Try the next encoding
        except FileNotFoundError:
            #print(f"Error: The file at '{file_path}' was not found.")
            return None
        except Exception as e:
            #print(f"An unexpected error occurred: {e}")
            return None
    print("Could not read the file with any of the attempted encodings.")
    return None


def getSQLite(db_name):
  path = f"{_DATABASE_FILE_NAME}{db_name}/"
  for item in os.listdir(path):
    item_path = os.path.join(path, item)
    if os.path.isfile(item_path) and ".sqlite" in item_path:
      return item_path
def getSchema(db_name):
    schema=""
    path = f"{_DATABASE_FILE_NAME}{db_name}/database_description/"
    
    for item in os.listdir(path):
        item_path = os.path.join(path, item)
        if os.path.isfile(item_path) and ".csv" in item_path and ".sqlite" not in item_path:
            content = read_csv_to_string_with_encoding_fix(item_path)
            table_name = item.replace(".csv","")
            schema+=f"Schema for Table {table_name} \n " + content
            schema+="\n"
    return schema

def getTableNames(db_name):
    table_names=[]
    path = f"{_DATABASE_FILE_NAME}{db_name}/database_description/"
    
    for item in os.listdir(path):
        item_path = os.path.join(path, item)
        if os.path.isfile(item_path) and ".csv" in item_path and ".sqlite" not in item_path:
            content = read_csv_to_string_with_encoding_fix(item_path)
            table_name = item.replace(".csv","")
            table_names.append(table_name)
    return table_names
 
      

def runQueries(str_query="Select * from continents;",db_name="car_1",debug=False):
  #str_query="select * from yearmonth limit 20;"
  #db_name="debit_card_specializing"
  if str_query.lower().startswith("select")==False:
    index=str_query.lower().find("with")
    str_query =str_query[index:]
  sqlite_file_name = getSQLite(db_name)
  if debug:
    print("The query which is going to run ....................................................: ", str_query)
  df = run_sql_db.run_query_sqlite(sqlite_file_name,str_query)
  if debug:
    print(df)
  return df

def lowercase_quotes(match):
    return f'"{match.group(1).lower()}"'
def lowercase_inside_parentheses(match):
      content = match.group(1)
      tokens = content.split(',')
      transformed = []
      for token in tokens:
          stripped = token.strip()
          # If token contains a space, skip lowering
          if ' ' in stripped:
              transformed.append(stripped)
          else:
              transformed.append(stripped.lower())
      return f"({', '.join(transformed)})"

def GetQuestions(db_name):
  mind = ai.GoogleGenAI.Get()
  db_question_name = _QUESTION_FILE_NAME
  sql_file_name = getSchema(db_name)
  yodaql_file_name = "logica_description.txt"

  example_yodaql_config_file_name1 = "examples/car_1/car_1_new.l"
  example_yodaql_config_file_name2 = "examples/concert_singer/concert_singer_new.l"
  example_yodaql_config_file_name3 = "examples/poker_player/poker_player_new.l"
  with open(example_yodaql_config_file_name1) as f:
      example_yodaql_config1 = f.read()
  with open(example_yodaql_config_file_name2) as f:
      example_yodaql_config2 = f.read()
  with open(example_yodaql_config_file_name3) as f:
      example_yodaql_config3 = f.read()
  with open(sql_file_name) as f:
      sql_schema = f.read()
      converted_schema = cleanup_schema(sql_schema)
  with open(yodaql_file_name) as f:
      yodaql_info = f.read()
  questions=[]
  with open(db_question_name) as f:
      config = json.loads(f.read())
  for test_case in config:
    if test_case["db_id"]==db_name:
      questions.append(test_case["question"])
  try:
    mind.CreateNewChat()
    step1=mind.sendPrompt(f"Please Understand this Yodaql Info: {yodaql_info}")
    print("Yodaql Info Step Done")
    time.sleep(20)
    print(step1[:100])
    step2=mind.sendPrompt(f"Please Understand this Input Schema: {converted_schema}")
    print("Input Schema Step Done")
    time.sleep(20)
    print(step2[:100])
    step3=mind.sendPrompt(f"Please Understand this Questions : {','.join(questions)}")
    print("Questions  Step Done")
    time.sleep(20)
    print(step3[:100])
    step4=mind.sendPrompt(f"Please Understand this Example Yodaql Config 1 : {example_yodaql_config1}")
    print("Example Yodaql Config 1 Step Done")
    time.sleep(20)
    print(step4[:100])
    step4=mind.sendPrompt(f"Please Understand this Example Yodaql Config 2 : {example_yodaql_config2}")
    print("Example Yodaql Config 2 Step Done")
    time.sleep(20)
    print(step4[:100])
    step4=mind.sendPrompt(f"Please Understand this Example Yodaql Config 3 : {example_yodaql_config3}")
    print("Example Yodaql Config 3 Step Done")
    time.sleep(20)
    print(step4[:100])
    new_config=mind.sendPrompt("Please provide a yodaql config for Input Schema which answers the questions. Please do not include any hashtags or comments.",30000)
    create_and_write_file(f"examples/{db_name}/{db_name}_new.l",new_config)
    print("Yodaql Config")
  except:
    print("Did not run config creation.")


def GetLogicLMConfig(db_name):
  mind = ai.GoogleGenAI.Get()
  prompt=getLogicLMTemplate(db_name)
  try:
    logiclm_answer = mind.CreateLogicProgram(prompt)
    create_and_write_file(f"examples/{db_name}/{db_name}_recent.l",logiclm_answer)
  except BaseException as e:
    print("Did not run config creation.",e)


def getLogicTemplate(db_name,question_evidence,extra_snip):
  converted_schema = getSchema(db_name)
  question,evidence = question_evidence
  logic_description_file = "logica_description.txt"
  example_logic_program_file = "examples/logic_program/logic_bird_prompt.txt"

  with open(example_logic_program_file) as f:
      example_logic_program = f.read()
  with open(logic_description_file) as f:
      logic_info = f.read()
  prompt=example_logic_program.replace("_SCHEMA_",converted_schema)
  if evidence=="":
    prompt=prompt.replace("This is some information about the question - _EVIDENCE_","")
  else:
    prompt=prompt.replace("_EVIDENCE_",evidence)
  prompt.replace("_DATA_",extra_snip)
  prompt=prompt.replace("_QUESTION_",question)
  prompt=prompt.replace("_LOGIC_INFO",logic_info)
  return prompt

def getLogicLMTemplate(db_name):
  sql_file_name = getSchema(db_name)
  db_question_name = _QUESTION_FILE_NAME
  example_yodaql_config_file_name1 = "examples/car_1/car_1_new.l"
  example_yodaql_config_file_name2 = "examples/concert_singer/concert_singer_new.l"
  example_yodaql_config_file_name3 = "examples/poker_player/poker_player_new.l"
  with open(example_yodaql_config_file_name1) as f:
      example_yodaql_config1 = f.read()
  with open(example_yodaql_config_file_name2) as f:
      example_yodaql_config2 = f.read()
  with open(example_yodaql_config_file_name3) as f:
      example_yodaql_config3 = f.read()
  with open(sql_file_name) as f:
      sql_schema = f.read()
      converted_schema = cleanup_schema(sql_schema)
  questions=[]
  with open(db_question_name) as f:
      config = json.loads(f.read())
  for test_case in config:
    if test_case["db_id"]==db_name:
      questions.append(test_case["question"])
  logic_description_file = "logica_description.txt"
  example_logic_program_file = "examples/logic_program/logiclm_config_prompt.txt"
  with open(example_logic_program_file) as f:
      example_logic_program = f.read()
  with open(logic_description_file) as f:
      logic_info = f.read()
  prompt=example_logic_program.replace("_LOGIC_INFO",logic_info)
  prompt=prompt.replace("_SCHEMA_",converted_schema)
  prompt=prompt.replace("_QUESTIONS_",'\n'.join(questions))
  prompt=prompt.replace("_EXAMPLE_1",example_yodaql_config_file_name1)
  prompt=prompt.replace("_EXAMPLE_2",example_yodaql_config_file_name2)
  prompt=prompt.replace("_EXAMPLE_3",example_yodaql_config_file_name3)
  return prompt

  
def GetLogicProgram(db_name,question_evidence,extra_snip=""):
  mind = ai.GoogleGenAI.Get()
  prompt = getLogicTemplate(db_name,question_evidence,extra_snip)
  question,evidence = question_evidence
  cached_logicas=CachingLogicas()
  try:
    if db_name+question not in cached_logicas:
      logic_answer = mind.CreateLogicProgram(prompt)
      logic_answer = cleanup_content(logic_answer)
    else:
      print("Got from Cache")
      logic_answer=cached_logicas[db_name+question]
    print("LOGIC PROGRAM: ",logic_answer,"\n")
    sql=GetSQL(logic_answer)
    print("GENERATED SQL: ",sql.replace('\n', ''),"\n")
    answer=runQueries(sql,db_name,False)
    return "success",answer,sql,logic_answer
  except parse.ParsingException as e:
    print("Parsing Error is: ", e.ShowMessage())
    return "error",e.ShowMessage(),None,None
  except BaseException as e:
    print("Error is: ", e)
    print("--- Full Traceback ---")
    traceback.print_exc()
    print("----------------------")
    return "error",e,None,None

def GetLogicPrograms(db_name,first_n=10):
  db_question_name = _QUESTION_FILE_NAME
  questions=[]
  golden_queries=[]
  errors=[]
  answers=[]
  actual_query=[]
  generated_query=[]
  with open(db_question_name) as f:
      config = json.loads(f.read())
  for test_case in config:
    if test_case["db_id"]==db_name:
      questions.append(test_case["question"])
      golden_queries.append(test_case["query"])
  for indx in range(min(len(questions),first_n)):
    print("QUESTION------------------------------->: ", questions[indx],"\n")
    status,output,generated_query = GetLogicProgram(db_name,questions[indx])
    if status=="error":
      errors.append([db_name,questions[indx],output])
      continue
    print("ACTUAL SQL: ",golden_queries[indx],"\n")
    answer=runQueries(golden_queries[indx],db_name)
    answers.append([db_name,questions[indx],answer.to_string().replace('\n', ''),output.to_string().replace('\n', ''),len(answer),len(output)])
    actual_query.append(golden_queries[indx].replace("\n"," "))
    generated_query.append(generated_query.replace("\n"," "))
    
  answers_df=pd.DataFrame(answers,columns=["db_name","Question","Actual Output","Logical Output","Actual Len","Logical Len"])
  errors_df=pd.DataFrame(errors,columns=["db_name","Question","Error"])
  answers_df.to_csv("logic_answers.txt", index=False)
  errors_df.to_csv("logic_errors.txt", index=False)
  print(f"Coverage: {len(answers)/(len(answers)+len(errors))}")
  print(f"Number of Rows Matching on Running Queries: {len(answers_df[answers_df["Actual Len"]==answers_df["Logical Len"]])/len(answers)}")

def CachingLogicas():
  answer_path = _LOGICA_ANSWERS_OUTPUT 
  with open(answer_path, 'r') as file:
        answers_df_loaded = json.load(file)
  dic1={}
  for i in answers_df_loaded:
    dic1[i[0]+i[1]]=i[3]
  return dic1

def QueryTables(db_name):
  table_names = getTableNames(db_name)
  snippet=[]
  for table_name in table_names:
    query=f"Select * from {table_name} LIMIT 20;"    
    try :
      df=runQueries(str_query=query,db_name=db_name)
      snippet.append(f"This is the snippet for table : {table_name} \n Data: {df.to_json()}\n")
    except:
      print("Cannot query:",db_name,table_name)
  return "\n".join(snippet)



def GetAllLogicProgram():
  db_question_name = _QUESTION_FILE_NAME
  questions=collections.defaultdict(list)
  golden_queries=collections.defaultdict(list)
  errors=[]
  answers=[]
  actual_query=[]
  generated_query_list=[]
  snip={}
  with open(db_question_name) as f:
      config = json.loads(f.read())
    #edit here
  for test_case in config:
    if getSchema(test_case["db_id"]):
      questions[test_case["db_id"]].append([test_case["question"],test_case["evidence"]])
      golden_queries[test_case["db_id"]].append(test_case["SQL"])
    
  for db_name in questions:
    snip[db_name]=QueryTables(db_name)

  for db_name in questions:
    golden_query=golden_queries[db_name]
    question_list=questions[db_name]

    for indx in range(len(question_list)):
      print("QUESTION------------------------------->: ", db_name,question_list[indx],"\n")
      status,output,generated_query,logic_answer = GetLogicProgram(db_name,question_list[indx],snip[db_name])
      if status=="error":
        errors.append([db_name,question_list[indx],output])
        continue
      print("ACTUAL SQL: ",golden_query[indx],"\n")
      answer=runQueries(golden_query[indx],db_name)
      try:
        answers.append([db_name,question_list[indx][0],question_list[indx][1],logic_answer,golden_query[indx].replace("\n"," "),generated_query.replace("\n"," "),answer.to_json(),output.to_json()])
        actual_query.append(golden_query[indx].replace("\n"," ")+"\t----- bird -----\t"+db_name)
        generated_query_list.append(generated_query.replace("\n"," ")+"\t----- bird -----\t"+db_name) 
      except  BaseException as e:
        print(f"An error occurred while appending to list: {e}")

  file_path = _LOGICA_ANSWERS_OUTPUT 
  file_path_clean = _LOGICA_ANSWERS_OUTPUT_CLEANED
  try:
      with open(file_path, 'w') as f:
          json.dump(answers, f, indent=4)  # Use indent for pretty printing (optional)
      print(f"JSON data successfully written to: {file_path}")
      cleaned_answers=[]
      for a in answers:
        ele_dic={}
        for indx,key in enumerate(["Database Name","Question","Evidence","Logica Program","Golden Query","Logica Query","Golden Output","Logica Output"]):
              ele_dic[key]=a[indx]
        cleaned_answers.append(ele_dic)
      with open(file_path_clean, 'w') as f:
          json.dump(cleaned_answers, f, indent=4)  # Use indent for pretty printing (optional)
      print(f"JSON data successfully written to: {file_path}")
  except Exception as e:
      print(f"An error occurred while writing to the file: {e}")
  errors_df=pd.DataFrame(errors,columns=["db_name","Question","Error"])
  errors_df.to_csv("logic_errors_new.txt", index=False)
  write_list_to_file(actual_query,_LOGICA_ACTUAL_QUERIES)
  write_list_to_file(generated_query_list,_LOGICA_GENERATED_QUERIES)
  print(f"Coverage: {len(answers)/(len(answers)+len(errors))}")


def GetResults():
  db_question_name = _QUESTION_FILE_NAME
  actual_query=[]
  generated_query_dic={}
  with open(db_question_name) as f:
      config = json.loads(f.read())
  cached_logicas=CachingLogicas()
  
  for test_case in config:
    db_name=test_case["db_id"]
    question = test_case["question"]
    question_id=test_case["question_id"]
    print(question_id)
    actual_query.append(test_case["SQL"].replace("\n"," ")+"\t"+db_name)
    
    if db_name+question not in cached_logicas:
      generated_query_dic[question_id] = 0
    else:
      logic_answer=cached_logicas[db_name+question]
      sql=GetSQL(logic_answer)
      generated_query_dic[question_id]=sql.replace("\n"," ")+"\t----- bird -----\t"+db_name

  
  with open(_COMPARE_OUTPUT, 'w') as f:
          json.dump(generated_query_dic, f, indent=4)  # Use indent for pretty printing (optional)
  print(f"JSON data successfully written to: {_COMPARE_OUTPUT}")
  write_list_to_file(actual_query,_GOLDEN_SQL)
  



  
  




def GetSQL(logic_program):
  rules = parse.ParseFile(logic_program)['rule']
  logic_program = universe.LogicaProgram(rules)
  sql = logic_program.FormattedPredicateSql('Report')
  return sql

def GetQuestion():
  folders=[]
  questions=collections.defaultdict(list)
  db_question_name = _QUESTION_FILE_NAME
  with open(db_question_name) as f:
      config = json.loads(f.read())
  for test_case in config:
    if test_case["db_id"]:
      questions[test_case["db_id"]].append(test_case["question"])
  for db_name in list(questions.keys()):
    try:
        if getSchema(db_name) and getSQLite(db_name):
          folders.append(db_name)
    except:
        continue
  for db_name in folders:
    print(folders)
    file_path = f"examples/{db_name}/{db_name}_recent.l"
    print(file_path)
    if os.path.exists(file_path):
      print("skipped for:", db_name)
    else:
      GetLogicLMConfig(db_name)

def write_list_of_lists_to_file(data, filename):
    """Writes a list of lists to a text file.

    Each inner list will be written as a comma-separated line in the file.

    Args:
        data: A list of lists to be written to the file.
        filename: The name of the file to create or overwrite.
    """
    try:
        with open(filename, 'w') as outfile:
            for inner_list in data:
                # Convert each element in the inner list to a string
                string_elements = [str(item) for item in inner_list]
                # Join the string elements with a comma and write to the file
                line = ','.join(string_elements) + '\n'
                outfile.write(line)
        print(f"List of lists successfully written to '{filename}'")
    except Exception as e:
        print(f"An error occurred while writing to the file: {e}")






  
 
def main(argv):
  config_filename = argv[1]

  if config_filename=="get_results":
    GetResults()
    return

  if config_filename=="get_logic_program":
    if len(argv)==2:
      GetAllLogicProgram()
    elif len(argv)>3:
      GetLogicProgram(argv[2],argv[3])
    else:
      GetLogicPrograms(argv[2])
    return

  if config_filename == "run_query":
    print(argv)
    if len(argv)>=3:
      runQueries(argv[2],argv[3],True)
    else:
      runQueries()
    return
  
  if config_filename =="get_questions":
    if len(argv)>=3:
      GetQuestions(argv[2])
    else:
      GetQuestion()
    return
  command = argv[2]

  


  if config_filename[-4:] == 'json':
    with open(config_filename) as f:
      config = json.loads(f.read())
  else:
    config = JsonConfigFromLogicLMPredicate(config_filename)

  if command == 'understand':
    user_request = argv[3]
    print(Understand(config, user_request))
  elif command == 'logic_program':
    request = json.loads(argv[3])
    analyzer = olap.Olap(config, request)
    print(analyzer.GetLogicProgram())
  elif command == 'sql':
    request = json.loads(argv[3])
    analyzer = olap.Olap(config, request)
    print(analyzer.GetSQL())
  elif command == 'show_prompt':
    print(ai.GetPromptTemplate(config))
  elif command == 'understand_and_program':
    user_request = argv[3]
    request = Understand(config, user_request)
    analyzer = olap.Olap(config, request)
    print(analyzer.GetLogicProgram())
  elif command == 'understand_and_sql':
    user_request = argv[3]
    request = Understand(config, user_request)
    analyzer = olap.Olap(config, request)
    try:
      print(analyzer.GetSQL())
    except parse.ParsingException as parsing_exception:
      parsing_exception.ShowMessage()
      sys.exit(1)
  elif command == 'understand_sql_run':
    user_request = argv[3]
    request = Understand(config, user_request)
    analyzer = olap.Olap(config, request)
    try:
      if len(argv)>=5:
        runQueries(analyzer.GetSQL(),argv[4],True)
      else:
        runQueries(analyzer.GetSQL())
    except parse.ParsingException as parsing_exception:
      parsing_exception.ShowMessage()
      sys.exit(1)
  elif command == 'start_server':
    server.StartServer(config)
  elif command == 'remove_dashboard_from_config':
    config['dashboard'] = {}
    print(json.dumps(config, indent='  '))
  else:
    assert False


if __name__ == '__main__':
  main(sys.argv)


