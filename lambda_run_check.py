#!/usr/bin/env python

import json
import boto3
import urllib2
from timeit import default_timer as timer


# @TODO: how to make the sns ARN more dynamic since it is        created by terraform?
TOPIC_ARN='arn:aws:sns:us-east-1:371378579270:check_results'

def check_url(url):
    """
    Given a URL, query it and return a tuple containing the http-response-code, duration (ms)
    """
    start = timer()
    try:
        resp = urllib2.urlopen(url)
        response_code = resp.getcode()
    except urllib2.HTTPError, e:
        response_code = e.code
    end = timer()
    duration = (end - start) * 1000
    return (response_code, duration)


def publish_result(result):
    client = boto3.client('sns')
    response = client.publish(
        TopicArn=TOPIC_ARN,
        Message=json.dumps(result),
        MessageStructure='string',
    )
    print 'DEBUG: published message to topic, sns response:', response
    return response


def lambda_handler(event, context):
    for check in event['Records']:
        url = check['Sns']['Message']
        code, duration = check_url(url)
        print 'RESULT: {}: code: {} duration: {} ms'.format(url, code, duration)
        publish_result({'url': url, 'code': code, 'duration': duration})


if __name__ == '__main__':
    event = {'Records': [{'Sns': {'Message': 'https://pantheon.io'}}]}
    lambda_handler(event, {})
