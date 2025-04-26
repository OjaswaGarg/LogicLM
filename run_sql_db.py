import sqlite3
import re

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
        else:
            print("Schema already exists, skipping schema execution.")
    else:
        print("Warning: No tables found in SQL schema.")

    # Execute the SQL query
    print(f"Executing query: {sql_query}")
    cursor.execute(sql_query)
    result = cursor.fetchall()

    # Print results
    for row in result:
        print(row)

    conn.commit()
    conn.close()
