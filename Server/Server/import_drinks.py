from database import Database
from api_setup import _config
import sqlite3

class ImportDrinks:
    # init method or constructor
    def __init__(self, dbname):
        self.conn = sqlite3.connect(dbname)
        self.cur = self.conn.cursor()

        self.db = Database(
            host = _config['db_url'],
            user = _config['db_login'],
            password = _config['db_pass'],
            database_name = _config['db_name'],
            ssl_ca = _config['db_cert'])

        if not self.db.connect():
            print('Cant open database')
            quit()

    def read_from_db(self, name):
        self.cur.execute('SELECT * FROM ' + name)
        data = self.cur.fetchall()
        return data

    def import_glass_table(self):
        data = self.read_from_db('glasses')
        for d in data:
            sql = "INSERT INTO glasses (grecord_id, glass, count) VALUES (%d, '%s', %d)" % (d[0], d[1], d[2])
            self.db.execute_insert_sql(sql)

    def import_categories_table(self):
        data = self.read_from_db('categories')
        for d in data:
            sql = "INSERT INTO categories (crecord_id, category, count) VALUES (%d, '%s', %d)" % (d[0], d[1], d[2])
            self.db.execute_insert_sql(sql)

    def import_ingredients_table(self):
        data = self.read_from_db('ingredients')
        for d in data:
            sql = """INSERT INTO ingredients (record_id, item, used, options, enabled, enabled_default, category_id) VALUES (%d, "%s", %d, %d, %d, %d, %d)""" % (d[0], d[1], d[2], d[3], d[4], d[5], d[6])
            self.db.execute_insert_sql(sql)

    def import_ingredient_types_table(self):
        data = self.read_from_db('ingredient_types')
        for d in data:
            sql = """INSERT INTO ingredient_types (record_id, category, category_id) VALUES (%d, "%s", %d)""" % (d[0], d[1], d[2])
            self.db.execute_insert_sql(sql)

    def import_drinks_table(self, alcohol=True):
        table = "hard_drinks" if (alcohol is True) else "soft_drinks"
        data = self.read_from_db(table)
        for d in data:
            sql = """INSERT INTO """ + table
            sql = sql + """ (record_id, name, ingredients, instructions, rating, comments, user_id, shopping, category_id, shopcount, glass_id, shopping_ids, enabled, unlocked) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"""
            insert_blob_tuple = (d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7], d[8], d[9], d[10], d[11], d[12], d[13])
            self.db.execute_insert_sql(sql, insert_blob_tuple)

    def import_all(self):
        print("Importing ingredients...")
        self.import_categories_table()
        self.import_ingredient_types_table()
        self.import_glass_table()
        self.import_ingredients_table()
        print("Importing drinks...")
        self.import_drinks_table(True)
        self.import_drinks_table(False)
        print("Importing complete.")

if __name__ == "__main__":
    i = ImportDrinks('../../database/drinks.sql')
    i.import_all()
