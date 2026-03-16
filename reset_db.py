import pymysql

try:
    db = pymysql.connect(host='localhost', user='root', password='')
    cursor = db.cursor()
    cursor.execute('DROP DATABASE IF EXISTS buspass_db')
    cursor.execute('CREATE DATABASE buspass_db')
    print('Database buspass_db reset successfully!')
except Exception as e:
    print(f'Error resetting database: {e}')
