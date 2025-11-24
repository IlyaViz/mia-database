data\.venv\Scripts\python.exe data\generate.py
psql postgresql://postgres:Winter2005@localhost:5432/postgres -c "DROP DATABASE IF EXISTS mia;"
psql postgresql://postgres:Winter2005@localhost:5432/postgres -f creation/db.sql
psql postgresql://postgres:Winter2005@localhost:5432/mia -f creation/tables.sql
psql postgresql://postgres:Winter2005@localhost:5432/mia -f creation/roles.sql
psql postgresql://postgres:Winter2005@localhost:5432/mia -f functions.sql
psql postgresql://postgres:Winter2005@localhost:5432/mia -f views.sql
psql postgresql://postgres:Winter2005@localhost:5432/mia -f procedures.sql
psql postgresql://postgres:Winter2005@localhost:5432/mia -f triggers.sql
psql postgresql://postgres:Winter2005@localhost:5432/mia -f data/load.sql
pause