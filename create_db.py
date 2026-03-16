import MySQLdb

try:
    db = MySQLdb.connect(host='localhost', user='root', passwd='')
    cursor = db.cursor()
    cursor.execute('CREATE DATABASE IF NOT EXISTS buspass_db')
    print('Database buspass_db created successfully!')
except Exception as e:
    print(f'Error creating database: {e}')
