#!/usr/bin/env python
from __future__ import print_function
import os, sys, datetime, sqlite3, argparse, time, subprocess
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
            print(e)
 
        return None


def create_table(conn, TABLE_SQL):
    """
    Create a new table in Database "conn" from SQL statements in string "TABLE_SQL"
    """
    try:
        cur = conn.cursor()
        cur.execute(TABLE_SQL)
    except Error as e:
        print(e)


def record_file(conn, record_data):
    """
    Create a new record in database "conn", in table "table", with data in list "record_data"
    """
    SQL = ''' INSERT OR REPLACE INTO files(id,file,age,ftype,st_inode_mode,st_inode,st_dev,st_num_links,st_uid,st_gid,st_size,st_atime,st_mtime,st_ctime)
          VALUES((SELECT id from files where file = :file),:file,:age,:ftype,:st_inode_mode,:st_inode,:st_dev,:st_num_links,:st_uid,:st_gid,:st_size,:st_atime,:st_mtime,:st_ctime) '''
    try:
        cur = conn.cursor()
        cur.execute(SQL, record_data)
    except Error as e:
        print(e)
    else:
        return cur.lastrowid



def stderr_out(*args, **kwargs):
    """
    Print to stderr
    """
    # This is the whole reason we imported the print function from the future.
    print(*args, file=sys.stderr, **kwargs)


def get_file_type(filename):
    """
    Use subprocess or somehting to run the "file" command on a given file.
    Return ascii, bin, or zip based on "file's" response.
    """
    try:
        output = subprocess.check_output(["file", filename])
    except CalledProcessError as e:
        stderr_out("ERROR: {}".format(e))
        return "UNK"

    if "text" in output:
        return "text"
    elif "data" in output:
        if "compressed" in output:
            return "zip"
        else:
            return "data"
    else:
        return "UNK"


# This is where the work is really done
def profile_data(dir_to_search):
    print("Scanning files recursively in: \"{}\". Go have a sammich...".format(dir_to_search))

    now = datetime.datetime.now()
    now_timestamp = time.mktime(now.timetuple())

    for dirpath, dirnames, filenames in os.walk(dir_to_search):
#        if ".snapshot" in dirpath: # Don't think this is needed. os.walk may already ignore hidden files
#            continue

        for file in filenames:
            currpath = os.path.join(dirpath, file)
            try:
                stat_details=os.stat(currpath)
            except OSError, e:
                print("Broken symlink, or file removed during evaluation: %s\n" % currpath)
                continue
            else:
                try:
                    file_mtime = datetime.datetime.fromtimestamp(stat_details.st_mtime)
                except ValueError:
                    print("Could not determine age of file: %s\n" % currpath)
                    continue
                file_size = stat_details.st_size
            # Age of files, relative to now, compared to modify time of files
            age = str(now - file_mtime) # Human readable time format
            age_timestamp = now_timestamp - stat_details.st_mtime # Epoch style time format
            ftype = get_file_type(currpath)
            if ftype == "UNK" and stat_details.st_size == 0:
                ftype = "empty"
            record_contents = {
                'file': currpath, 
                'age': age_timestamp, 
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


def get_stats_from_db(conn, age=86400):
    """
    Analyze the database, extracting only the stats we want.
    "conn" is a database connection object
    "age" is an integer representing the age of a file in seconds
    """
    GET_STATS_SQL = """ select 
                            sum(case when st_size < 1024 then 1 else 0 end) as NoSmallFiles,
                            sum(case when st_size < 1024 then st_size else 0 end) as SizeSmall,
                            sum(case when st_size > 1024 and st_size < 104857600 then 1 else 0 end) as NoMediumFiles,
                            sum(case when st_size > 1024 and st_size < 104857600 then st_size else 0 end) as SizeMedium,
                            sum(case when st_size > 104857600 and st_size < 1073741824 then 1 else 0 end) as NoLargeFiles,
                            sum(case when st_size > 104857600 and st_size < 1073741824 then st_size else 0 end) as SizeLarge,
                            sum(case when st_size > 1073741824 then 1 else 0 end) as NoGiantFiles,
                            sum(case when st_size > 1073741824 then st_size else 0 end) as SizeGiant,
                            sum(case when ftype = "data" then 1 else 0 end) as NoDataFiles,
                            sum(case when ftype = "data" then st_size else 0 end) as SizeDataFiles,
                            sum(case when ftype = "text" then 1 else 0 end) as NoTextFiles,
                            sum(case when ftype = "text" then st_size else 0 end) as SizeTextFiles,
                            sum(case when ftype = "zip" then 1 else 0 end) as NoZipFiles,
                            sum(case when ftype = "zip" then st_size else 0 end) as SizeZipFiles,
                            sum(case when ftype = "empty" then 1 else 0 end) as NoEmptyFiles,
                            sum(case when ftype = "UNK" then 1 else 0 end) as NoUnkFiles,
                            sum(case when ftype = "UNK" then st_size else 0 end) as SizeUnkFiles,
                            sum(st_size) as TotalSize
                        from (select * from files where age < 86400) """

    cur = conn.cursor()
    cur.execute(GET_STATS_SQL)
    rows = cur.fetchall()

    for row in rows:
        return row # single row query, don't care about other rows... yet?

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
            ),
        default = "{}.db".format(os.path.basename(__file__))
        )
    parser.add_argument(
        "--path", "-p",
        help = ("The path that will be scanned"),
        default = "."
        )
    args = parser.parse_args()
    db_file = args.database
    dir_to_search = args.path

    # The required SQL table layout, for generating a new table, if needed.
    FILE_SQL_TABLE = """ CREATE TABLE IF NOT EXISTS files (
                            id integer PRIMARY KEY AUTOINCREMENT,
                            file text NOT NULL,
                            age integer,
                            ftype text,
                            st_inode_mode varchar,
                            st_inode varchar,
                            st_dev varchar,
                            st_num_links integer,
                            st_uid varchar,
                            st_gid varchar,
                            st_size integer,
                            st_atime integer,
                            st_mtime integer,
                            st_ctime integer
                        ); """

    conn = create_connection(db_file)

    with conn:
        create_table(conn, FILE_SQL_TABLE)

        for record in profile_data(dir_to_search):
            record_file(conn, record)

        values = get_stats_from_db(conn)

    keys = [ 
        NumberOfSmallFiles,
        SizeOfSmallFiles,
        NumberOfMediumFiles,
        SizeOfMediumFile,
        NumberOfLargeFiles,
        SizeOfLargeFiles,
        NumberOfGiantFiles,
        SizeOfGiantFiles,
        NumberOfTypeData,
        SizeOfTypeData,
        NumberOfTypeText,
        SizeOfTypeText,
        NumberOfTypeZip,
        SizeOfTypeZip,
        NumberOfTypeEmpty,
        NumberOfTypeUnk,
        SizeOfTypeUnk
        ]

    stats = dict(zip(keys, values))


    # NumberOfSmallFiles = stats[0]
    # SizeOfSmallFiles = stats[1]
    # NumberOfMediumFiles = stats[2]
    # SizeOfMediumFile = stats[3]
    # NumberOfLargeFiles = stats[4]
    # SizeOfLargeFiles = stats[5]
    # NumberOfGiantFiles = stats[6]
    # SizeOfGiantFiles = stats[7]
    # NumberOfTypeData = stats[8]
    # SizeOfTypeData = stats[9]
    # NumberOfTypeText = stats[10]
    # SizeOfTypeText = stats[11]
    # NumberOfTypeZip = stats[12]
    # SizeOfTypeZip = stats[13]
    # NumberOfTypeEmpty = stats[14]
    # NumberOfTypeUnk = stats[15]
    # SizeOfTypeUnk = stats[16]


    print("...Complete\nDatabase has been stored here: {}".format(db_file))


if __name__ == '__main__':
    main()


#Query to get the data I want after scanning.
#select 
#     sum(case when st_size < 1024 then 1 else 0 end) as NoSmallFiles,
#     sum(case when st_size < 1024 then st_size else 0 end) as SizeSmall,
#     sum(case when st_size > 1024 and st_size < 104857600 then 1 else 0 end) as NoMediumFiles,
#     sum(case when st_size > 1024 and st_size < 104857600 then st_size else 0 end) as SizeMedium,
#     sum(case when st_size > 104857600 and st_size < 1073741824 then 1 else 0 end) as NoLargeFiles
#     sum(case when st_size > 104857600 and st_size < 1073741824 then st_size else 0 end) as SizeLarge
#     sum(case when st_size > 1073741824 then 1 else 0 end) as NoGiantFiles,
#     sum(case when st_size > 1073741824 then st_size else 0 end) as SizeGiant
# from (select * from files where age < 86400)

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


