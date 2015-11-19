#!/usr/bin/env python

import boto3

# @TODO: how to make the sns ARN more dynamic since it is        created by terraform?
TOPIC_ARN='arn:aws:sns:us-east-1:371378579270:check_runner'

def get_checks():
    return [
            {'url': 'https://pantheon.io'}
            ]

def lambda_handler(event, context):
    """do stuff"""
    print 'DEBUG:', event, context
    client = boto3.client('sns')
    for i in xrange(1, 100):
        for check in get_checks():
            response = client.publish(
                TopicArn=TOPIC_ARN,
                Message=check['url'],
                MessageStructure='string',
            )
            print 'DEBUG: published message to topic, sns response:', response


if __name__ == '__main__':
    lambda_handler({}, {})
