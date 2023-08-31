#!/bin/python
# This program creates a new QuickSight Analysis using a template

import boto3
import json, os, sys
from string import Template

def process_input(aws_region: str, aws_profile: str, aws_account_id: str, template_file: str, dataset_arn: str, quicksight_user_arn: str, analysis_id: str, analysis_name: str) -> dict: 
  result = {}

  if not os.path.exists(template_file):
    result['status'] = '500'
    result['error'] = f'File {template_file} not found or cannot be read.'
    return result

  try: 
    fh = open(template_file, 'r', encoding='utf8')
    tpl_contents = fh.read()
    fh.close()

    tpl = Template(tpl_contents)
    analysis_json = tpl.substitute(dataset_arn=dataset_arn, quicksight_user_arn=quicksight_user_arn)
    analysis_dict = json.loads(analysis_json)

    session = boto3.Session(region_name=aws_region, profile_name=aws_profile)
    qs = session.client('quicksight')
    qs_response = qs.create_analysis(
      AwsAccountId = aws_account_id, 
      AnalysisId = analysis_id, 
      Name = analysis_name, 
      **analysis_dict
    )
  except Exception as err: 
    result['status'] = '500'
    result['error'] = str(err)
    return result


  result['status'] = str(qs_response.get('Status'))
  if qs_response.get('Status') >= 200 and qs_response.get('Status') < 300: 
    result['arn'] = str(qs_response['Arn'])
    result['analysis_id'] = str(qs_response['AnalysisId'])
    result['creation_status'] = str(qs_response['CreationStatus'])

  return result

if __name__ == '__main__':
  input = sys.stdin.read()
  params = json.loads(input)
  
  result = process_input(**params)
  print(json.dumps(result))


