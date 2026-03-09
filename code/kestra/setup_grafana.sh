#!/bin/bash

# Grafana Setup Script for Exasol Workshop
# Author: Thomas Degen
# Event: DataTalks.Club @ Exasol Xperience 2026

set -e

echo "================================================"
echo "Grafana Setup for Exasol NHS Workshop"
echo "================================================"
echo ""

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "Error: Please run this script from the code/kestra directory"
    exit 1
fi

# Create directory structure
echo "Creating directory structure..."
mkdir -p grafana/provisioning/datasources
mkdir -p grafana/provisioning/dashboards
mkdir -p grafana/dashboards

# Prompt for Exasol connection details
echo ""
echo "Please provide Exasol connection details:"
echo "(Run 'exasol info' from deployment directory if needed)"
echo ""

read -p "Exasol Host IP: " EXASOL_HOST
read -p "Exasol Port [8563]: " EXASOL_PORT
EXASOL_PORT=${EXASOL_PORT:-8563}
read -sp "Exasol Password: " EXASOL_PASSWORD
echo ""

# Create datasource configuration
echo ""
echo "Creating Exasol datasource configuration..."
cat > grafana/provisioning/datasources/exasol.yml <<EOF
apiVersion: 1

datasources:
  - name: Exasol
    type: postgres
    uid: exasol_datasource
    access: proxy
    url: ${EXASOL_HOST}:${EXASOL_PORT}
    database: EXA_DB
    user: sys
    jsonData:
      sslmode: 'disable'
      postgresVersion: 1200
      timescaledb: false
    secureJsonData:
      password: '${EXASOL_PASSWORD}'
    isDefault: true
    editable: true
EOF

# Create dashboard provider configuration
echo "Creating dashboard provider configuration..."
cat > grafana/provisioning/dashboards/default.yml <<EOF
apiVersion: 1

providers:
  - name: 'Exasol NHS Dashboards'
    orgId: 1
    folder: 'Exasol Workshop'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
      foldersFromFilesStructure: false
EOF

# Copy dashboard JSON (assuming it's in the parent directory)
if [ -f "../grafana_dashboard_exasol_nhs.json" ]; then
    echo "Copying dashboard JSON..."
    cp ../grafana_dashboard_exasol_nhs.json grafana/dashboards/
elif [ -f "grafana_dashboard_exasol_nhs.json" ]; then
    echo "Copying dashboard JSON..."
    cp grafana_dashboard_exasol_nhs.json grafana/dashboards/
else
    echo "Warning: Dashboard JSON not found. Please copy it manually to grafana/dashboards/"
fi

# Backup existing docker-compose.yml
if [ -f "docker-compose.yml" ]; then
    echo "Backing up existing docker-compose.yml..."
    cp docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)
fi

# Check if docker-compose-with-grafana.yml exists
if [ -f "../docker-compose-with-grafana.yml" ]; then
    cp ../docker-compose-with-grafana.yml docker-compose.yml
elif [ -f "docker-compose-with-grafana.yml" ]; then
    cp docker-compose-with-grafana.yml docker-compose.yml
else
    echo "Error: docker-compose-with-grafana.yml not found"
    exit 1
fi

echo ""
echo "Configuration complete!"
echo ""

# Ask to start services
read -p "Start Grafana now? (y/n): " START_NOW

if [ "$START_NOW" = "y" ] || [ "$START_NOW" = "Y" ]; then
    echo ""
    echo "Starting services..."
    docker compose down
    docker compose up -d

    echo ""
    echo "Waiting for Grafana to start..."
    sleep 10

    echo ""
    echo "================================================"
    echo "Setup Complete!"
    echo "================================================"
    echo ""
    echo "Access Grafana at: http://localhost:3000"
    echo "Login: admin / admin"
    echo ""
    echo "Dashboard location:"
    echo "  Dashboards → Exasol Workshop → Exasol NHS Prescriptions"
    echo ""
    echo "To view logs: docker compose logs -f grafana"
    echo "================================================"
else
    echo ""
    echo "Configuration saved. Start services manually with:"
    echo "  docker compose up -d"
fi
