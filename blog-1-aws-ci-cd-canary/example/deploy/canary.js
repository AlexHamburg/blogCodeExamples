var synthetics = require('Synthetics');
const log = require('SyntheticsLogger');

const AWS = require('aws-sdk');
const S3 = new AWS.S3();
const secretsManager = new AWS.SecretsManager();

const debugHeader = true;
const debugBody = true;

// request JSON files
const bucketName = "bucket";
const request = "requests/request.json";

// api paths
const host = 'example.com';
const path = '/test';
const pathAuth = '/auth';

// global variables
let requestBody = null;
let bearerToken = null;

/* 
Use Case: 
Step 1: Auth -> Token
Step 2: Request to my API
*/

const apiMonitoring = async function () {

    // Preparing (canary global config):
    syntheticsConfiguration.setConfig({
        restrictedHeaders: ['X-Amz-Security-Token', 'Authorization'],
        restrictedUrlParameters: [] 
    });

    // Read requests from S3
    requestBodyRaw = await S3.getObject(
        {
            Bucket: bucketName,
            Key: request,
            ResponseContentType: 'application/json'
        }).promise();
    requestBody = JSON.parse(requestBodyRaw.Body.toString('utf-8'));

    // Create a client for Secrets Manager
    const getSecrets = async (secretName) => {
        var params = {
            SecretId: secretName
        };
        return await secretsManager.getSecretValue(params).promise();
    }

    // Fetch secrets credentials
    let secrets = await getSecrets("CANARY_API");
    let secretsObj = JSON.parse(secrets.SecretString);

    // -----------------------------------------------------------------
    // STEP 1: Auth
    // -----------------------------------------------------------------
    const validateSuccessfulAuth = async function (res) {
        return new Promise((resolve, reject) => {
            if (res.statusCode < 200 || res.statusCode > 299) {
                throw res.statusCode + ' ' + res.statusMessage;
            }

            let responseBody = '';
            res.on('data', (d) => {
                responseBody += d;
            });

            res.on('end', () => {
                bearerToken = JSON.parse(responseBody);
                if (!bearerToken) {
                    log.error("Auth is failed. No token is found.");
                    throw "Auth is failed. No token is found." + res.statusCode + " " + res.statusMessage;
                }
            });
        });
    };

    // Set request option to verify auth
    let authStep = {
        hostname: host,
        method: 'POST',
        path: pathAuth,
        port: '443',
        protocol: 'https:',
        body: requestBody,
        headers: { "content-type": "application/json" }
    };
    authStep['headers']['User-Agent'] = [synthetics.getCanaryUserAgentString(), authStep['headers']['User-Agent']].join(' ');

    // Set step config option for Verify Auth
    let authStepConfig = {
        includeRequestHeaders: debugHeader,
        includeResponseHeaders: debugHeader,
        includeRequestBody: false,
        includeResponseBody: debugBody,
        continueOnHttpStepFailure: false,
        restrictedHeaders: ['X-Amz-Security-Token', 'Authorization']
    };

    // -----------------------------------------------------------------
    // STEP 2: Request to my API
    // -----------------------------------------------------------------
    // Handle validation for positive scenario
    const validateSuccessfulGetRequest = async function (res) {
        return new Promise((resolve, reject) => {
            if (res.statusCode < 200 || res.statusCode > 299) {
                throw res.statusCode + ' ' + res.statusMessage;
            }

            let responseBody = '';
            res.on('data', (d) => {
                responseBody += d;
            });

            res.on('end', () => {
                response = JSON.parse(responseBody);
                if (!response) {
                    log.error("Request is failed.");
                    throw "Request is failed." + res.statusCode + " " + res.statusMessage;
                }
            });
        });
    };

    // Set request option to verify auth
    let reqStep = {
        hostname: host,
        method: 'GET',
        path: path,
        port: '443',
        protocol: 'https:',
        body: "{\"foo\": \"boo\"}",
        headers: { "content-type": "application/json" }
    };
    reqStep['headers']['User-Agent'] = [synthetics.getCanaryUserAgentString(), authStep['headers']['User-Agent']].join(' ');

    // Set step config option
    let stepConfig = {
        includeRequestHeaders: debugHeader,
        includeResponseHeaders: debugHeader,
        includeRequestBody: debugBody,
        includeResponseBody: debugBody,
        continueOnHttpStepFailure: false,
        restrictedHeaders: ['X-Amz-Security-Token', 'Authorization']
    };

    // Call steps
    // Call to Auth
    await synthetics.executeHttpStep('Step 1: Auth', authStep, validateSuccessfulAuth, authStepConfig);
    // Call to my API
    await synthetics.executeHttpStep('Step 1: Auth', reqStep, validateSuccessfulGetRequest, stepConfig);
};

exports.handler = async () => {
    return await apiMonitoring();
};
