# AWS Co-pilot
## What are we looking to achieve

* mono repo with 3 variations of the same application (with the different variations defined by entry points in the docker file)
* deployment sequence is important
* each branch should result in a unique deployed version of the application
* environments should be temporary, and created and deleted as required

## Look at the application

Simple [flask app](./app.py), that just displays some dynamic html generated from [a template](./index.html)
A single [docker file](./Dockerfile)

## Recap of co-pilot concepts

https://aws.github.io/copilot-cli/docs/overview/

### Application

An Application is a collection of services and environments (in my example here, I’m going to just use “webapp”

Application initialisation triggers creation of application specific:

* IAM Roles to manage services and jobs in your environment
* KMS Key
* S3 Bucket

### Service

A service is your code and all of the supporting infrastructure needed to get it up and running on AWS.  For this demo, we have 3 services, web, admin and scheduler

Service initialisation triggers creation of:

* An ECR Repository per service

copilot init is a shorthand command, that initialises an app (if required) as well as a service.  I’ve got 3 to initialise:

```
copilot init --app webapp --type "Load Balanced Web Service" --name scheduler
copilot init --app webapp --type "Load Balanced Web Service" --name web
copilot init --app webapp --type "Load Balanced Web Service" --name admin
```

### Environment

Environment in copilot refers to tradition environments within a single AWS account used to deploy code (eg. dev, test, prod) each with its own infrastructure, but in my demo today, its going to represent a distinct version of a deployed application (so a branch, or tag)

Environment initialisation involves creation of the following resources:

* Load balancer (listener, sg, default target group)
* ECS cluster
* Service discovery namespace

And optionally a new dedicated VPC with 2 AZs, 2 public subnets and 2 private subnets.

For our requirements, environment would likely map to a branch, or optionally to a tag

```
copilot env init --app webapp --name test --container-insights --import-vpc-id vpc-09c4429329f753e0c --import-public-subnets subnet-0aa17990f2ee22fde,subnet-029f94c618bd9e221,subnet-0d69222a3c05cbe7e --import-private-subnets subnet-0ffa2a27c68f0782d,subnet-0ad9e870f74801f17,subnet-0b0e529004420cce1
```

### Pipelines

A pipeline, is as you can imagine, a pipeline.  Set up to monitor source control and automate deployment when a change is detected.  In this demo, each branch would have its own distinct pipeline, and deployment lifecycle.

Now we can deploy directly from here using copilot svc deploy, but best practice tells us that a pipeline is a better option:

```
copilot pipeline deploy --app webapp --environments test --name copilot-multiservice-main
```

Switch to confirm it completes, then ec2/load balancers.

http://<LOAD BALANCER_URL>/scheduler
http://<LOAD BALANCER_URL>/web
http://<LOAD BALANCER_URL>/admin

Now push a change.

## Cleaning up
When its time to tear it down, we can:

```
copilot pipeline delete --app webapp --name copilot-multiservice-main --yes
copilot svc delete --name scheduler --env test --yes
copilot svc delete --name web --env test --yes
copilot svc delete --name admin --env test --yes
copilot env delete --name test --yes
```