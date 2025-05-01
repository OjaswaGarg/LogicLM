import sqlite3
import duckdb
import re
import pandas as pd
import os

def run_query(sqlite_file_name, sql_file, sql_query):
    # Connect to the database
    conn = sqlite3.connect(sqlite_file_name)
    cursor = conn.cursor()

    # Check if schema already exists
    with open(sql_file, 'r') as f:
        sql_script = f.read()

    # Find all table names from CREATE TABLE statements
    table_names = re.findall(r'CREATE TABLE\s+"?(\w+)"?', sql_script, re.IGNORECASE)

    if table_names:
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name=?;", (table_names[0],))
        if not cursor.fetchone():
            print(f"Applying schema from {sql_file}")
            cursor.executescript(sql_script)

    df = pd.read_sql_query(sql_query, conn)
    

    conn.commit()
    conn.close()
    return df

def run_query_duckdb(sqlite_file_name, sql_file, sql_query):
    """
    Runs a SQL query on a DuckDB database, optionally applying a schema
    from a SQL file if the tables don't exist in the attached SQLite database.

    Args:
        sqlite_file_name (str): The path to the SQLite database file.
        sql_file (str): The path to the SQL file containing the schema.
        sql_query (str): The SQL query to execute.

    Returns:
        pandas.DataFrame: The result of the SQL query as a pandas DataFrame.
    """
    # Connect to an in-memory DuckDB database
    conn = duckdb.connect(':memory:')
    database_name = re.sub(r'\W+', '_', os.path.basename(sqlite_file_name).replace('.', '_')) # Sanitize db name

    try:
        # Attach the SQLite database
        conn.execute(f"ATTACH '{sqlite_file_name}' AS {database_name} (TYPE sqlite);")

        # Check if schema already exists by querying the attached database's tables
        with open(sql_file, 'r') as f:
            sql_script = f.read()

        table_names = re.findall(r'CREATE TABLE\s+"?(\w+)"?', sql_script, re.IGNORECASE)

        if table_names:
            first_table = table_names[0]
            try:
                # Check if the first table exists in the attached SQLite database
                result = conn.execute(f"SELECT 1 FROM {database_name}.{first_table} LIMIT 1;").fetchone()
                if result:
                    print(f"Schema already exists in {sqlite_file_name}. Skipping schema application.")
                else:
                    print(f"Applying schema from {sql_file} to DuckDB")
                    for statement in sql_script.split(';'):
                        cleaned_statement = statement.strip()
                        if cleaned_statement:
                            try:
                                conn.execute(cleaned_statement)
                            except duckdb.ParserException as e:
                                print(f"Error executing schema statement: {cleaned_statement}")
                                print(f"Parser Error: {e}")
            except duckdb.CatalogException:
                print(f"Applying schema from {sql_file} to DuckDB (table check failed)")
                for statement in sql_script.split(';'):
                    cleaned_statement = statement.strip()
                    if cleaned_statement:
                        try:
                            conn.execute(cleaned_statement)
                        except duckdb.ParserException as e:
                            print(f"Error executing schema statement: {cleaned_statement}")
                            print(f"Parser Error: {e}")

        # Run the query against the attached SQLite database
        df = conn.execute(f"SELECT * FROM {database_name}.({sql_query})").fetchdf()

    finally:
        conn.close()

    return df