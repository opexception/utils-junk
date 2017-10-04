#!/usr/bin/env python
import os, sys, datetime, sqlite3, argparse
from sqlite3 import Error

#
#    A quick and dirty script to gather details about all files under a given 
#      directory root.
#


#Database Stuff
def create_connection(db_file):
        """ 
        create a database connection to the SQLite database
        specified by the db_file
        :param db_file: database file
        :return: Connection object or None
        """
        try:
            conn = sqlite3.connect(db_file)
            return conn
        except Error as e:
            print e
 
        return None


def create_table(conn, TABLE_SQL):
    """
    Create a new table in Database "conn" from SQL statements in string "TABLE_SQL"
    """
    try:
        cur = conn.cursor()
        cur.execute(TABLE_SQL)
    except Error as e:
        print e


def record_file(conn, record_data):
    """
    Create a new record in database "conn", in table "table", with data in list "record_data"
    """
    #SQL = ''' INSERT INTO files(file,age,ftype,st_inode_mode,st_inode,st_dev,st_num_links,st_uid,st_gid,st_size,st_atime,st_mtime,st_ctime)
    #          VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?) '''
    SQL = ''' INSERT OR REPLACE INTO files(id,file,age,ftype,st_inode_mode,st_inode,st_dev,st_num_links,st_uid,st_gid,st_size,st_atime,st_mtime,st_ctime)
          VALUES((SELECT id from files where file = :file),:file,:age,:ftype,:st_inode_mode,:st_inode,:st_dev,:st_num_links,:st_uid,:st_gid,:st_size,:st_atime,:st_mtime,:st_ctime) '''
    try:
        cur = conn.cursor()
        cur.execute(SQL, record_data)
    except Error as e:
        print e
    else:
        return cur.lastrowid


# This is where the work is really done
def profile_data(dir_to_search):
    print "Scanning files recursively in current directory. Go have a sammich."

    now = datetime.datetime.now()
    for dirpath, dirnames, filenames in os.walk(dir_to_search):
        for file in filenames:
            currpath = os.path.join(dirpath, file)
            try:
                stat_details=os.stat(currpath)
            except OSError, e:
                print "Broken symlink, or file removed during evaluation: %s\n" % currpath
                continue
            else:
                try:
                    file_mtime = datetime.datetime.fromtimestamp(stat_details.st_mtime)
                except ValueError:
                    print "Could not determine age of file: %s\n" % currpath
                    continue
                file_size = stat_details.st_size
            # Age of files, relative to now, compared to modify time of files
            age = str(now - file_mtime)
            ftype = "unk"
            # record_contents = [
            #                     currpath, 
            #                     age, 
            #                     ftype, 
            #                     stat_details.st_mode, 
            #                     stat_details.st_ino, 
            #                     stat_details.st_dev, 
            #                     stat_details.st_nlink, 
            #                     stat_details.st_uid, 
            #                     stat_details.st_gid, 
            #                     stat_details.st_size, 
            #                     stat_details.st_atime, 
            #                     stat_details.st_mtime, 
            #                     stat_details.st_ctime]
            record_contents = {
                'file': currpath, 
                'age': age, 
                'ftype': ftype, 
                'st_inode_mode': stat_details.st_mode, 
                'st_inode': stat_details.st_ino, 
                'st_dev': stat_details.st_dev, 
                'st_num_links': stat_details.st_nlink, 
                'st_uid': stat_details.st_uid, 
                'st_gid': stat_details.st_gid, 
                'st_size': stat_details.st_size, 
                'st_atime': stat_details.st_atime, 
                'st_mtime': stat_details.st_mtime, 
                'st_ctime': stat_details.st_ctime
                }
            yield record_contents



def main():

    parser = argparse.ArgumentParser(
        description = (
            "Gather all \"stat()\" data about files in a given directory."
            " Store all that in a database for later analysis"
            )
        )
    parser.add_argument(
        "--database", "-d",
        help = (
            "The database file to use. If file does not exist, it will be created."
            )
        )
    parser.add_argument(
        "--path", "-p",
        help = ("The path that will be scanned")
        )
    args = parser.parse_args()
    db_file = args.database
    dir_to_search = args.path

    # The required SQL table layout, for generating a new table, if needed.
    FILE_SQL_TABLE = """ CREATE TABLE IF NOT EXISTS files (
                            id integer PRIMARY KEY AUTOINCREMENT,
                            file text NOT NULL,
                            age text,
                            ftype text,
                            st_inode_mode varchar,
                            st_inode varchar,
                            st_dev varchar,
                            st_num_links integer,
                            st_uid varchar,
                            st_gid varchar,
                            st_size varchar,
                            st_atime integer,
                            st_mtime integer,
                            st_ctime integer
                        ); """

    conn = create_connection(db_file)
    # if conn is not None:
    #     create_table(conn, FILE_SQL_TABLE)
    # else:
    #     print "ERROR: Cannot create database connection!"

    with conn:
        create_table(conn, FILE_SQL_TABLE)

        for record in profile_data(dir_to_search):
            print record
            record_file(conn, record)


if __name__ == '__main__':
    main()


# scan files, store path/name and all attributes. Dump attributes to sqlite db
# analyze files. Number of files, and total size in each group
# - <1KB
# - 1KB < < 4KB
# - 4K < < 1M
# - 1M < < 10M
# - 10 < < 1G
# - >1G
# run `file` command on each file to determine type. also store if bin/ascii
# analyze to determine # of files of type bin/ascii in each group.
#


