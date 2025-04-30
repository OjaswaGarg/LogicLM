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

import os
import sys

try:
  import google.generativeai as genai
  from vertexai import generative_models
except:
  pass

try:
  import openai
except:
  pass

try:
  import mistralai
  from mistralai import client as mistral_client
except:
  pass

class AI:
  def __init__(self, api_key=None):
    self.api_key = api_key

  def SetAPIKey(self, api_key):
    self.api_key = api_key

  def __call__(self, prompt):
    raise NotImplementedError

  def InitFromSystemVariable(self):
    key = self.SystemAPIKey()
    assert key, 'Can not initialize %s as system does not have a key.' % self
    self.SetAPIKey(key)

  @classmethod
  def SystemAPIKey(cls):
    return os.getenv(cls.api_key_system_variable)

  @classmethod
  def Options(cls):
    yield GoogleGenAI
    yield OpenAI
    yield MistralAI

  @classmethod
  def Get(cls):
    system_vars = []
    for option in cls.Options():
      key = option.SystemAPIKey()
      system_vars.append(option.api_key_system_variable)
      if key:
        return option(key)
    assert False, 'Can not initialize AI. None of the AI API keys were set: %s' % system_vars
  
  def CutOffChatter(self, response):
    useful_start = response.index('{')
    useful_end = response.rfind('}') + 1
    useful_response = response[useful_start:useful_end]
    if response != useful_response:
      print('Cutting of chatter from:', response)
      print('Obtaining:', useful_response)
    return useful_response


class GoogleGenAI(AI):
    configured_api_key = None
    api_key_system_variable = 'LOGICLM_GOOGLE_GENAI_API_KEY'
    chat=None
    def __call__(self, prompt):
        self.api_key = os.environ.get(self.api_key_system_variable)
        if not self.api_key:
            raise ValueError(
                f"Google GenAI API key not found in environment variable: {self.api_key_system_variable}"
            )
        if self.configured_api_key != self.api_key:
            genai.configure(api_key=self.api_key)
            self.configured_api_key = self.api_key
        model = genai.GenerativeModel(model_name='gemini-2.0-flash')  # Try accessing GenerativeModel directly
        try:
          content = model.generate_content(
            prompt,
            generation_config=dict(
              max_output_tokens=512,
              temperature=0.2
            ))
          return self.CutOffChatter(content.text)
          #return content.text
        except Exception as e:
          print(f"An error occurred: {e}")
    def CreateNewChat(self):
      self.api_key = os.environ.get(self.api_key_system_variable)
      if self.configured_api_key != self.api_key:
            genai.configure(api_key=self.api_key)
            self.configured_api_key = self.api_key
      model = genai.GenerativeModel(model_name='gemini-2.5-pro-preview-03-25')
      self.chat=model.start_chat()
    def sendPrompt(self,prompt,max_output_tokens=3000):
      response=self.chat.send_message(prompt,generation_config=dict(
              max_output_tokens=max_output_tokens,
              temperature=1
            ))
      return response.text
   
     


class OpenAI(AI):
  configured_api_key = None
  api_key_system_variable = 'LOGICLM_OPENAI_API_KEY'
  
  def __call__(self, prompt):
    client = openai.OpenAI(api_key=self.api_key)
    response = client.chat.completions.create(
      model="gpt-4o",
      messages=[
        {
          "role": "user",
          "content": prompt
        }
      ],
      temperature=1,
      max_tokens=512,
      top_p=1,
      frequency_penalty=0,
      presence_penalty=0
    )
    return self.CutOffChatter(response.choices[0].message.content)

class MistralAI(AI):
  configuration_api_key = None
  api_key_system_variable = 'LOGICLM_MISTRALAI_API_KEY'

  def __call__(self, prompt):
    client = mistral_client.MistralClient(api_key=self.api_key)
    message = mistralai.models.chat_completion.ChatMessage(
      role="user", content=prompt)
    chat_response = client.chat(model='mistral-medium',
                                messages=[message])
    result = self.CutOffChatter(chat_response.choices[0].message.content)
    result = result.replace('\\_', '_')
    return result


def GetPromptTemplate(config):
  def MaybeDescription(call_object):
    if 'description' in call_object:
      return ': %s' % call_object['description']
    return ''

  params_str = lambda parameters: ', '.join(p['field_name']
                                             + ':' for p in parameters)
  result_lines = []
  result_lines.append('Please write configuration for an OLAP request.')
  result_lines.append('Available measures are:')
  result_lines.extend('* %s(%s)%s' % (m['aggregating_function']['predicate_name'],
                                    params_str(m['aggregating_function'].get('parameters', [])),
                                    MaybeDescription(m))
                      for m in config['measures'])
  result_lines.append('')
  result_lines.append('Available dimensions are:')
  result_lines.extend('* %s(%s)%s' % (d['function']['predicate_name'],
                                    params_str(d['function'].get('parameters', [])),
                                    MaybeDescription(d))
                      for d in config['dimensions'])
  result_lines.append('')
  if 'filters' in config:
    result_lines.append('Available filters are:')
    result_lines.extend('* %s(%s)%s' % (d['predicate']['predicate_name'],
                                        params_str(d['predicate'].get('parameters', [])),
                                        MaybeDescription(d))
                        for d in config['filters'])
  result_lines.append('')
  result_lines.append('Available charts are:')
  result_lines.extend('* %s(%s)%s' % (c['predicate']['predicate_name'],
                                      params_str(c['predicate'].get('parameters', [])),
                                      MaybeDescription(c))
                      for c in config['chart_types'])
  result_lines.append('Config is JSON object with fields title, measures, dimensions, filters, order, limit and chartType.')
  # result_lines.append('In the order clause please back-tick the predicate call.')
  result_lines.append('Always use all the fields. For example if you do not have filters, then pass it as empty list.')
  result_lines.append('')
  if 'suffix_lines' in config:
    result_lines.extend(config['suffix_lines'])
  result_lines.append('')
  result_lines.append('Write me JSON for this request: __USER_REQUEST__')
  return '\n'.join(result_lines)


if __name__ == '__main__':
  ai = AI.Get()
  print(ai(sys.argv[1]))


