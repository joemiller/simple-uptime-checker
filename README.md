simple-uptime-checker
=====================

An AWS Lambda experiment.

A pingdom-like URL monitor implemented primarily using AWS Lambdas, with SNS for passing
control between lambdas, and API gateway as control interface.

Tech Spec
---------

### api gateway / user interface

- /checks
    - GET - lambda:get_checks
    - POST ? - lambda:add_checks
    - DELETE - lambda:remove_checks

### checker flow

Description: On a timer, execute a lambda (queue_checks) that reads a list of URLs
from a database (dynamoDB?) and publishes each URL to SNS topic (check_runner). A lambda
(run_check) will be executed for each URL published. Results (http-code + duration) are
published to SNS topic (check_results). A final lambda (store_result) reads results
from the check_results topic and processes them (sends to graphite, other datastores, etc)

- `lambda:queue_checks`
    - event source:  scheduled task: every X secs,
    - enumerates a list of checks to run from the db, send each to `sns:check_runner`
- `lambda:run_check`
    - event source: `sns:check_runner`
    - execute check, send result to `sns:check_results`
            - initial check will just be a simple http check, with results being: ``{'code': 200, 'time': 600 }``
- `lambda:store_result`
    - event source: `sns:check_results`
    - send result to graphite (tcp/2003)
    - send result to other stuff?
    - send result to other sns topics ?

Deployment
----------

Management of AWS resources is managed by Terraform. Get terraform from http://terraform.io and install it in
your $PATH.

Set environment vars:

    export TF_VAR_aws_access_key=$AMAZON_ACCESS_KEY
    export TF_VAR_aws_secret_key=$AMAZON_SECRET_KEY

Run `make plan` to execute terraform in `plan` mode, which will show you what changes it will make
when run in `apply` mode.

Deploy: Run `make all`.
