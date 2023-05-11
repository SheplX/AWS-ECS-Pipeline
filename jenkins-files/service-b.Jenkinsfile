pipeline {

    environment {
        AWS_REGION          = 'eu-central-1'
        DOCKER_REGISTRY     = '123456789.dkr.ecr.eu-central-1.amazonaws.com'
        DOCKER_IMAGE_NAME   = 'pipeline-service-b'
        DOCKER_IMAGE_TAG    = "${env.BUILD_NUMBER}-service-b"
        ECS_CLUSTER_NAME    = 'pipeline-dev-ecs-cluster'
        ECS_SERVICE_NAME    = 'service-b'
        ECS_TASK_DEFINITION = 'pipeline-service-b'
        SERVICE_DIR         = 'service-b'
        ENV_FILE            = 'service-b'
    }

  agent {
    kubernetes {
      yaml '''
        apiVersion: v1
        kind: Pod
        metadata:
          name: docker
        spec:
          containers:
          - name: docker
            image: shepl/docker.aws:alpine
            imagePullPolicy: IfNotPresent
            command: ["sleep", "infinity"]
            volumeMounts:
            - name: docker-socket
              mountPath: /var/run/docker.sock
          volumes:
          - name: docker-socket
            hostPath:
              path: /var/run/docker.sock
        '''   
    }
  }

    stages {

        stage('Build Docker image') {
            steps {
                dir("${SERVICE_DIR}") {
                    container('docker') {
                        script {
                            sh "docker build -t ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ."
                        }
                    } 
                }  
            }
        }

        stage('Push to ECR') {
          steps {
                container('docker') {
                    withCredentials([usernamePassword(credentialsId: 'AWS', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        script {
                            sh """
                                aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${DOCKER_REGISTRY}
                                docker push ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
                            """
                        }
                    }
                }
            }
        }

        stage('Update ECS service') {
            steps {
                container('docker') {
                    withCredentials([usernamePassword(credentialsId: 'AWS', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh """
                            LAUNCH_TYPE=\$(jq -r '.LAUNCH_TYPE' data/\$ENV_FILE.json)
                            SERVICE_1=\$(jq -r '.SERVICE_1' data/\$ENV_FILE.json)
                            SERVICE_2=\$(jq -r '.SERVICE_2' data/\$ENV_FILE.json)
                            NODE_ENV=\$(jq -r '.NODE_ENV' data/\$ENV_FILE.json)
                            PORT=\$(jq -r '.PORT' data/\$ENV_FILE.json)
                            TASK_DEFINITION=\$(aws ecs describe-task-definition --task-definition \${ECS_TASK_DEFINITION} --region \${AWS_REGION})
                            CURRENT_TASK_ARN=\$(aws ecs list-tasks --cluster \${ECS_CLUSTER_NAME} --service-name \${ECS_SERVICE_NAME} --desired-status RUNNING --query 'taskArns[0]' --output text --region \${AWS_REGION})
                            CURRENT_TASK_DEFINITION_ARN=\$(aws ecs describe-tasks --cluster \${ECS_CLUSTER_NAME} --tasks \${CURRENT_TASK_ARN} --query 'tasks[0].taskDefinitionArn' --output text --region \${AWS_REGION})
                            aws ecs deregister-task-definition --task-definition \${CURRENT_TASK_DEFINITION_ARN} --region \${AWS_REGION}
                            NEW_TASK_DEFINITION=\$(echo \${TASK_DEFINITION} | jq '.taskDefinition' | jq --arg DOCKER_REGISTRY "$DOCKER_REGISTRY" --arg DOCKER_IMAGE_NAME "$DOCKER_IMAGE_NAME" --arg DOCKER_IMAGE_TAG "$DOCKER_IMAGE_TAG" '.containerDefinitions[].image |= sub("$DOCKER_REGISTRY/$DOCKER_IMAGE_NAME:.*"; "$DOCKER_REGISTRY/$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG")' | jq --arg LAUNCH_TYPE \$LAUNCH_TYPE --arg SERVICE_1 \$SERVICE_1 --arg SERVICE_2 \$SERVICE_2 --arg NODE_ENV \$NODE_ENV --arg PORT \$PORT '.containerDefinitions[].environment[].value |= ( sub("LAUNCH_TYPE=[^;]*"; "LAUNCH_TYPE="+\$LAUNCH_TYPE) | sub("SERVICE_1=[^;]*"; "SERVICE_1="+\$SERVICE_1) | sub("SERVICE_2=[^;]*"; "SERVICE_2="+\$SERVICE_2) | sub("NODE_ENV=[^;]*"; "NODE_ENV="+\$NODE_ENV) | sub("PORT=[^;]*"; "PORT="+\$PORT) )' | jq 'del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)')
                            NEW_TASK_INFO=\$(aws ecs register-task-definition --region \${AWS_REGION} --cli-input-json "\${NEW_TASK_DEFINITION}")
                            NEW_REVISION=\$(echo \${NEW_TASK_INFO} | jq '.taskDefinition.revision')
                            aws ecs update-service  --region \${AWS_REGION} --cluster \${ECS_CLUSTER_NAME} --service \${ECS_SERVICE_NAME} --task-definition \${ECS_TASK_DEFINITION}:\${NEW_REVISION}
                        """
                    }
                }
            }
        }


    }    
}