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


from logica.common import logica_lib
from logica.type_inference.research import infer
from logica.parser_py import parse
import run_sql_db
import collections
from logica.compiler import universe


def cleanup_content(content):
    lines = content.strip().split('\n')
    filtered_lines = [line for line in lines if not line.lower().startswith("```")]
    content_filtered = "\n".join(filtered_lines)
    return content_filtered

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
    # Skipping ordering
    json_obj["order"] = []
    print("HI I AM HERE")
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

def getSQLite(db_name):
  path = f"spider_data/database/{db_name}/"
  for item in os.listdir(path):
    item_path = os.path.join(path, item)
    if os.path.isfile(item_path) and ".sqlite" in item_path:
      return item_path
def getSchema(db_name):
  path = f"spider_data/database/{db_name}/"
  for item in os.listdir(path):
    item_path = os.path.join(path, item)
    if os.path.isfile(item_path) and ".sql" in item_path and ".sqlite" not in item_path:
      return item_path
      

def runQueries(str_query="Select * from continents;",db_name="car_1",debug=False):
  if str_query.lower().startswith("select")==False:
    index=str_query.lower().find("with")
    str_query =str_query[index:]
  sql_file_name = getSchema(db_name)
  sqlite_file_name = getSQLite(db_name)
  if debug:
    print("The query which is going to run ....................................................: ", str_query)
  df = run_sql_db.run_query(sqlite_file_name,sql_file_name,str_query)
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
  db_question_name = "spider_data/dev.json"
  sql_file_name = getSchema(db_name)
  print(sql_file_name)
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
      lines = sql_schema.strip().split('\n')
      filtered_lines = [line for line in lines if not line.lower().startswith("insert into")]
      sql_schema = "\n".join(filtered_lines)
      sql_schema = re.sub(r'\(([^;]+?)\)', lowercase_inside_parentheses, sql_schema, flags=re.DOTALL)
      converted_schema = re.sub(r'"([^"]+)"', lowercase_quotes, sql_schema)
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

def getLogicTemplate(db_name,question):
  sql_file_name = getSchema(db_name)
  logic_description_file = "logica_description.txt"
  example_logic_program_file = "examples/logic_program/logic_program.txt"
  with open(sql_file_name) as f:
    sql_schema = f.read()
    lines = sql_schema.strip().split('\n')
    filtered_lines = [line for line in lines if not line.lower().startswith("insert into")]
    sql_schema = "\n".join(filtered_lines)
    sql_schema = re.sub(r'\(([^;]+?)\)', lowercase_inside_parentheses, sql_schema, flags=re.DOTALL)
    converted_schema = re.sub(r'"([^"]+)"', lowercase_quotes, sql_schema)
    converted_schema = re.sub(r'\n\s*\n', '\n', converted_schema)
  with open(example_logic_program_file) as f:
      example_logic_program = f.read()
  with open(logic_description_file) as f:
      logic_info = f.read()
  prompt=example_logic_program.replace("_LOGIC_INFO",logic_info)
  prompt=prompt.replace("_SCHEMA_",converted_schema)
  prompt=prompt.replace("_QUESTION_",question)
  return prompt

  


def GetLogicProgram(db_name,question):
  mind = ai.GoogleGenAI.Get()
  prompt = getLogicTemplate(db_name,question)
  try:
    logic_answer = mind.CreateLogicProgram(prompt)
    logic_answer = cleanup_content(logic_answer)
    print("LOGIC PROGRAM: ",logic_answer,"\n")
    sql=GetSQL(logic_answer)
    print("GENERATED SQL: ",sql.replace('\n', ''),"\n")
    answer=runQueries(sql,db_name,False)
    return "success",answer
  except parse.ParsingException as e:
    print("Parsing Error is: ", e.ShowMessage())
    return "error",e.ShowMessage()
  except BaseException as e:
    print("Error is: ", e)
    return "error",e

def GetLogicPrograms(db_name,first_n=10):
  db_question_name = "spider_data/dev.json"
  questions=[]
  golden_queries=[]
  errors=[]
  answers=[]
  with open(db_question_name) as f:
      config = json.loads(f.read())
  for test_case in config:
    if test_case["db_id"]==db_name:
      questions.append(test_case["question"])
      golden_queries.append(test_case["query"])
  for indx in range(min(len(questions),first_n)):
    print("QUESTION------------------------------->: ", questions[indx],"\n")
    status,output = GetLogicProgram(db_name,questions[indx])
    if status=="error":
      errors.append([db_name,questions[indx],output])
      continue
    print("ACTUAL SQL: ",golden_queries[indx],"\n")
    answer=runQueries(golden_queries[indx],db_name)
    answers.append([db_name,questions[indx],answer.to_string().replace('\n', ''),output.to_string().replace('\n', ''),len(answer),len(output)])
  answers_df=pd.DataFrame(answers,columns=["db_name","Question","Actual Output","Logical Output","Actual Len","Logical Len"])
  errors_df=pd.DataFrame(errors,columns=["db_name","Question","Error"])
  answers_df.to_csv("logic_answers.txt", index=False)
  errors_df.to_csv("logic_errors.txt", index=False)
  print(f"Coverage: {len(answers)/(len(answers)+len(errors))}")
  print(f"Number of Rows Matching on Running Queries: {len(answers_df[answers_df["Actual Len"]==answers_df["Logical Len"]])/len(answers)}")




def GetSQL(logic_program):
  rules = parse.ParseFile(logic_program)['rule']
  logic_program = universe.LogicaProgram(rules)
  sql = logic_program.FormattedPredicateSql('Report')
  return sql

def GetQuestion():
  folders=[]
  questions=collections.defaultdict(list)
  db_question_name = "spider_data/dev.json"
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
    file_path = f"examples/{db_name}/{db_name}_new.l"
    print(file_path)
    if os.path.exists(file_path):
      print("skipped for:", db_name)
    else:
      GetQuestions(db_name)

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

def Testing():
  questions=collections.defaultdict(list)
  sql_queries=collections.defaultdict(list)
  db_question_name = "spider_data/dev.json"
  answers=[]
  errors=[]
  delete_configs=[]
  with open(db_question_name) as f:
      config = json.loads(f.read())
  for test_case in config:
    if test_case["db_id"]:
      questions[test_case["db_id"]].append(test_case["question"])
      sql_queries[test_case["db_id"]].append(test_case["query"])
  testing_done=0
  for db_name in questions:
    file_path = f"examples/{db_name}/{db_name}_new.l"
    if os.path.exists(file_path)==False:
      print("Skipping for db_name:",db_name)
      continue
    with open(file_path) as f:
      config_output = f.read().lower()
    if "logiclm" not in config_output:
      print("LOGIC LM not in: ", file_path)
      delete_configs.append(db_name)
      continue

    try:
      print("Will do testing for db_name:",db_name)
      print(questions[db_name][0])
      print(sql_queries[db_name][0])
      print(runQueries(sql_queries[db_name][0],db_name))
      config=JsonConfigFromLogicLMPredicate(file_path)
      request = Understand(config,questions[db_name][0] )
      analyzer = olap.Olap(config, request)
      print(runQueries(analyzer.GetSQL(),db_name))
      testing_done+=1
      for indx,question in enumerate(questions[db_name]):
        try:
          answer=[]
          answer.append(db_name)
          answer.append(question)
          actual_df=runQueries(sql_queries[db_name][indx],db_name)

          answer.append(actual_df.to_string().replace('\n', ''))
          request = Understand(config,question )
          analyzer = olap.Olap(config, request)

          tested_df=runQueries(analyzer.GetSQL(),db_name)

          answer.append(tested_df.to_string().replace('\n', ''))

          answer.append(len(actual_df))
          answer.append(len(tested_df))
          answers.append(answer)
        except BaseException as e:
          errors.append([db_name,question,e])
          print(e)
          print(f"We failed this question ->{question} for db_name: {db_name}")
    except BaseException as e:
      print("Could no do testing for:", db_name)
      delete_configs.append(db_name)
      print(f"An error occurred: {e}")
  print("Delete Configs: ",delete_configs)
  answers_df=pd.DataFrame(answers,columns=["db_name","Question","Actual Output","Logical Output","Actual Len","Logical Len"])
  errors_df=pd.DataFrame(errors,columns=["db_name","Question","Error"])
  answers_df.to_csv("running_queries2.txt", index=False)
  errors_df.to_csv("errors2.txt", index=False)
  print(f"Errors Number : {len(errors_df)}")
  print("We did testing for: ", testing_done)
  print("Number of rows correct:",len(answers_df[answers_df["Actual Len"]==answers_df["Logical Len"]]))
  





  
 
def main(argv):
  config_filename = argv[1]

  if config_filename=="testing":
    Testing()
    return
  if config_filename=="get_logic_program":
    if len(argv)>3:
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