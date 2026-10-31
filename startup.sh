#!/bin/bash

print_help() {
  cat <<EOF
Usage: $0 [dev|clean|prod|prod-clean]

Optional positional parameters:
    dev             Run the application for local development, keeping existing volumes
    clean           Run the application for local development, wiping volumes first
    prod            Run the production stack (env.prod, Caddy on 80/443) detached
    prod-clean      Same as prod, but wipe the database first (asks for confirmation)

Options:
    -h, --help      Show this help message and exit
EOF
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  print_help
  exit 0
fi

mode=${1:-dev}

if [[ "$mode" != "dev" && "$mode" != "clean" && "$mode" != "prod" && "$mode" != "prod-clean" ]]; then
  echo "Unknown mode. Exiting..."
  exit 1
fi

COMPOSE_PROJECT_NAME=prospero-acl

if [[ "$mode" = "dev" || "$mode" = "clean" ]]; then
  echo "Running in $mode mode..."
  ENV_FILE=env.localdev
  DOCKER_COMPOSE_FILE=docker-compose-localdev.yml
elif [[ "$mode" = "prod" || "$mode" = "prod-clean" ]]; then
  echo "Running in $mode mode..."
  ENV_FILE=env.prod
  DOCKER_COMPOSE_FILE=docker-compose-prod.yml
fi

if [[ -f "$ENV_FILE" ]]; then
  echo "Loading env file..."
  set -a
  source "$ENV_FILE"
  set +a
else
  echo "env file not found. Exiting..." >&2
  exit 1
fi

if [[ "$mode" = "prod-clean" ]]; then
  echo "This deletes the production database: all users, clearances, trilogies and embeddings."
  answer=""
  while [[ "$answer" != "yes" && "$answer" != "no" ]]; do
    read -r -p "Continue? (yes/no): " answer || { echo; echo "Aborted."; exit 1; }
  done
  if [[ "$answer" = "no" ]]; then
    echo "Aborted."
    exit 0
  fi
fi

echo "Running docker compose..."
if [[ "$mode" = "clean" ]]; then
  docker compose -f "$DOCKER_COMPOSE_FILE" -p "$COMPOSE_PROJECT_NAME" down &&
    (docker volume rm "${COMPOSE_PROJECT_NAME}_node_modules" || true) &&
    (docker volume rm "${COMPOSE_PROJECT_NAME}_postgres_data" || true) &&
    docker compose -f "$DOCKER_COMPOSE_FILE" -p "$COMPOSE_PROJECT_NAME" up --build
elif [[ "$mode" = "prod" ]]; then
  # rebuilds and replaces the containers in place; postgres_data and caddy_data are kept
  docker compose -f "$DOCKER_COMPOSE_FILE" -p "$COMPOSE_PROJECT_NAME" up -d --build --remove-orphans
elif [[ "$mode" = "prod-clean" ]]; then
  # only postgres_data goes; caddy_data keeps the TLS certs so Let's Encrypt isn't asked again
  docker compose -f "$DOCKER_COMPOSE_FILE" -p "$COMPOSE_PROJECT_NAME" down &&
    (docker volume rm "${COMPOSE_PROJECT_NAME}_postgres_data" || true) &&
    docker compose -f "$DOCKER_COMPOSE_FILE" -p "$COMPOSE_PROJECT_NAME" up -d --build --remove-orphans
else
  docker compose -f "$DOCKER_COMPOSE_FILE" -p "$COMPOSE_PROJECT_NAME" down &&
    docker compose -f "$DOCKER_COMPOSE_FILE" -p "$COMPOSE_PROJECT_NAME" up --build
fi
