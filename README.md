# OpenClinica & PostgreSQL with Backup Script and Environment Files

This project provides an OpenClinica Community Edition environment running with a PostgreSQL backend. It includes a Docker Compose configuration to create and link the two services, a backup script (`oc_backup.sh`) to automate backups, and environment variable files (.env and .env_sample) to simplify configuration management.

## Table of Contents

- [Overview](#overview)
- [Services Description](#services-description)
  - [PostgreSQL Database Service (`pgs`)](#postgresql-database-service-pgs)
  - [OpenClinica Application Service (`openclinica`)](#openclinica-application-service-openclinica)
- [Docker Compose Configuration](#docker-compose-configuration)
- [Environment Files](#environment-files)
  - [.env_sample](#env_sample)
  - [Using .env](#using-env)
- [Backup Script (`oc_backup.sh`)](#backup-script-oc_backupsh)
  - [Backup Script Overview](#backup-script-overview)
  - [How It Works](#how-it-works)
  - [Running the Backup](#running-the-backup)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)
- [Additional Information](#additional-information)
- [License](#license)

## Overview

This repository sets up OpenClinica Community Edition using Docker Compose with two main services:
- **PostgreSQL (`pgs`):** Provides the database backend.
- **OpenClinica (`openclinica`):** Hosts the clinical data capture web application.

In addition, a backup script is provided to create backups of:
- The PostgreSQL database (using `pg_dump`).
- The persistent Docker volumes (`ocdb-data` and `oc-data`) that store database and application data.

Environment variable files (`.env` and `.env_sample`) help centralize configuration settings for both the services and backup process.

## Services Description

### PostgreSQL Database Service (`pgs`)

- **Image:** `postgres:9.4`
- **Ports:** Exposes port `5432` for database access.
- **Environment Variables:**  
  These variables are loaded from the environment file(s) (see [Environment Files](#environment-files)).
  - `POSTGRES_DB`
  - `POSTGRES_USER`
  - `POSTGRES_PASSWORD`
- **Volumes:** Uses `ocdb-data` to persist database files.
- **Network:** Connects to the custom network `mynetwork` for internal container communication.

### OpenClinica Application Service (`openclinica`)

- **Image:** `piegsaj/openclinica:oc-3.13`
- **Ports:** Exposes port `8080` for accessing the web interface.
- **Environment Variables:**  
  Loaded from the environment file(s), these include:
  - `LOG_LEVEL`
  - `TZ`
  - `DB_TYPE`
  - `DB_HOST`
  - `DB_NAME`
  - `DB_USER`
  - `DB_PASS`
  - `DB_PORT`
  - `SUPPORT_URL`
- **Dependencies:** Depends on the PostgreSQL container (`pgs`).
- **Volumes:** Uses `oc-data` to persist OpenClinica application data.
- **Network:** Part of the `mynetwork` bridge network.

## Docker Compose Configuration

The `docker-compose.yml` file defines the services, persistent volumes, and a custom network. For example:

```yaml
services:
  pgs:
    image: postgres:9.4
    restart: always
    ports:
      - ${PGS_PORT:-5432}:5432
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - ocdb-data:/var/lib/postgresql/data
    networks:
      - mynetwork

  openclinica:
    image: piegsaj/openclinica:oc-3.13
    restart: always
    ports:
      - ${OC_PORT:-8080}:8080
    environment:
      LOG_LEVEL: ${LOG_LEVEL}
      TZ: ${TZ}
      DB_TYPE: ${DB_TYPE}
      DB_HOST: ${DB_HOST}
      DB_NAME: ${DB_NAME}
      DB_USER: ${DB_USER}
      DB_PASS: ${DB_PASS}
      DB_PORT: ${DB_PORT}
      SUPPORT_URL: ${SUPPORT_URL}
    depends_on:
      - pgs
    volumes:
      - oc-data:/usr/local/tomcat/openclinica.data
    networks:
      - mynetwork

volumes:
  ocdb-data:
  oc-data:

networks:
  mynetwork:
    driver: bridge
```

*Note:* Environment variable substitutions in the Docker Compose file use the values defined in `.env` (or system environment variables). If a variable is not defined, you can specify a default (as shown for `PGS_PORT` and `OC_PORT`).

## Environment Files

### .env_sample

This sample file contains default values for the configuration variables used by the services. Copy it to create your own `.env` file and adjust as needed.

```dotenv
# PostgreSQL settings
POSTGRES_DB=clinica
POSTGRES_USER=clinica
POSTGRES_PASSWORD=clinica
PGS_PORT=5432

# OpenClinica settings
LOG_LEVEL=INFO
TZ=UTC-1
DB_TYPE=postgres
DB_HOST=pgs
DB_NAME=clinica
DB_USER=clinica
DB_PASS=clinica
DB_PORT=5432
SUPPORT_URL=https://www.openclinica.com/community-edition-open-source-edc/
OC_PORT=8080
```

### Using .env

1. **Create Your .env File:**  
   Copy the sample file to create your working `.env` file:
   ```bash
   cp .env_sample .env
   ```
2. **Customize Configuration:**  
   Open `.env` in your favorite text editor to adjust settings such as database credentials, port mappings, timezone, etc.
   ```bash
   nano .env
   ```
3. **Docker Compose Integration:**  
   When you run Docker Compose, the settings in `.env` will automatically be used to substitute the variables in `docker-compose.yml`.

## Backup Script (oc_backup.sh)

### Backup Script Overview

The `oc_backup.sh` script automates the backup process of your OpenClinica deployment by performing the following tasks:
- Creates a backup directory (default: `/home/clinical/backup`).
- Backs up the PostgreSQL database (using `pg_dump` via Docker Compose).
- Backs up the persistent volumes (`ocdb-data` and `oc-data`) using temporary Alpine containers.

### How It Works

1. **Preparation:**  
   - Sets a backup directory and generates a timestamp to create unique filenames.
   - Creates the backup directory if it doesn't exist.

2. **Database Backup:**  
   - Executes a PostgreSQL dump inside the running `pgs` container.
   - Outputs a SQL dump file with the timestamp (e.g., `clinica_backup_YYYYMMDD_HHMMSS.sql`).

3. **Volume Backups:**  
   - Launches a temporary Alpine container to create tarball backups of the `ocdb-data` and `oc-data` volumes.
   - The tarball files are named with the current timestamp (e.g., `ocdb-data_YYYYMMDD_HHMMSS.tar.gz`).

### Running the Backup

1. **Set Execute Permission:**  
   Make the backup script executable:
   ```bash
   chmod +x oc_backup.sh
   ```

2. **Run the Script:**  
   Execute the script to create backups:
   ```bash
   ./oc_backup.sh
   ```

3. **Verify Backups:**  
   The backup files will be stored in `/home/clinical/backup` (or the directory specified in the script).

## Prerequisites

- **Docker** and **Docker Compose** must be installed on your system.
  - [Get Docker](https://docs.docker.com/get-docker/)
  - [Install Docker Compose](https://docs.docker.com/compose/install/)

- Ensure that the `alpine` image is available (the script pulls it if not already present).

## Getting Started

1. **Clone the Repository:**
   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```

2. **Set Up Environment Variables:**
   ```bash
   cp .env_sample .env
   # Edit .env as needed:
   nano .env
   ```

3. **Review Configuration Files:**
   - Examine and adjust `docker-compose.yml` and `oc_backup.sh` as necessary.

4. **Start the Services:**
   ```bash
   docker-compose up -d
   ```

## Usage

- **Access the OpenClinica Interface:**  
  Open your browser and navigate to [http://localhost:8080](http://localhost:8080) (or the port defined in your `.env`).

- **Monitor Logs:**  
  To view logs for a service:
  ```bash
  docker-compose logs <service-name>
  ```

- **Stop the Services:**
  ```bash
  docker-compose down
  ```

## Troubleshooting

- **Service Startup:**  
  - Ensure the PostgreSQL container (`pgs`) is fully running before OpenClinica tries to connect.
  - Check logs for errors with:
    ```bash
    docker-compose logs pgs
    docker-compose logs openclinica
    ```

- **Backup Failures:**  
  - Verify that the backup directory exists or update the path in `oc_backup.sh`.
  - Confirm that Docker is running and containers are active.
  - Ensure the `alpine` image is available (it will be pulled if missing).

## Additional Information

- **OpenClinica Support:**  
  For more information on OpenClinica Community Edition, visit the [OpenClinica Community Edition page](https://www.openclinica.com/community-edition-open-source-edc/).

- **Customization:**  
  You can further adjust configurations (such as database credentials, port mappings, and timezone settings) in the `.env` file and `docker-compose.yml` to suit your environment.
