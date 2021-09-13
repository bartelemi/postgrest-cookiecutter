#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 \
     --username "{{ cookiecutter.postgresql_user }}" \
     --dbname "postgres" \
     --no-psqlrc \
<<-EOSQL
    create database {{ cookiecutter.project_slug }};

    begin;
    create user authenticator with noinherit login
    password '{{ cookiecutter.authenticator_password }}';
    grant all privileges on database {{ cookiecutter.project_slug }} to authenticator;
    commit;
EOSQL
