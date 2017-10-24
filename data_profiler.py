#!/usr/bin/env python
from __future__ import print_function
import os, sys, datetime, sqlite3, argparse, time, subprocess, string, random, uuid, zlib
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

            if stat_details.st_size == 0:
                ftype = "empty"
            else:
                ftype = get_file_type(currpath)

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


def characterize_stats(stats):
    """
    Given the dictionary "stats", calculate some some, errr... stats from it.
    """

    # Total all files up
    numberOfFiles = stats['NumberOfSmallFiles']+stats['NumberOfMediumFiles']+stats['NumberOfLargeFiles']+stats['NumberOfGiantFiles']+stats['NumberOfTypeEmpty']
    
    # Begin characterizing each group with percentages of size and quantity for each demographic.
    characterized = {
        'smallFiles':{
            'perOfTotalNumber':float(stats['NumberOfSmallFiles'])/numberOfFiles, 
            'perOfTotalSize':float(stats['SizeOfSmallFiles'])/stats['TotalSize']
            },
        'mediumFiles':{
            'perOfTotalNumber':float(stats['NumberOfMediumFiles'])/numberOfFiles,
            'perOfTotalSize':float(stats['SizeOfMediumFiles'])/stats['TotalSize']
            },
        'largeFiles':{
            'perOfTotalNumber':float(stats['NumberOfLargeFiles'])/numberOfFiles,
            'perOfTotalSize':float(stats['SizeOfLargeFiles'])/stats['TotalSize']
            },
        'giantFiles':{
            'perOfTotalNumber':float(stats['NumberOfGiantFiles'])/numberOfFiles,
            'perOfTotalSize':float(stats['SizeOfGiantFiles'])/stats['TotalSize']
            },
        'emptyFiles':{
            'perOfTotalNumber':float(stats['NumberOfTypeEmpty'])/numberOfFiles,
            'perOfTotalSize':0,
            'avgSize':0
            },
        'totalFiles':numberOfFiles,
        'totalSize':stats['TotalSize']
        }

    if stats['NumberOfSmallFiles'] == 0:
        characterized['smallFiles']['perData'] = 0
        characterized['smallFiles']['perText'] = 0
        characterized['smallFiles']['perZip'] = 0
        characterized['smallFiles']['perUnk'] = 0
        characterized['smallFiles']['avgSize'] = 0
    else:
        characterized['smallFiles']['perData'] = float(stats['SmallData'])/stats['NumberOfSmallFiles']
        characterized['smallFiles']['perText'] = float(stats['SmallText'])/stats['NumberOfSmallFiles']
        characterized['smallFiles']['perZip'] = float(stats['SmallZip'])/stats['NumberOfSmallFiles']
        characterized['smallFiles']['perUnk'] = float(stats['SmallZip'])/stats['NumberOfSmallFiles']
        characterized['smallFiles']['avgSize'] = float(stats['SizeOfSmallFiles'])/stats['NumberOfSmallFiles']

    if stats['NumberOfMediumFiles'] == 0:
        characterized['mediumFiles']['perData'] = 0
        characterized['mediumFiles']['perText'] = 0
        characterized['mediumFiles']['perZip'] = 0
        characterized['mediumFiles']['perUnk'] = 0
        characterized['mediumFiles']['avgSize'] = 0
    else:
        characterized['mediumFiles']['perData'] = float(stats['MediumData'])/stats['NumberOfMediumFiles']
        characterized['mediumFiles']['perText'] = float(stats['MediumText'])/stats['NumberOfMediumFiles']
        characterized['mediumFiles']['perZip'] = float(stats['MediumZip'])/stats['NumberOfMediumFiles']
        characterized['mediumFiles']['perUnk'] = float(stats['MediumUnk'])/stats['NumberOfMediumFiles']
        characterized['mediumFiles']['avgSize'] = float(stats['SizeOfMediumFiles'])/stats['NumberOfMediumFiles']

    if stats['NumberOfLargeFiles'] == 0:
        characterized['largeFiles']['perData'] = 0
        characterized['largeFiles']['perText'] = 0
        characterized['largeFiles']['perZip'] = 0
        characterized['largeFiles']['perUnk'] = 0
        characterized['largeFiles']['avgSize'] = 0
    else:
        characterized['largeFiles']['perData'] = float(stats['LargeData'])/stats['NumberOfLargeFiles']
        characterized['largeFiles']['perText'] = float(stats['LargeText'])/stats['NumberOfLargeFiles']
        characterized['largeFiles']['perZip'] = float(stats['LargeZip'])/stats['NumberOfLargeFiles']
        characterized['largeFiles']['perUnk'] = float(stats['LargeUnk'])/stats['NumberOfLargeFiles']
        characterized['largeFiles']['avgSize'] = float(stats['SizeOfLargeFiles'])/stats['NumberOfLargeFiles']

    if stats['NumberOfGiantFiles'] == 0:
        characterized['giantFiles']['perData'] = 0
        characterized['giantFiles']['perText'] = 0
        characterized['giantFiles']['perZip'] = 0
        characterized['giantFiles']['perUnk'] = 0
        characterized['giantFiles']['avgSize'] = 0
    else:
        characterized['giantFiles']['perData'] = float(stats['GiantData'])/stats['NumberOfGiantFiles']
        characterized['giantFiles']['perText'] = float(stats['GiantText'])/stats['NumberOfGiantFiles']
        characterized['giantFiles']['perZip'] = float(stats['GiantZip'])/stats['NumberOfGiantFiles']
        characterized['giantFiles']['perUnk'] = float(stats['GiantUnk'])/stats['NumberOfGiantFiles']
        characterized['giantFiles']['avgSize'] = float(stats['SizeOfGiantFiles'])/stats['NumberOfGiantFiles']

    if stats['NumberOfTypeEmpty'] == 0:
        characterized['emptyFiles']['perData'] = 0
        characterized['emptyFiles']['perText'] = 0
        characterized['emptyFiles']['perZip'] = 0
        characterized['emptyFiles']['perUnk'] = 0
    else:
        characterized['emptyFiles']['perData'] = float(stats['NumberOfTypeEmpty'])/numberOfFiles
        characterized['emptyFiles']['perText'] = 0
        characterized['emptyFiles']['perZip'] = 0
        characterized['emptyFiles']['perUnk'] = 0
    
    return characterized


def get_stats_from_db(conn, age=86400):
    """
    Analyze the database, extracting only the stats we want.
    "conn" is a database connection object
    "age" is an integer representing the age of a file in seconds
    """
    GET_STATS_SQL = """ select 
                            sum(case when st_size > 0 and st_size <= 1024 then 1 else 0 end) as NoSmallFiles,
                            sum(case when st_size > 0 and st_size <= 1024 then st_size else 0 end) as SizeSmall,
                            sum(case when st_size > 0 and st_size <= 1024 and ftype = "data" then 1 else 0 end) as SmallData,
                            sum(case when st_size > 0 and st_size <= 1024 and ftype = "text" then 1 else 0 end) as SmallText,
                            sum(case when st_size > 0 and st_size <= 1024 and ftype = "zip" then 1 else 0 end) as SmallZip,
                            sum(case when st_size > 0 and st_size <= 1024 and ftype = "UNK" then 1 else 0 end) as SmallUnk,
                            sum(case when st_size > 1024 and st_size <= 104857600 then 1 else 0 end) as NoMediumFiles,
                            sum(case when st_size > 1024 and st_size <= 104857600 then st_size else 0 end) as SizeMedium,
                            sum(case when st_size > 1024 and st_size <= 104857600 and ftype = "data" then 1 else 0 end) as MediumData,
                            sum(case when st_size > 1024 and st_size <= 104857600 and ftype = "text" then 1 else 0 end) as MediumText,
                            sum(case when st_size > 1024 and st_size <= 104857600 and ftype = "zip" then 1 else 0 end) as MediumZip,
                            sum(case when st_size > 1024 and st_size <= 104857600 and ftype = "UNK" then 1 else 0 end) as MediumUnk,
                            sum(case when st_size > 104857600 and st_size <= 1073741824 then 1 else 0 end) as NoLargeFiles,
                            sum(case when st_size > 104857600 and st_size <= 1073741824 then st_size else 0 end) as SizeLarge,
                            sum(case when st_size > 104857600 and st_size <= 1073741824 and ftype = "data" then 1 else 0 end) as LargeData,
                            sum(case when st_size > 104857600 and st_size <= 1073741824 and ftype = "text" then 1 else 0 end) as LargeText,
                            sum(case when st_size > 104857600 and st_size <= 1073741824 and ftype = "zip" then 1 else 0 end) as LargeZip,
                            sum(case when st_size > 104857600 and st_size <= 1073741824 and ftype = "UNK" then 1 else 0 end) as LargeUnk,
                            sum(case when st_size > 1073741824 then 1 else 0 end) as NoGiantFiles,
                            sum(case when st_size > 1073741824 then st_size else 0 end) as SizeGiant,
                            sum(case when st_size > 1073741824 and ftype = "data" then 1 else 0 end) as GiantData,
                            sum(case when st_size > 1073741824 and ftype = "text" then 1 else 0 end) as GiantText,
                            sum(case when st_size > 1073741824 and ftype = "zip" then 1 else 0 end) as GiantZip,
                            sum(case when st_size > 1073741824 and ftype = "UNK" then 1 else 0 end) as GiantUnk,
                            sum(case when ftype = "data" then 1 else 0 end) as NoDataFiles,
                            sum(case when ftype = "text" then 1 else 0 end) as NoTextFiles,
                            sum(case when ftype = "zip" then 1 else 0 end) as NoZipFiles,
                            sum(case when ftype = "empty" then 1 else 0 end) as NoEmptyFiles,
                            sum(case when ftype = "UNK" then 1 else 0 end) as NoUnkFiles,
                            sum(st_size) as TotalSize
                        from (select * from files where age < {}) """.format(age)

    cur = conn.cursor()
    cur.execute(GET_STATS_SQL)
    rows = cur.fetchall()

    for row in rows:
        return row # single row query, don't care about other rows... yet?

        
def generate_ascii(size):
    rand_str = lambda n: ''.join([random.choice(string.lowercase) for i in xrange(n)])
    ascii_string = rand_str(size)

    return ascii_string


def generate_data(size):
    data = bytearray(os.urandom(size))

    return data

def generate_zip(size):

    zip = zlib.compress(os.urandom(size), 9)

    return zip

def get_num_and_size(total_size, total_files, percentFiles, percentSize, percentData, percentText, percentZip):
    """
    Determine how many files of each demographic to create, and their average size, each.
    """
    numOfFiles = total_files*percentFiles
    #DEBUG
    #print(numOfFiles)

    if numOfFiles > 0:
        avgSizeOfFile = int((total_size*percentSize)/numOfFiles)
        numOfData = int(numOfFiles*percentData)
        numOfText = int(numOfFiles*percentText)
        numOfZip = int(numOfFiles*percentZip)
    else:
        avgSizeOfFile = 0
        numOfData = 0
        numOfText = 0
        numOfZip = 0

    return numOfFiles, avgSizeOfFile, numOfData, numOfText, numOfZip


def dump_file(group, name, content, path):
    """
    Write the given contents to a file
    """

    name = str(name)
    group = str(group)
    path = str(path)

    if os.path.isdir(path):
        subPath = os.path.join(path, name, group)
        if os.path.isdir(subPath):
            unique_filename = str(uuid.uuid4())
            myFile = os.path.join(subPath, unique_filename)
        elif os.path.exists(subPath):
            stderr_out("This should be a directory, not a file: {}".format(os.path.join))
            sys.exit(1)
        else:
            os.makedirs(subPath)
            unique_filename = str(uuid.uuid4())
            myFile = os.path.join(subPath, unique_filename)
    else:
        stderr_out("Could not find directory: {}".format(path))
        sys.exit(1)

    try:
        fd = open(myFile, "w")
        try:
            fd.write( content )
        finally:
            fd.close()
    except IOError:
        stderr_out("Could not create \"{}\"".format(myFile))


def generate_output(character, size, path):
    """
    gather the demographics of each file to create. Then create it.    
    """
    total_files_to_create = int((size/float(character['totalSize']))*character['totalFiles'])
    files_to_create_per_hour = int(total_files_to_create/24)
    remaining_files_to_create = total_files_to_create%24
    
    print("Will be creating {} files. That's {} files each hour".format(total_files_to_create, files_to_create_per_hour))

    for h in range(0, 24):
        for g in ['smallFiles', 'mediumFiles', 'largeFiles', 'giantFiles', 'emptyFiles']:
            print("\nGenerating: {}, for hour: {}".format(g, h))
            
            #DEBUG
            #print(character[g])
            
            numOfFiles, avgSizeOfFile, numOfData, numOfText, numOfZip = get_num_and_size(
                size,
                files_to_create_per_hour,
                character[g]['perOfTotalNumber'],
                character[g]['perOfTotalSize'],
                character[g]['perData'] + character[g]['perUnk'],
                character[g]['perText'],
                character[g]['perZip']
                )

            print("Generating a total of {} files, each with average size of {}bytes, for a toatal of {}bytes".format(numOfData+numOfText+numOfZip, int(character[g]['avgSize']), (numOfData+numOfText+numOfZip)*int(character[g]['avgSize'])))

            print("Generating {} data files of average size {}bytes ({}bytes total)".format(numOfData, int(character[g]['avgSize']), int(numOfData)*int(character[g]['avgSize'])))
            for f in range(0, numOfData):
                #d = generate_data(avgSizeOfFile)
                d = generate_data(int(character[g]['avgSize']))
                dump_file(g, h, d, path)

            print("Generating {} text files of average size {}bytes ({}bytes total)".format(numOfText, int(character[g]['avgSize']), int(numOfText)*int(character[g]['avgSize'])))
            for f in range(0, numOfText):
                #t = generate_ascii(avgSizeOfFile)
                t = generate_ascii(int(character[g]['avgSize']))
                dump_file(g, h, t, path)

            print("Generating {} compressed files of average size {}bytes ({}bytes total)".format(numOfZip, int(character[g]['avgSize']), int(numOfZip)*int(character[g]['avgSize'])))
            for f in range(0, numOfZip):
                #z = generate_zip(avgSizeOfFile)
                z = generate_zip(int(character[g]['avgSize']))
                dump_file(g, h, z, path)

    if remaining_files_to_create > 0:
        for h in range(0, int(remaining_files_to_create)):
            for g in ['smallFiles', 'mediumFiles', 'largeFiles', 'giantFiles', 'emptyFiles']:
                print("\nGenerating any remaining: {}, for hour: {}".format(g, h))
                
                #DEBUG
                #print(character[g])
                
                numOfFiles, avgSizeOfFile, numOfData, numOfText, numOfZip = get_num_and_size(
                    size,
                    remaining_files_to_create,
                    character[g]['perOfTotalNumber'],
                    character[g]['perOfTotalSize'],
                    character[g]['perData'] + character[g]['perUnk'],
                    character[g]['perText'],
                    character[g]['perZip']
                    )

                print("Generating {} data files of average size {}bytes".format(numOfData, int(character[g]['avgSize'])))
                for f in range(0, numOfData):
                    #d = generate_data(avgSizeOfFile)
                    d = generate_data(int(character[g]['avgSize']))
                    dump_file(g, h, d, path)

                print("Generating {} text files of average size {}bytes".format(numOfText, int(character[g]['avgSize'])))
                for f in range(0, numOfText):
                    #t = generate_ascii(avgSizeOfFile)
                    t = generate_ascii(int(character[g]['avgSize']))
                    dump_file(g, h, t, path)

                print("Generating {} compressed files of average size {}bytes".format(numOfZip, int(character[g]['avgSize'])))
                for f in range(0, numOfZip):
                    #z = generate_zip(avgSizeOfFile)
                    z = generate_zip(int(character[g]['avgSize']))
                    dump_file(g, h, z, path)


def main():

    parser = argparse.ArgumentParser(
        description = (
            "Gather all \"stat()\" data about files in a given directory."
            " Store all that in a database for later analysis"
            )
        )
    action_group = parser.add_mutually_exclusive_group()
    action_group.add_argument(
        "--scan", "-s",
        help = ("Only perform the scan and create a database. Do not generate data. Use with -d, and -p"),
        action="store_true"
        )
    action_group.add_argument(
        "--generate", "-g",
        help = ("Only generate the data from an existing database. Use with -d, and -o"),
        action="store_true"
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
    parser.add_argument(
        "--out", "-o",
        help = ("The output path to generate the needed data"),
        default = "./output"
        )
    parser.add_argument(
        "--age", "-a",
        help = ("Filter file records to files less than or equal to 'n' seconds of age."),
        default = "86400"
        )
    parser.add_argument(
        "--sizeOfDataSet", "-q",
        help = ("The size of the data set to generate in whole GB"),
        default = pow(1024,3)
        )
    args = parser.parse_args()
    db_file = args.database
    dir_to_search = args.path
    scan_only = args.scan
    gen_only = args.generate
    out_path = args.out
    scan_age = args.age
    dataset_size = int(args.sizeOfDataSet) * 1073741824 # convert GB to Bytes

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

    keys = [ 
        'NumberOfSmallFiles',
        'SizeOfSmallFiles',
        'SmallData',
        'SmallText',
        'SmallZip',
        'SmallUnk',
        'NumberOfMediumFiles',
        'SizeOfMediumFiles',
        'MediumData',
        'MediumText',
        'MediumZip',
        'MediumUnk',
        'NumberOfLargeFiles',
        'SizeOfLargeFiles',
        'LargeData',
        'LargeText',
        'LargeZip',
        'LargeUnk',
        'NumberOfGiantFiles',
        'SizeOfGiantFiles',
        'GiantData',
        'GiantText',
        'GiantZip',
        'GiantUnk',
        'NumberOfTypeData',
        'NumberOfTypeText',
        'NumberOfTypeZip',
        'NumberOfTypeEmpty',
        'NumberOfTypeUnk',
        'TotalSize'
        ]

    if scan_only:
        with conn:
            create_table(conn, FILE_SQL_TABLE)

            for record in profile_data(dir_to_search):
                record_file(conn, record)

        print("...Complete\nDatabase has been stored here: {}".format(db_file))

    elif gen_only:
        with conn:
            values = get_stats_from_db(conn)

        stats = dict(zip(keys, values))
        characterized = characterize_stats(stats)

        generate_output(characterized, dataset_size, out_path)
    else:
        with conn:
            create_table(conn, FILE_SQL_TABLE)

            for record in profile_data(dir_to_search):
                record_file(conn, record)

            values = get_stats_from_db(conn)

        print("...Scanning Complete\nDatabase has been stored here: {}".format(db_file))

        stats = dict(zip(keys, values))
        characterized = characterize_stats(stats)

        generate_output(characterized, dataset_size, out_path)


if __name__ == '__main__':
    main()
