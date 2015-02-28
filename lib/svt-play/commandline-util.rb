def parse_args
  options = {}
  optparse = OptionParser.new do|opts|
    # Set a banner, displayed at the top
    # of the help screen.
    opts.banner = "Usage: parse_series.rb [options] series_name"

    # Define the options, and what they do
    options[:verbose] = false
    opts.on( '-v', '--verbose', 'Output more information' ) do
      options[:verbose] = true
    end

    options[:url] = nil
    opts.on( '-u', '--url URL', 'Download from url' ) do |url|
      options[:url] = url
    end

    options[:exclude] = false
    options[:exclude_string] = nil
    opts.on( '-e', '--exclude EXCLUDE', 'Exclude download which contains string' ) do |exclude|
      options[:exclude] = true
      options[:exclude_string] = exclude
    end

    options[:force] = false
    opts.on( '-f', '--force', 'Download from url' ) do
      options[:force] = true
    end

    options[:folder] = nil
    opts.on( '-d', '--destination FOLDER', 'Destination folder' ) do |folder|
      options[:folder] = folder

      #Add tailing /
      options[:folder]+="/" if options[:folder]!=nil && !(options[:folder][options[:folder].length-1] == '/')
    end

    # This displays the help screen, all programs are
    # assumed to have this option.
    opts.on( '-h', '--help', 'Display this screen' ) do
      puts opts
    exit
    end
  end
  optparse.parse!
  return options, optparse
end
