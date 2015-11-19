#!/usr/bin/env python

import json


def lambda_handler(event, context):
    for check in event['Records']:
        msg = check['Sns']['Message']
        result = json.loads(msg)
        print "DEBUG: result:", result


if __name__ == '__main__':
    result = {'url': 'http://pantheon.io', 'code': 200, 'duration': 350.1}
    event = {'Records': [{'Sns': {'Message': json.dumps(result)}}]}
    lambda_handler(event, {})
