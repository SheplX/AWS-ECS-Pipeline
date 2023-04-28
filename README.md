# AWS ECS Pipeline
Introducing a full deployment cycle of 2 different node.js apps with ECS cluster and Jenkins. each app will provide 2 different microservices. this cycle will aim to provide the best high availability and security to the microservices, a smart logic for dynamically scaling up / down according to changes in demand and providing optimized cost plan. using AWS stack like Cloudwatch for getting the applications logs, Route 53 bounded with ALB for routing the traffic to the cluster, and ECR for storing the images.

![Project](./screenshots/project.png)

# Terraform Resources

- I tried to make a general ECS module including the both `EC2` and `Fargate` launch types. each launch type is prepared with auto-scaling policies and high availability across availability zones. and each launch type will have a specific target group type and different service configurations.
- Modules :
    - `Network` 
        - VPC with 2 public subnets for Loadbalancer and 2 private subnets associated with nat gateway allocated with elastic IP to make sure that apps in the private subnet can access the internet without problems.
    - `IAM`
        - 2 required services are wanted with assume role action for running the ECS services, in my case because this module will have both service launch types:
            - `Fargate` - will need `ecs-tasks.amazonaws.com` service attached to a role have a policy for managing ECS tasks and this role will be added to the Fargate service.
            - `EC2` - will need `ec2.amazonaws.com` service attached to a role that has a policy for managing ECS tasks and this role will be added to the IAM instance profile resource so we can use it on launch configuration so any launched instance will have this role assigned with it to be able to manage ECS operations.
    - `ECR`
        - For storing our images privately.
    - `ECS`
        - ECS Cluster with both service launch type solutions if Fargate or EC2.
        - security group for services and auto scaling group allows traffic only from the load balancer with an additional option allowing to access service from public IP.
        - launch Configuration configured with AMI has Docker engine installed, instance type, security group for services, and IAM instance profile important to assign an ECS task management role for each launched instance so that instance will be able to manage the ECS tasks.
        - auto-scaling group assigned with the previous launch configuration with some additional configs like target group, max & min number of launched instances.
        - Cloudwatch for creating several groups for each service for getting the container logs.
        - task definition will have a specific config according to each service case, setting each service with Cloudwatch group, the ability to choose service type if Fargate or ec2.
        - service template with launch type option configured with the previous task definition and have 2 resources, the capacity provider will be created & assigned for any service with EC2 launch type only and it's required for best cost plan so only launched instances will be those which required by the service only and for making sure that no any unused instances are active. if Fargate then the second resource network configuration will be applied. the load balancer resource for both service types for adding each service to its specific target group with the container name & port.
        - auto-scaling target configured with 2 policies:
            - `Memory` & `CPU` - both will watch the service memory and ram metrics. if it is more than 75 % then a new replica will be launched to handle the traffic and when it goes less than 75% it will dynamically terminate the additional replica and keep only one.
            - this is very important for dynamically scaling up / down according to the traffic being handled by a service and for making sure about high availability for each service also for keeping the best cost optimization plan.
    - `Security Group`
        - creates a security group for the application load balancer opened on port 80.
    - `Alb`
        - creates an Application load balancer with all its components.
        - target group will be created for each service defined with a different target group type for each service type. so if Fargate, then it will create a target group with IP type, if EC2, it will create a target group with instance type. and the ability to configure special health check configurations for each service.
        - listener with default action response with a simple msg if the user visited a page with an unknown path pattern defined.
        - listener rules to configure for each service rules like what kind of action will be used and with which condition. here I used forward action to forward the traffic to each service target group and the condition will be if it matches a specific path pattern according to each service case.
    - `Route53`
        - for creating a custom record type A and binding it to the load balancer.
        - because I have a predefined hosted zone I just used a data resource with the hosted zone name to get the hosted zone ID which is required to add the record to it.