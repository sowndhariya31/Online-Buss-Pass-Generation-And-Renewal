import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'buspass_project.settings')
django.setup()

from django.db import connection

with connection.cursor() as cursor:
    try:
        cursor.execute("ALTER TABLE users_user ADD COLUMN college VARCHAR(200) NULL;")
        cursor.execute("ALTER TABLE users_user ADD COLUMN address LONGTEXT NULL;")
        cursor.execute("ALTER TABLE users_user ADD COLUMN route VARCHAR(100) NULL;")
        cursor.execute("ALTER TABLE users_user ADD COLUMN photo VARCHAR(100) NULL;")
        cursor.execute("ALTER TABLE users_user ADD COLUMN id_proof VARCHAR(100) NULL;")
        cursor.execute("ALTER TABLE users_user ADD COLUMN role VARCHAR(10) NOT NULL DEFAULT 'STUDENT';")
        print('Users table altered manually.')
    except Exception as e:
        print(f'Error altering users table: {e}')
