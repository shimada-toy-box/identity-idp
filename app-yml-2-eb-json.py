#!/usr/bin/env python

import json
import yaml

with open('../pauldoom-test.yaml', 'r') as yf:
  d = yaml.safe_load(yf)

o = []
for k, v in d.items():
  # Empty values will not load into an environment
  if v is None:
    continue
  o.append({'Namespace': 'aws:elasticbeanstalk:application:environment', 'OptionName': k, 'Value': v})

with open('./config.json', 'w') as outf:
  json.dump(o, outf, indent=2)
