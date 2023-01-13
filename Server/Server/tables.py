import mysql.connector
from mysql.connector import errorcode

class Tables:
    TABLES = {}

    TABLES['users'] = (
        "CREATE TABLE `users` ("
        "  `user_id` int(11) NOT NULL AUTO_INCREMENT,"
        "  `name` varchar(128) NOT NULL,"
        "  `login_id` varchar(128) NOT NULL,"
        "  `key` varchar(128) NOT NULL,"
        "  `joined` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        "  `location_id` int(11) DEFAULT 0,"
        "  `status` int(4) DEFAULT 0,"
        "  `devices` int(6) DEFAULT 0,"
        "  `attrib_id` int(11) DEFAULT 0,"
        "  `picture` varchar(256) NOT NULL DEFAULT '',"
        "  PRIMARY KEY (`user_id`),"
        "  UNIQUE KEY `login_id` (`login_id`),"
        "  KEY `name` (`name`)"
        ") ENGINE=InnoDB"
    )

    TABLES['glasses'] = (
        " CREATE TABLE `glasses` ("
        " `grecord_id` int(11) NOT NULL,"
        " `glass` varchar(100),"
        " `count` int(11),"
        " `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        " `modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        "  PRIMARY KEY (`grecord_id`)"
        ") ENGINE=InnoDB"
    )

    TABLES['categories'] = (
        " CREATE TABLE `categories` ("
        " `crecord_id` int(11) NOT NULL,"
        " `category` varchar(100),"
        " `count` int(11),"
        " `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        " `modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        "  PRIMARY KEY (`crecord_id`)"
        ") ENGINE=InnoDB"
    )

    TABLES['hard_drinks'] = (
        " CREATE TABLE `hard_drinks` ("
        " `record_id` int(11) NOT NULL,"
        " `name` varchar(250) NOT NULL,"
        " `ingredients` text,"
        " `instructions` text,"
        " `rating` int(4) DEFAULT 0,"
        " `comments` text,"
        " `user_id` int(11) DEFAULT 0,"
        " `shopping` TEXT,"
        " `category_id` int(11),"
        " `shopcount` int(11) DEFAULT 0,"
        " `glass_id` int(11),"
        " `shopping_ids` LONGBLOB,"
        " `enabled` boolean,"
        " `unlocked` boolean,"
        " `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        " `modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        "  PRIMARY KEY (`record_id`, `name`), KEY `name` (`name`),"
        " CONSTRAINT `hard_drinks_ibfk_1`"
        " FOREIGN KEY (`glass_id`) REFERENCES `glasses` (`grecord_id`) ON DELETE CASCADE,"
        " CONSTRAINT `hard_drinks_ibfk_2`"
        " FOREIGN KEY (`category_id`) REFERENCES `categories` (`crecord_id`) ON DELETE CASCADE"
        ") ENGINE=InnoDB"
    )

    TABLES['soft_drinks'] = (
        " CREATE TABLE `soft_drinks` ("
        " `record_id` int(11) NOT NULL,"
        " `name` varchar(250) NOT NULL,"
        " `ingredients` text,"
        " `instructions` text,"
        " `rating` int(4) DEFAULT 0,"
        " `comments` text,"
        " `user_id` int(11) DEFAULT 0,"
        " `shopping` text,"
        " `category_id` int(11),"
        " `shopcount` int(11) DEFAULT 0,"
        " `glass_id` int(11),"
        " `shopping_ids` blob,"
        " `enabled` boolean,"
        " `unlocked` boolean,"
        " `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        " `modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        "  PRIMARY KEY (`record_id`, `name`), KEY `name` (`name`),"
        " CONSTRAINT `soft_drinks_ibfk_1`"
        " FOREIGN KEY (`glass_id`) REFERENCES `glasses` (`grecord_id`) ON DELETE CASCADE,"
        " CONSTRAINT `soft_drinks_ibfk_2`"
        " FOREIGN KEY (`category_id`) REFERENCES `categories` (`crecord_id`) ON DELETE CASCADE"
        ") ENGINE=InnoDB"
    )

    TABLES['ingredient_types'] = (
        " CREATE TABLE `ingredient_types` ("
        " `record_id` int(11) NOT NULL,"
        " `category` varchar(100) NOT NULL,"
        " `category_id` int(11),"
        " `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        " `modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        "  PRIMARY KEY (`record_id`)"
        ") ENGINE=InnoDB"
    )

    TABLES['ingredients'] = (
        " CREATE TABLE `ingredients` ("
        " `record_id` int(11) NOT NULL,"
        " `item` varchar(100) NOT NULL,"
        " `used` int(11),"
        " `options` int(11),"
        " `enabled` boolean,"
        " `enabled_default` boolean,"
        " `category_id` int(11),"
        " `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        " `modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        "  PRIMARY KEY (`record_id`),"
        " CONSTRAINT `ingredients_ibfk_1`"
        " FOREIGN KEY(`category_id`) REFERENCES `ingredient_types`(`record_id`) ON DELETE CASCADE"
        ") ENGINE=InnoDB"
    )

    TABLES['user_ext'] = (
        "CREATE TABLE `user_ext` ("
        "  `ext_id` int(11) NOT NULL AUTO_INCREMENT,"
        "  `user_id` int(11) NOT NULL,"
        "  `pin` varchar(16),"
        "  `date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        "  PRIMARY KEY (`ext_id`,`user_id`), KEY `user_id` (`user_id`),"
        "  CONSTRAINT `ext_ibfk_1` FOREIGN KEY (`user_id`) "
        "     REFERENCES `users` (`user_id`) ON DELETE CASCADE"
        ") ENGINE=InnoDB"
    )

    TABLES['upgrades'] = (
        "CREATE TABLE `upgrades` ("
        "  `upgrade_id` int(11) NOT NULL AUTO_INCREMENT,"
        "  `user_id` int(11) NOT NULL,"
        "  `upgrade_code` varchar(80) NOT NULL,"
        "  `type` int(6) DEFAULT 0,"
        "  `asset` int(6) DEFAULT 0,"
        "  `date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        "  PRIMARY KEY (`upgrade_id`),"
        "  KEY `upgrade_code` (`upgrade_code`)"
        ") ENGINE=InnoDB"
    )

    TABLES['user_attrib'] = (
        "CREATE TABLE `user_attrib` ("
        "  `attrib_id` int(11) NOT NULL AUTO_INCREMENT,"
        "  `user_id` int(11) NOT NULL,"

        "  `sent` int(11) DEFAULT 0,"
        "  `received` int(11) DEFAULT 0,"
        "  `chats_in` int(11) DEFAULT 0,"
        "  `chats_out` int(11) DEFAULT 0,"

        "  `limit_teleportations` int(11) DEFAULT 10,"
        "  `limit_devices` int(6) DEFAULT 5,"
        "  `limit_chats` int(11) DEFAULT 100,"
        "  `attributes` int(11) DEFAULT 15,"
        # attributes:
        # 0x0001 - can receive teleports,           15      255     511
        # 0x0002 - can send teleports (limit),
        # 0x0004 - can receive chats,
        # 0x0008 - can send chats (limit),
        # 0x0010 - unilimited send,                 240
        # 0x0020 - unlimited chats,
        # 0x0040 - unlimited devices,
        # 0x0100 - expiration date limit,           256
        # ... TBD
        "  `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        "  `modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        "  `expires` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        "  PRIMARY KEY (`attrib_id`,`user_id`), KEY `user_id` (`user_id`),"
        "  CONSTRAINT `attrib_ibfk_1` FOREIGN KEY (`user_id`) "
        "     REFERENCES `users` (`user_id`) ON DELETE CASCADE"
        ") ENGINE=InnoDB"
    )

    TABLES['sessions'] = (
        "CREATE TABLE `sessions` ("
        "  `session_id` int(11) NOT NULL AUTO_INCREMENT,"
        "  `user_id` int(11) NOT NULL,"
        "  `session_uuid` varchar(64) NOT NULL,"
        "  `started` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        "  `expires` datetime NOT NULL,"
        "  PRIMARY KEY (`session_id`,`user_id`), KEY `user_id` (`user_id`),"
        "  CONSTRAINT `sessions_ibfk_1` FOREIGN KEY (`user_id`) "
        "     REFERENCES `users` (`user_id`) ON DELETE CASCADE"
        ") ENGINE=InnoDB"
    )

    TABLES['clients'] = (
        "CREATE TABLE `clients` ("
        "  `client_id` int(11) NOT NULL AUTO_INCREMENT,"
        "  `secret` varchar(64) NOT NULL,"
        "  `client_uuid` varchar(128) NOT NULL,"
        "  `added` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        "  `name` varchar(128) NOT NULL,"
        "  `os` varchar(20) NOT NULL,"
        "  `version` int(6) DEFAULT 1,"
        "  PRIMARY KEY (`client_id`),"
        "  UNIQUE KEY `client_uuid` (`client_uuid`),"
        "  KEY `name` (`name`)"
        ") ENGINE=InnoDB"
    )

    TABLES['devices'] = (
        "CREATE TABLE `devices` ("
        "  `device_id` int(11) NOT NULL AUTO_INCREMENT,"
        "  `user_id` int(11) NOT NULL,"
        "  `name` varchar(128) NOT NULL,"
        "  `device_token` varchar(80) NOT NULL,"
        "  `os` varchar(20) NOT NULL,"
        "  `version` int(6) DEFAULT 1,"
        "  `added` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        "  `status` int(11) DEFAULT 0,"
        "  `pin` varchar(10),"
        "  `production` tinyint(1) DEFAULT 0,"
        "  PRIMARY KEY (`device_id`,`user_id`), KEY `user_id` (`user_id`),"
        "  UNIQUE KEY `device_token` (`device_token`),"
        "  CONSTRAINT `devices_ibfk_1` FOREIGN KEY (`user_id`) "
        "     REFERENCES `users` (`user_id`) ON DELETE CASCADE"
        ") ENGINE=InnoDB"
    )

    TABLES['locations'] = (
        "CREATE TABLE `locations` ("
        "  `location_id` int(11) NOT NULL AUTO_INCREMENT,"
        "  `lati` float(10,6) DEFAULT 0.0,"
        "  `longi` float(10,6) DEFAULT 0.0,"
        "  `address` varchar(255),"
        "  `version` int(6) DEFAULT 1,"
        "  `added` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        "  PRIMARY KEY (`location_id`)"
        ") ENGINE=InnoDB"
    )

    TABLES['peripherals'] = (
        "CREATE TABLE `peripherals` ("
        "  `peripheral_id` int(11) NOT NULL AUTO_INCREMENT,"
        "  `user_id` int(11) NOT NULL,"
        "  `location_id` int(11) DEFAULT 0,"
        "  `name` varchar(128) NOT NULL,"
        "  `serial_number` char(64) NOT NULL,"
        "  `added` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        "  `status` int(4) DEFAULT 0,"
        "  `type` int(8) NOT NULL,"
        "  `version` int(6) DEFAULT 1,"
        "  PRIMARY KEY (`peripheral_id`,`user_id`), KEY `user_id` (`user_id`),"
        "  UNIQUE KEY `serial_number` (`serial_number`),"
        "  CONSTRAINT `peripherals_ibfk_1` FOREIGN KEY (`user_id`) "
        "     REFERENCES `users` (`user_id`) ON DELETE CASCADE"
        ") ENGINE=InnoDB"
    )

    TABLES['push_queue'] = (
        "CREATE TABLE `push_queue` ("
        "  `queue_id` int(11) NOT NULL AUTO_INCREMENT,"
        "  `device_id` int(11) NOT NULL,"
        "  `device_token` char(64) NOT NULL,"
        "  `os` varchar(20) NOT NULL,"
        "  `alert` varchar(255),"
        "  `custom` varchar(255),"
        "  `badge` int(8),"
        "  `sound` char(64),"
        "  `sent` datetime,"
        "  `expires` datetime,"
        "  `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        "  `production` tinyint(1) DEFAULT 0,"
        "  `content` tinyint(1) DEFAULT 0,"
        "  `retry_count` int(4) DEFAULT 1,"
        "  PRIMARY KEY (`queue_id`,`device_id`),"
        "  KEY `device_id` (`device_id`),"
        "  CONSTRAINT `queue_ibfk_1` FOREIGN KEY (`device_id`) "
        "     REFERENCES `devices` (`device_id`) ON DELETE CASCADE"
        ") ENGINE=InnoDB"
    )

    TABLES['active_requests'] = (
        "CREATE TABLE `active_requests` ("
        "  `request_id` int(11) NOT NULL AUTO_INCREMENT,"
        "  `from_user_id` int(11) NOT NULL,"
        "  `to_user_id` int(11) NOT NULL,"
        "  `from_token` char(64) NOT NULL,"
        "  `to_token` char(64),"
        "  `status` int(8) DEFAULT 0,"
        "  `expires` datetime,"
        "  `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        "  `type` int(8) DEFAULT 0,"
        "  PRIMARY KEY (`request_id`)"
        ") ENGINE=InnoDB"
     )

    def __init__(self, cursor):
        self.cursor = cursor

    # Create static tables

    def createTable(self, name):
        try:
            print("Creating table {}: ".format(name))
            ddl = self.TABLES[name]
            self.cursor.execute(ddl)
        except mysql.connector.Error as err:
            if err.errno == errorcode.ER_TABLE_EXISTS_ERROR:
                print("already exists.")
            else:
                print(err.msg)
        else:
            print("OK")

    def createAllTables(self):
        for name, ddl in self.TABLES.items():
            print( 'creating database ' + name )
            self.createTable(name)

    def dropAllTables(self):
        for name, ddl in reversed(self.TABLES.items()):
            print( "Deleting database " + name )
            try:
                sql = "DROP TABLE " + name
                self.cursor.execute(sql)
            except mysql.connector.Error as err:
                print(err.msg)

    def dropTable(self, name):
        print( "Deleting database " + name )
        try:
            sql = "DROP TABLE " + name
            self.cursor.execute(sql)
        except mysql.connector.Error as err:
            print(err.msg)
