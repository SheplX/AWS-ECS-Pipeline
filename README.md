# AWS ECS Pipeline
Introducing a full deployment cycle of 2 different node.js apps with ECS cluster and Jenkins. each app will provide 2 different microservices. this cycle will aim to provide the best high availability and security to the microservices, a smart logic for dynamically scaling up / down according to changes in demand and providing optimized cost plan. using AWS stack like Cloudwatch for getting the applications logs, Route 53 bounded with ALB for routing the traffic to the cluster, and ECR for storing the images.

![Project](./screenshots/project.png)

