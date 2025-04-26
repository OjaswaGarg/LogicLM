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


from logica.common import logica_lib
from logica.type_inference.research import infer
from logica.parser_py import parse
import run_sql_db


def Understand(config, user_request):
  mind = ai.AI.Get()
  template = ai.GetPromptTemplate(config)
  json_str = mind(template.replace('__USER_REQUEST__', user_request))
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



def runQueries():
  sql_file_name = "spider_data/database/car_1/car_1.sql"
  sqlite_file_name = "spider_data/database/car_1/car_1.sqlite"
  run_sql_db.trying(sqlite_file_name,sql_file_name,"Select * from continents;")
  return
def GetQuestions(db_name):
  mind = ai.GoogleGenAI.Get()
  db_question_name = "spider_data/dev.json"
  sql_file_name = "spider_data/database/car_1/car_1.sql"
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


  example_yodaql_config_file_name = "examples/starfleet/starfleet.l"
  with open(example_yodaql_config_file_name) as f:
      example_yodaql_config = f.read()
  with open(sql_file_name) as f:
      sql_schema = f.read()
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
  questions =questions[:10]
  mind.CreateNewChat()
  mind.sendPrompt(f"Yodaql Info: {yodaql_info}")
  print("First Step Done")
  time.sleep(10)
  mind.sendPrompt(f"Input Schema: {converted_schema}")
  print("Second Step Done")
  time.sleep(10)
  mind.sendPrompt(f"Questions : {','.join(questions)}")
  print("Third Step Done")
  time.sleep(10)
  mind.sendPrompt(f"Example Yodaql Config : {example_yodaql_config}")
  print("Fourth Step Done")
  time.sleep(10)
  print(mind.sendPrompt("Provide a yodaql config for Input Schema which answers the questions."))
 
def main(argv):
  config_filename = argv[1]
  command = argv[2]
  if config_filename[-4:] == 'json':
    with open(config_filename) as f:
      config = json.loads(f.read())
  else:
    config = JsonConfigFromLogicLMPredicate(config_filename)

  if command == 'understand':
    user_request = argv[3]
    print(Understand(config, user_request))
  elif command =="get_questions":
    db_name = argv[3]
    GetQuestions(db_name)
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
  elif command == 'start_server':
    server.StartServer(config)
  elif command == 'remove_dashboard_from_config':
    config['dashboard'] = {}
    print(json.dumps(config, indent='  '))
  else:
    assert False


if __name__ == '__main__':
  main(sys.argv)