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
import os


from logica.common import logica_lib
from logica.type_inference.research import infer
from logica.parser_py import parse
import run_sql_db


def create_and_write_file(filepath, content):
    """Creates a file at the specified filepath (including parent directories) and writes the given content to it."""
    try:
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"File '{filepath}' created and the following content was written:\n'{content}'")
    except Exception as e:
        print(f"An error occurred while creating or writing to the file: {e}")

def Understand(config, user_request):
  mind = ai.AI.Get()
  template = ai.GetPromptTemplate(config)
  try:
    json_str = mind(template.replace('__USER_REQUEST__', user_request))
  except:
    print("Failed to get Logic in Understand")
  print("This is me:",json_str)
  try:
    json_obj = json.loads(json_str)
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
  print(config)
  config['fact_tables'] = [{'fact_table': f} for f in config['fact_tables']]
  def Params(p):
    if p not in types.predicate_signature:
      assert False, 'Unknown predicate %s, known: %s' % (
          p, '\n'.join(types.predicate_signature.keys()))
    return [{'field_name': f}
            for f in types.predicate_signature[p].keys()
            if not isinstance(f, int) and f != 'logica_value']
  def BuildCalls(role, field):
    return [{role: {'predicate_name': p,
                    'parameters': Params(p)}}
            for p in config[field]]

  config['dimensions'] = BuildCalls('function', 'dimensions')
  config['measures'] = BuildCalls('aggregating_function', 'measures')
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
      

def runQueries(str_query="Select * from continents;",db_name="car_1"):
  print(str_query)
  if str_query.startswith("Select")==False:
    index=str_query.find("WITH")
    str_query =str_query[index:]
  print(str_query)
  sql_file_name = getSchema(db_name)
  sqlite_file_name = getSQLite(db_name)
  print(sql_file_name,sqlite_file_name)
  print("The query which is going to run ....................................................: ", str_query)
  run_sql_db.run_query(sqlite_file_name,sql_file_name,str_query)
  return
  


def GetQuestions(db_name):
  mind = ai.GoogleGenAI.Get()
  db_question_name = "spider_data/dev.json"
  sql_file_name = getSchema(db_name)
  print(sql_file_name)
  yodaql_file_name = "logica_description.txt"
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

  example_yodaql_config_file_name = "examples/car_1/car_final.l"
  with open(example_yodaql_config_file_name) as f:
      example_yodaql_config = f.read()
  with open(sql_file_name) as f:
      sql_schema = f.read()
      lines = sql_schema.strip().split('\n')
      filtered_lines = [line for line in lines if not line.lower().startswith("insert into")]
      sql_schema = "\n".join(filtered_lines)
      sql_schema = re.sub(r'\(([^;]+?)\)', lowercase_inside_parentheses, sql_schema, flags=re.DOTALL)
      converted_schema = re.sub(r'"([^"]+)"', lowercase_quotes, sql_schema)
  print(converted_schema)
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
    step4=mind.sendPrompt(f"Please Understand this Example Yodaql Config : {example_yodaql_config}")
    print("Example Yodaql Config Step Done")
    time.sleep(20)
    print(step4[:100])
    new_config=mind.sendPrompt("Please provide a yodaql config for Input Schema which answers the questions. Please do not include any hashtags or comments.",30000)
    print(new_config)
    create_and_write_file(f"examples/{db_name}/{db_name}_new.l",new_config)
    print("Yodaql Config")
  except:
    print("Did not run config creation.")

def GetQuestion():
  folders=[]
  path = f"spider_data/database//"
  for item in os.listdir(path):
    item_path = os.path.join(path, item)
    if os.path.isdir(item_path):
      folders.append(item)
  for db_name in folders[:5]:
    GetQuestions(db_name)


  
 
def main(argv):
  config_filename = argv[1]

  if config_filename == "run_query":
    print(argv)
    if len(argv)>=3:
      runQueries(argv[2],argv[3])
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
        runQueries(analyzer.GetSQL(),argv[4])
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