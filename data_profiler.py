#!/usr/bin/env python
import os, sys, datetime, sqlite3, collections

#
#  A quick and dirty script to determin size of data vs. age of data in 
#  current workin directory recusively. result is a printed list 
#  of age groups and the associated data size
#

###
#   Variables
###

dir_to_search = os.path.curdir # FIXME: curdir by default, but use argparse
now = datetime.datetime.now()
one_day = datetime.timedelta(days=1)
one_week = datetime.timedelta(days=7)
one_year = datetime.timedelta(days=365)
three_years = datetime.timedelta(days=(3*365))
five_years = datetime.timedelta(days=(5*365))
seven_years = datetime.timedelta(days=(7*365))
less_than_one_day = 0.0
less_than_one_week = 0.0
less_than_one_year = 0.0
one_to_three_years = 0.0
three_to_five_years = 0.0
five_to_seven_years = 0.0
greater_than_seven_years = 0.0
Haserror = 0
profile_database_file = "./profile.db"
working_database_file = "/tmp/data_profiler.db"
log_file = "./data_profiler.log"


#Catch errors here:
def logit(msg):
  global Haserror
  global log_file
  try:
    logfile = open(log_file, "a")
    try:
      logfile.write( msg )
    finally:
      logfile.close()
  except IOError:
    if ( Haserror ):
      pass
    else:
      print "Could not write Error Log!"
      Haserror = 1
      pass


#Database Stuff
def create_connection(db_file):
    """ create a database connection to the SQLite database
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


def flatten(l):
    for element in l:
        if isinstance(element, collections.Iterable) and not isinstance(element, basestring):
            for sub in flatten(element):
                yield sub
        else:
            yield element

def profile_data(dir_to_search, db_file):
  print "Scanning files recursively in current directory."
  header_contents=[
                  'file',
                  'age',
                  'type',
                  'mode',
                  'inode',
                  'device',
                  'numlinks',
                  'uid',
                  'gid',
                  'size',
                  'atime',
                  'mtime',
                  'ctime']
  txt_header = ""
  for i in header_contents:
    if txt_header:
      txt_header += str("," + i)
    else:
      txt_header = i
  logit(txt_header + "\n")

  # conn = create_connection(db_file)

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
      age = now - file_mtime
      ftype = "unk"
      record_contents = [
                        currpath, 
                        age, 
                        ftype, 
                        stat_details.st_mode, 
                        stat_details.st_ino, 
                        stat_details.st_dev, 
                        stat_details.st_nlink, 
                        stat_details.st_uid, 
                        stat_details.st_gid, 
                        stat_details.st_size, 
                        stat_details.st_atime, 
                        stat_details.st_mtime, 
                        stat_details.st_ctime]
      #record = flatten(record_contents)
      txt_record = ""
      for i in record_contents:
        if txt_record:
          txt_record += str("," + str(i))
        else:
          txt_record = str(i)
      logit(txt_record + "\n")


profile_data(dir_to_search, profile_database_file)



# scan files, store path/name and all attributes. Dump attributes to file txt/sqlite
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


