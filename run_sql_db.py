import sqlite3
import re
import pandas as pd

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
