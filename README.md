# OpenClinica & PostgreSQL with Backup Script

This project provides an OpenClinica Community Edition environment running with a PostgreSQL backend. It includes a Docker Compose configuration to create and link the two services as well as a backup script (`oc_backup.sh`) that automates backups of both the PostgreSQL database and persistent Docker volumes.

## Table of Contents

- [Overview](#overview)
- [Services Description](#services-description)
  - [PostgreSQL Database Service (`pgs`)](#postgresql-database-service-pgs)
  - [OpenClinica Application Service (`openclinica`)](#openclinica-application-service-openclinica)
- [Docker Compose Configuration](#docker-compose-configuration)
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

In addition, the provided `oc_backup.sh` script allows you to create backups of:
- The PostgreSQL database (using `pg_dump`).
- The persistent Docker volumes (`ocdb-data` and `oc-data`) that store database and application data.

## Services Description

### PostgreSQL Database Service (`pgs`)

- **Image:** `postgres:9.4`
- **Ports:** Exposes port `5432` for database access.
- **Environment Variables:**
  - `POSTGRES_DB`: `clinica`
  - `POSTGRES_USER`: `clinica`
  - `POSTGRES_PASSWORD`: `clinica`
- **Volumes:** Uses `ocdb-data` to persist database files.
- **Network:** Connects to the custom network `mynetwork` for internal container communication.

### OpenClinica Application Service (`openclinica`)

- **Image:** `piegsaj/openclinica:oc-3.13`
- **Ports:** Exposes port `8080` for accessing the web interface.
- **Environment Variables:**
  - `LOG_LEVEL`: `INFO`
  - `TZ`: `UTC-1` (Timezone configuration; adjust as needed)
  - **Database Connection Settings:**
    - `DB_TYPE`: `postgres`
    - `DB_HOST`: `pgs`
    - `DB_NAME`: `clinica`
    - `DB_USER`: `clinica`
    - `DB_PASS`: `clinica`
    - `DB_PORT`: `5432`
  - `SUPPORT_URL`: [OpenClinica Community Edition](https://www.openclinica.com/community-edition-open-source-edc/)
- **Dependencies:** Depends on the PostgreSQL container (`pgs`).
- **Volumes:** Uses `oc-data` to persist OpenClinica application data.
- **Network:** Also part of the `mynetwork` bridge network.

## Docker Compose Configuration

The `docker-compose.yml` file defines the two services along with persistent volumes and a custom network:

```yaml
services:
  pgs:
    image: postgres:9.4
    restart: always
    ports:
      - 5432:5432
    environment:
      POSTGRES_DB: clinica
      POSTGRES_USER: clinica
      POSTGRES_PASSWORD: clinica
    volumes:
      - ocdb-data:/var/lib/postgresql/data
    networks:
      - mynetwork

  openclinica:
    image: piegsaj/openclinica:oc-3.13
    restart: always
    ports:
      - 8080:8080
    environment:
      LOG_LEVEL: INFO
      TZ: UTC-1
      DB_TYPE: postgres
      DB_HOST: pgs
      DB_NAME: clinica
      DB_USER: clinica
      DB_PASS: clinica
      DB_PORT: 5432
      SUPPORT_URL: "https://www.openclinica.com/community-edition-open-source-edc/"
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
