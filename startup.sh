#!/bin/bash

print_help() {
  cat <<EOF
Usage: $0 [dev|prod]

Optional positional parameters:
    dev             Run the application for local development
    prod            TODO

Options:
    -h, --help      Show this help message and exit
EOF
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  print_help
  exit 0
fi

mode=${1:-dev}

if [[ "$mode" != "dev" && "$mode" != "prod" ]]; then
  echo "Unknown mode. Exiting..."
  exit 1
fi

COMPOSE_PROJECT_NAME=prospero-acl

if [[ "$mode" = "dev" ]]; then
  echo "Running in dev mode..."
  ENV_FILE=.env.localdev
  COMPOSE_FILE=docker-compose-localdev.yml
elif [[ "$mode" = "prod" ]]; then
  echo "Running in prod mode..."
  echo "THIS IS NOT IMPLEMENTED YET! Exiting...."
  exit 0
fi

if [[ -f ENV_FILE ]]; then
  echo "Loading env file..."
  set -a
  source $ENV_FILE
  set +a
else
  echo "env file not found. Exiting..." >&2
  exit 1
fi

echo "Running docker compose..."
docker compose -f $DOCKER_COMPOSE_FILE -p $COMPOSE_PROJECT_NAME down &&
  (docker volume rm "${COMPOSE_PROJECT_NAME}_node_modules" || true) &&
  docker compose -f $DOCKER_COMPOSE_FILE -p $COMPOSE_PROJECT_NAME up --build
