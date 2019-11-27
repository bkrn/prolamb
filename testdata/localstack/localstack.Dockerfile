FROM localstack/localstack:0.10.4

ENV DEBUG=1
ENV SERVICES=lambda
ENV LAMBDA_EXECUTOR=docker
ENV LAMBDA_REMOTE_DOCKER=true
ENV LAMBDA_DOCKER_NETWORK=host

ENV START_WEB=0

COPY lambda_executors.py localstack/services/awslambda/
COPY lambda_api.py localstack/services/awslambda/