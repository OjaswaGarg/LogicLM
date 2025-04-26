import sqlite3
import os


def create_tables_from_schema(db_file, schema_file):
    """
    Creates tables in an SQLite database based on the provided schema file.


    Args:
        db_file (str): The path to the SQLite database file.
        schema_file (str): The path to the .schema file containing the CREATE TABLE statements.
    """
    try:
        # Connect to the SQLite database (creates the file if it doesn't exist)
        conn = sqlite3.connect(db_file)
        cursor = conn.cursor()


        # Read the schema from the .schema file, explicitly specifying utf-8 encoding and error handling
        with open(schema_file, 'r', encoding='utf-8', errors='ignore') as f:
            schema_content = f.read()
            # Split the schema into individual CREATE TABLE statements
            statements = schema_content.split(';')
            for statement in statements:
                # Clean up each statement
                statement = statement.strip()
                if statement:  # Make sure the statement is not empty
                    print(f"Executing SQL: {statement}")
                    cursor.execute(statement)
                    print(f"Table created (or already existed).")


        # Commit the changes and close the connection
        conn.commit()
        print("All tables created successfully.")
    except sqlite3.Error as e:
        print(f"Error creating tables: {e}")
        if conn:
            conn.rollback()  # Rollback changes in case of error
    except FileNotFoundError:
        print(f"Error: Schema file not found at {schema_file}")
    finally:
        if conn:
            conn.close()






def run_query(db_file, query, fetch=True):
    """
    Executes an SQL query on the specified SQLite database.


    Args:
        db_file (str): The path to the SQLite database file.
        query (str): The SQL query to execute.
        fetch (bool, optional): Whether to fetch and return the results.
            Defaults to True. If False, returns None.


    Returns:
        list: A list of tuples representing the query results, or None if fetch is False or an error occurs.
              Returns an empty list if the query executes but returns no rows.
    """
    try:
        # Connect to the SQLite database
        conn = sqlite3.connect(db_file)
        cursor = conn.cursor()


        # Execute the SQL query
        print(f"Executing query: {query}")
        cursor.execute(query)


        # Fetch the results if requested
        if fetch:
            results = cursor.fetchall()
            print("Query executed successfully.  Fetching results.")
            return results
        else:
            conn.commit() # Important for non-SELECT queries
            print("Query executed successfully.")
            return None


    except sqlite3.Error as e:
        print(f"Error running query: {e}")
        if conn:
            conn.rollback() # rollback
        return None  # Return None on error


    finally:
        if conn:
            conn.close()




def trying(sqlite_file_name, sql_file, sql_query):
    # Connect to the database
    conn = sqlite3.connect(sqlite_file_name)
    cursor = conn.cursor()


    # Check if schema is already applied (based on first table in SQL file)
    with open(sql_file, 'r') as f:
        sql_script = f.read()


    # Find all table names from CREATE TABLE statements
    import re
    table_names = re.findall(r'CREATE TABLE\s+"?(\w+)"?', sql_script, re.IGNORECASE)


    # Check if first table exists in DB
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
    cursor.execute(sql_query)
    result = cursor.fetchall()


    # Print results
    for row in result:
        print(row)


    conn.commit()
    conn.close()


def main():
    """
    Main function to demonstrate the usage of the functions.
    """
    # Define the database file
    db_file = "my_database.db"  # You can change this name
    schema_file = "my_schema.schema" # Name of the schema file


    # 1. Create the tables in the database
    create_tables_from_schema(db_file, schema_file)


    # 2. Insert some data (example)
    conn = sqlite3.connect(db_file)
    cursor = conn.cursor()


    # Insert data into continents
    cursor.executemany("INSERT INTO continents (Continent) VALUES (?)", [("Asia",), ("Europe",), ("North America",)])


    # Insert data into countries
    cursor.executemany("INSERT INTO countries (CountryName, Continent) VALUES (?, ?)", [("Japan", 1), ("Germany", 2), ("USA", 3)])


    # Insert data into car_makers
    cursor.executemany("INSERT INTO car_makers (Maker, FullName, Country) VALUES (?, ?, ?)", [("Toyota", "Toyota Motor Corporation", 1), ("BMW", "Bayerische Motoren Werke AG", 2), ("Ford", "Ford Motor Company", 3)])


    # Insert data into model_list
    cursor.executemany("INSERT INTO model_list (Maker, Model) VALUES (?, ?)", [(1, "Corolla"), (1, "Camry"), (2, "3 Series"), (2, "5 Series"), (3, "Mustang"), (3, "F-150")])


    # Insert data into car_names
    cursor.executemany("INSERT INTO car_names (Model, Make) VALUES (?, ?)", [("Corolla", "Toyota"), ("Camry", "Toyota"), ("3 Series", "BMW"), ("5 Series", "BMW"), ("Mustang", "Ford"), ("F-150", "Ford")])
   
    # Insert data into cars_data.  Note that the number of values should match
    # the number of columns in the cars_data table.
    cursor.executemany("INSERT INTO cars_data (MPG, Cylinders, Edispl, Horsepower, Weight, Accelerate, Year) VALUES (?, ?, ?, ?, ?, ?, ?)",
                           [("29", 4, 1.8, "132", 2950, 19.0, 2023),
                            ("28", 4, 2.5, "203", 3300, 17.0, 2023),
                            ("25", 4, 2.0, "255", 3500, 16.0, 2023),
                            ("24", 6, 3.0, "335", 4000, 15.0, 2023),
                            ("15", 8, 5.0, "450", 4200, 12.0, 2023),
                            ("17", 6, 3.5, "400", 4500, 13.0, 2023)])


    conn.commit()
    conn.close()
    print("Example data inserted.")


    # 3. Run some SQL queries
    query1 = "SELECT * FROM car_makers;"
    results1 = run_query(db_file, query1)
    if results1:
        print("\nResults of query 1:")
        for row in results1:
            print(row)


    query2 = "SELECT Maker, FullName FROM car_makers WHERE Country = 3;"
    results2 = run_query(db_file, query2)
    if results2:
        print("\nResults of query 2:")
        for row in results2:
            print(row)


    query3 = """
        SELECT cn.Make, cn.Model, cd.MPG, cd.Horsepower
        FROM car_names cn
        JOIN cars_data cd ON cn.MakeId = cd.Id;
        """
    results3 = run_query(db_file, query3)
    if results3:
        print("\nResults of query 3:")
        for row in results3:
            print(row)
   
    query4 = """
        SELECT c.CountryName, cont.Continent
        FROM countries c
        JOIN continents cont ON c.Continent = cont.ContId;
        """
    results4 = run_query(db_file, query4)
    if results4:
        print("\nResults of query 4:")
        for row in results4:
            print(row)


if __name__ == "__main__":
    main()