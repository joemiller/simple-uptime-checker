# example lambda makefile: https://github.com/localytics/node-lambda-starter/blob/master/Makefile
# http://docs.aws.amazon.com/lambda/latest/dg/lambda-python-how-to-create-deployment-package.html
#

all: tf

clean:
	rm -rf pkg venv lambdas.zip

venv: requirements.txt
	rm -rf venv
	virtualenv venv
	# need a newer version of setuptools on OSX 10.11 otherwise mock install will fail.
	venv/bin/pip install --upgrade setuptools
	venv/bin/pip install -r requirements.txt

lambdas.zip: venv *.py
	cp -r venv/lib/python2.7/site-packages/ pkg/
	cp *.py pkg/
	cd pkg && zip -r ../lambdas.zip .

test: venv
	./venv/bin/python tests.py

# @TODO(joe): this is a workaround to force terraform to delete/create lambda functions. This shouldn't be needed after https://github.com/hashicorp/terraform/pull/3825 is released.
taint_lambdas:
	terraform taint -allow-missing aws_lambda_function.lambda_queue_checks
	terraform taint -allow-missing aws_lambda_function.lambda_run_check
	terraform taint -allow-missing aws_lambda_function.lambda_store_result

plan:
	terraform plan ./terraform

tf: lambdas.zip
	terraform apply ./terraform

# TODO: create an event mapping of the 'scheduled_event' type. This is not currently possible
#       with the aws-cli though. https://forums.aws.amazon.com/thread.jspa?threadID=218513

.PHONY: clean plan tf
