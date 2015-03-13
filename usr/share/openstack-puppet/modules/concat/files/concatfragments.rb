# Script to concat files to a config file.
#
# Given a directory like this:
# /path/to/conf.d
# |-- fragments
# |   |-- 00_named.conf
# |   |-- 10_domain.net
# |   `-- zz_footer
#
# The script supports a test option that will build the concat file to a temp location and
# use /usr/bin/cmp to verify if it should be run or not.  This would result in the concat happening
# twice on each run but gives you the option to have an unless option in your execs to inhibit rebuilds.
#
# Without the test option and the unless combo your services that depend on the final file would end up
# restarting on each run, or in other manifest models some changes might get missed.
#
# OPTIONS:
#  -o	The file to create from the sources
#  -d	The directory where the fragments are kept
#  -t	Test to find out if a build is needed, basically concats the files to a temp
#       location and compare with what's in the final location, return codes are designed
#       for use with unless on an exec resource
#  -w   Add a shell style comment at the top of the created file to warn users that it
#       is generated by puppet
#  -f   Enables the creation of empty output files when no fragments are found
#  -n	Sort the output numerically rather than the default alpha sort
#
# the command:
#
#   concatfragments.rb -o /path/to/conffile.cfg -d /path/to/conf.d
#
# creates /path/to/conf.d/fragments.concat and copies the resulting
# file to /path/to/conffile.cfg.  The files will be sorted alphabetically
# pass the -n switch to sort numerically.
#
# The script does error checking on the various dirs and files to make
# sure things don't fail.
require 'optparse'
require 'fileutils'

settings = {
  :outfile => "",
  :workdir => "",
  :test    => false,
  :force   => false,
  :warn    => "",
  :sortarg => "",
  :newline => false
}

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"
  opts.separator "Specific options:"

  opts.on("-o", "--outfile OUTFILE", String, "The file to create from the sources") do |o|
    settings[:outfile] = o
  end

  opts.on("-d", "--workdir WORKDIR", String, "The directory where the fragments are kept") do |d|
    settings[:workdir] = d
  end

  opts.on("-t", "--test", "Test to find out if a build is needed") do
    settings[:test] = true
  end

  opts.separator "Other options:"
  opts.on("-w", "--warn WARNMSG", String,
          "Add a shell style comment at the top of the created file to warn users that it is generated by puppet") do |w|
    settings[:warn] = w
  end

  opts.on("-f", "--force", "Enables the creation of empty output files when no fragments are found") do
    settings[:force] = true
  end

  opts.on("-n", "--sort", "Sort the output numerically rather than the default alpha sort") do
    settings[:sortarg] = "-n"
  end

  opts.on("-l", "--line", "Append a newline") do
    settings[:newline] = true
  end
end.parse!

# do we have -o?
raise 'Please specify an output file with -o' unless !settings[:outfile].empty?

# do we have -d?
raise 'Please specify fragments directory with -d' unless !settings[:workdir].empty?

# can we write to -o?
if File.file?(settings[:outfile])
  if !File.writable?(settings[:outfile])
    raise "Cannot write to #{settings[:outfile]}"
  end
else
  if !File.writable?(File.dirname(settings[:outfile]))
    raise "Cannot write to dirname #{File.dirname(settings[:outfile])} to create #{settings[:outfile]}"
  end
end

# do we have a fragments subdir inside the work dir?
if !File.directory?(File.join(settings[:workdir], "fragments")) && !File.executable?(File.join(settings[:workdir], "fragments"))
  raise "Cannot access the fragments directory"
end

# are there actually any fragments?
if (Dir.entries(File.join(settings[:workdir], "fragments")) - %w{ . .. }).empty?
  if !settings[:force]
    raise "The fragments directory is empty, cowardly refusing to make empty config files"
  end
end

Dir.chdir(settings[:workdir])

if settings[:warn].empty?
  File.open("fragments.concat", 'w') {|f| f.write("") }
else
  File.open("fragments.concat", 'w') {|f| f.write("#{settings[:warn]}\n") }
end

# find all the files in the fragments directory, sort them numerically and concat to fragments.concat in the working dir
open('fragments.concat', 'a') do |f|
  Dir.entries("fragments").sort.each{ |entry|

    if File.file?(File.join("fragments", entry))
      f << File.read(File.join("fragments", entry))

      # append a newline if we were asked to (invoked with -l)
      if settings[:newline]
        f << "\n"
      end

    end
  }
end

if !settings[:test]
  # This is a real run, copy the file to outfile
  FileUtils.cp 'fragments.concat', settings[:outfile]
else
  # Just compare the result to outfile to help the exec decide
  if FileUtils.cmp 'fragments.concat', settings[:outfile]
    exit 0
  else
    exit 1
  end
end
