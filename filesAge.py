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

dir_to_search = os.path.curdir
now = datetime.datetime.now()
one_day = datetime.timedelta(days=1)
one_week = datetime.timedelta(days=7)
one_year = datetime.timedelta(days=365)
three_years = datetime.timedelta(days=(3*365))
five_years = datetime.timedelta(days=(5*365))
seven_years = datetime.timedelta(days=(7*365))
less_than_one_day = 0
less_than_one_week = 0
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
      os.stat(currpath)
    except OSError, e:
      logit("Broken symlink, or file removed during evaluation: %s\n" % currpath)
      continue
    else:
      try:
        file_mtime = datetime.datetime.fromtimestamp(os.path.getmtime(currpath))
      except ValueError:
        logit("Could not determine age of file: %s\n" % currpath)
        continue
    # Age of files, relative to now, compared to modify time of files
    age = now - file_mtime
    if age < one_day :
      less_than_one_day += os.path.getsize(currpath)
      continue
    elif age > one_day and age < one_week :
      less_than_one_week += os.path.getsize(currpath)
      continue
    elif age > one_week and age < one_year :
      less_than_one_year += os.path.getsize(currpath)
      continue
    elif age > one_year and age < three_years :
      one_to_three_years += os.path.getsize(currpath)
      continue
    elif  age > three_years and age < five_years :
      three_to_five_years += os.path.getsize(currpath)
      continue
    elif age > five_years and age < seven_years :
      five_to_seven_years += os.path.getsize(currpath)
      continue
    elif age > seven_years :
      greater_than_seven_years += os.path.getsize(currpath)

###
#   Convert units to something more human friendly
###
if less_than_one_day < 1024 :
  units = "Bytes"
  ltod = less_than_one_day, units
elif less_than_one_day > 1024 and less_than_one_day < pow(1024,2):
  units = "K"
  ltod = (less_than_one_day / 1024), units
elif less_than_one_day > pow(1024,2) and less_than_one_day < pow(1024,3):
  units = "M"
  ltod = (less_than_one_day / pow(1024,2)), units
elif less_than_one_day > pow(1024,3) and less_than_one_day < pow(1024,4):
  units = "G"
  ltod = (less_than_one_day / pow(1024,3)), units
elif less_than_one_day > pow(1024,4):
  units = "T"
  ltod = (less_than_one_day / pow(1024,4)), units
  
if less_than_one_week < 1024 :
  units = "Bytes"
  ltow = less_than_one_week, units
elif less_than_one_week > 1024 and less_than_one_week < pow(1024,2):
  units = "K"
  ltow = (less_than_one_week / 1024), units
elif less_than_one_week > pow(1024,2) and less_than_one_week < pow(1024,3):
  units = "M"
  ltow = (less_than_one_week / pow(1024,2)), units
elif less_than_one_week > pow(1024,3) and less_than_one_week < pow(1024,4):
  units = "G"
  ltow = (less_than_one_week / pow(1024,3)), units
elif less_than_one_week > pow(1024,4):
  units = "T"
  ltow = (less_than_one_week / pow(1024,4)), units

if less_than_one_year < 1024 :
  units = "Bytes"
  ltoy = less_than_one_year, units
elif less_than_one_year > 1024 and less_than_one_year < pow(1024,2):
  units = "K"
  ltoy = (less_than_one_year / 1024), units
elif less_than_one_year > pow(1024,2) and less_than_one_year < pow(1024,3):
  units = "M"
  ltoy = (less_than_one_year / pow(1024,2)), units
elif less_than_one_year > pow(1024,3) and less_than_one_year < pow(1024,4):
  units = "G"
  ltoy = (less_than_one_year / pow(1024,3)), units
elif less_than_one_year > pow(1024,4):
  units = "T"
  ltoy = (less_than_one_year / pow(1024,4)), units

if one_to_three_years < 1024 :
  units = "Bytes"
  otty = one_to_three_years, units
elif one_to_three_years > 1024 and one_to_three_years < pow(1024,2):
  units = "K"
  otty = (one_to_three_years / 1024), units
elif one_to_three_years > pow(1024,2) and one_to_three_years < pow(1024,3):
  units = "M"
  otty = (one_to_three_years / pow(1024,2)), units
elif one_to_three_years > pow(1024,3) and one_to_three_years < pow(1024,4):
  units = "G"
  otty = (one_to_three_years / pow(1024,3)), units
elif one_to_three_years > pow(1024,4):
  units = "T"
  otty = (one_to_three_years / pow(1024,4)), units

if three_to_five_years < 1024 :
  units = "Bytes"
  ttfy = three_to_five_years, units
elif three_to_five_years > 1024 and three_to_five_years < pow(1024,2):
  units = "K"
  ttfy = (three_to_five_years / 1024), units
elif three_to_five_years > pow(1024,2) and three_to_five_years < pow(1024,3):
  units = "M"
  ttfy = (three_to_five_years / pow(1024,2)), units
elif three_to_five_years > pow(1024,3) and three_to_five_years < pow(1024,4):
  units = "G"
  ttfy = (three_to_five_years / pow(1024,3)), units
elif three_to_five_years > pow(1024,4):
  units = "T"
  ttfy = (three_to_five_years / pow(1024,4)), units
  
if five_to_seven_years < 1024 :
  units = "Bytes"
  ftsy = five_to_seven_years, units
elif five_to_seven_years > 1024 and five_to_seven_years < pow(1024,2):
  units = "K"
  ftsy = (five_to_seven_years / 1024), units
elif five_to_seven_years > pow(1024,2) and five_to_seven_years < pow(1024,3):
  units = "M"
  ftsy = (five_to_seven_years / pow(1024,2)), units
elif five_to_seven_years > pow(1024,3) and five_to_seven_years < pow(1024,4):
  units = "G"
  ftsy = (five_to_seven_years / pow(1024,3)), units
elif five_to_seven_years > pow(1024,4):
  units = "T"
  ftsy = (five_to_seven_years / pow(1024,4)), units
  
if greater_than_seven_years < 1024 :
  units = "Bytes"
  gtsy = greater_than_seven_years, units
elif greater_than_seven_years > 1024 and greater_than_seven_years < pow(1024,2):
  units = "K"
  gtsy = (greater_than_seven_years / 1024), units
elif greater_than_seven_years > pow(1024,2) and greater_than_seven_years < pow(1024,3):
  units = "M"
  gtsy = (greater_than_seven_years / pow(1024,2)), units
elif greater_than_seven_years > pow(1024,3) and greater_than_seven_years < pow(1024,4):
  units = "G"
  gtsy = (greater_than_seven_years / pow(1024,3)), units
elif greater_than_seven_years > pow(1024,4):
  units = "T"
  gtsy = (greater_than_seven_years / pow(1024,4)), units



###
#   Display results
###
print "Size of files that are less than 1 day old: \n\t %s%s" % ltod
print "Size of files that are less than 1 week old: \n\t %s%s" % ltow
print "Size of files that are less than 1 year old:\n\t %.2f%s" % ltoy
print "Size of files that are 1-3 years old:\n\t %.2f%s" % otty
print "Size of files that are 3-5 years old:\n\t %.2f%s" % ttfy
print "Size of files that are 5-7 years old:\n\t %.2f%s" % ftsy
print "Size of files that are greater than 7 years old:\n\t %.2f%s" % gtsy
      
      
          
# age_analysis.py
# Written Aug. 2, 2012 by Robert Maracle
