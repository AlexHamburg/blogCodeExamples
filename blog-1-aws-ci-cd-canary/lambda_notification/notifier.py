import os
import time
import datetime
import json
import requests
import boto3


def build_message_card(timestamp, account_id, region, canary):
    return {
        "@type": "MessageCard",
        "@context": "https://schema.org/extensions",
        "summary": "Syntatic Canary Alert",
        "themeColor": "FF0000",
        "title": "Syntatic Canary Alert: " + canary,
        "sections": [
            {
                "activityTitle": "Alarm for Canary Failures",
                "activitySubtitle": timestamp,
                "facts": [
                    {
                        "name": "Canary:",
                        "value": canary
                    }
                ],
            }
        ],
        "potentialAction": [
            {
                "@type": "OpenUri",
                "name": "Open Synthetics Canary",
                "targets": [
                    {
                        "os": "default",
                        "uri": "https://" + region +
                               ".console.aws.amazon.com/cloudwatch/home" +
                               "?region=" + region +
                               "#synthetics:canary/detail/" + canary
                    }
                ]
            }
        ]
    }


def lambda_handler(event, context):
    webhook_secret_arn = os.environ.get('WEBHOOK_SECRET_ARN')
    logs_table = os.environ.get('LOGS_TABLE')
    logs_expiration_days = os.environ.get('LOGS_EXPIRATION_DAYS')

    client_secmgr = boto3.client('secretsmanager')

    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(logs_table)

    expirationInDays = int(time.time()) + int(datetime.timedelta(days=int(logs_expiration_days)).seconds)
    expirationTimestamp = datetime.datetime.fromtimestamp(expirationInDays)
    print('write start processing logs')
    table.put_item(
        Item={
            'timestamp': event['time'],
            'alarm': event['detail']['alarmName'],
            'trigger': event['detail']['state']['reason'],
            'sent_successful': False,
            'expiration': int(expirationTimestamp.timestamp())
        }
    )

    response = client_secmgr.get_secret_value(SecretId=webhook_secret_arn)
    credentials = json.loads(response['SecretString'])
    url = credentials['teams_webhook_url']

    if len(url) == 0:
        raise Exception("error: no webhook URL provided")

    print("building teams message object")
    message = build_message_card(
        event['detail']['state']['timestamp'],
        event['account'],
        event['region'],
        event['detail']['configuration']['metrics'][0]['metricStat']['metric']['dimensions']['CanaryName']
    )
    print("send event to teams channel")
    response = requests.post(url, data=json.dumps(message))
    print("response: " + str(response.status_code) + " " + str(response.text))

    print('write finished processing logs')
    table.update_item(
        Key={
            'timestamp': event['time']
        },
        UpdateExpression="set sent_successful=:s",
        ExpressionAttributeValues={
            ':s': True
        }
    )

    return "notification sent"
