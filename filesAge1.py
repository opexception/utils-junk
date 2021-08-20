#!/usr/bin/python
import os, sys, datetime

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


#Catch errors here:
def logit(msg):
  global Haserror
  try:
    logfile = open("/tmp/age_analysis_errors.log", "a")
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


###
#   Main Loop
###
print "Scanning files recursively in current directory."

for dirpath, dirnames, filenames in os.walk(dir_to_search):
  for file in filenames:
    currpath = os.path.join(dirpath, file)
    try:
      stat_details=os.stat(currpath)
    except OSError, e:
      logit("Broken symlink, or file removed during evaluation: %s\n" % currpath)
      continue
    else:
      try:
        file_mtime = datetime.datetime.fromtimestamp(stat_details.st_mtime)
      except ValueError:
        logit("Could not determine age of file: %s\n" % currpath)
        continue
      file_size = stat_details.st_size
    # Age of files, relative to now, compared to modify time of files
    age = now - file_mtime
    if age < one_day :
      less_than_one_day += file_size
      continue
    elif age > one_day and age < one_week :
      less_than_one_week += file_size
      continue
    elif age > one_week and age < one_year :
      less_than_one_year += file_size
      continue
    elif age > one_year and age < three_years :
      one_to_three_years += file_size
      continue
    elif  age > three_years and age < five_years :
      three_to_five_years += file_size
      continue
    elif age > five_years and age < seven_years :
      five_to_seven_years += file_size
      continue
    elif age > seven_years :
      greater_than_seven_years += file_size

###
#   Convert units to something more human friendly
###

def set_units(value):
  """
  Take a number, "value", and set a human readable unit to it. 
  """
  if value < 1024 :
    units = "Bytes"
    converted_val = value 
  elif value > 1024 and value < pow(1024,2):
    units = "K"
    converted_val = (value / 1024)
  elif value > pow(1024,2) and value < pow(1024,3):
    units = "M"
    converted_val = (value / pow(1024,2))
  elif value > pow(1024,3) and value < pow(1024,4):
    units = "G"
    converted_val = (value / pow(1024,3))
  elif value > pow(1024,4):
    units = "T"
    converted_val = (value / pow(1024,4))

  return converted_val, units


ltod = set_units(less_than_one_day)
ltow = set_units(less_than_one_week)
ltoy = set_units(less_than_one_year)
otty = set_units(one_to_three_years)
ttfy = set_units(three_to_five_years)
ftsy = set_units(five_to_seven_years)
gtsy = set_units(greater_than_seven_years)

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

###
#   Display results
###
print "Size of files that are less than 1 day old: \n\t %.2f%s" % ltod
print "Size of files that are less than 1 week old: \n\t %.2f%s" % ltow
print "Size of files that are less than 1 year old:\n\t %.2f%s" % ltoy
print "Size of files that are 1-3 years old:\n\t %.2f%s" % otty
print "Size of files that are 3-5 years old:\n\t %.2f%s" % ttfy
print "Size of files that are 5-7 years old:\n\t %.2f%s" % ftsy
print "Size of files that are greater than 7 years old:\n\t %.2f%s" % gtsy
      
      
          
# age_analysis.py
# Written Aug. 2, 2012 by Robert Maracle
