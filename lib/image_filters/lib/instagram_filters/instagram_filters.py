import sys, getopt, os.path
from instagram_filters.filters import *

def main(argv):
   inputfile = ''
   filter_name = ''
   available_filters = ['Nashville', 'Gotham', 'Kelvin', 'Lomo', 'Toaster']
   try:
      opts, args = getopt.getopt(argv,"hi:f:")
   except getopt.GetoptError:
      sys.exit('There are invalid options in command line')
   for opt, arg in opts:
      if opt == '-h':
         print 'How to use: '
         print 'python instagram_filters.py -i <input_file> -f <filter>. -i and -f are obligatory options which must have corresponding values'
         print 'Available filters: %s' % ', '.join(available_filters)
         sys.exit()
      elif opt == "-i":
         inputfile = arg
      elif opt == '-f':
        filter_name = arg

   if inputfile or filter_name:
     if (not inputfile) or (inputfile.isspace()):
       sys.exit("option -i is not set")
     if not os.path.isfile(inputfile):
       sys.exit("input file doesn't exist")
     if (not filter_name) or (filter_name.isspace()):
       sys.exit("option -f is not set")
     if not filter_name in available_filters:
       sys.exit("Invalid filter name")
     clazz = eval(str(filter_name))
     f = clazz(inputfile)
     f.apply()

if __name__ == "__main__":
   main(sys.argv[1:])
