echo "
# LOG LOCATION
log_destination = stderr
logging_collector = true

# ERROR REPORTING AND LOGGING
log_statement = all
log_min_duration_statement = 0
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
log_temp_files = 0
log_autovacuum_min_duration = 0
log_duration = on

# Locale
timezone = '{{ cookiecutter.timezone }}'
" >> /var/lib/postgresql/data/postgresql.conf