require 'shellwords'
require 'open3'

module FFMpeg
  class Convert
    attr_accessor :version, :total_time, :frame, :total_frames, :capturing,
                  :input_fps, :fps

    @@timeout = 30
    @started = false
    @completed = false

    def self.timeout=(time)
      @@timeout = time
    end

    def self.timeout
      @@timeout
    end

    def initialize(input, output, options={})
      @input   = input
      @output  = output
      @options = options

      failure_msg = "FATAL:  cannot find ffmpeg command"
      failure_msg << " (#{ self.class.base_command })"

      self.class.system_command(failure_msg) do
        cmd = "#{ self.class.base_command } --version 2> /dev/null"
        system cmd
      end
    end


    def fix_encoding(output)
      output[/test/]
    rescue ArgumentError
      output.force_encoding("ISO-8859-1")
    end

    def self.base_command
      ENV['FFMPEG'] || 'ffmpeg'
    end

    def self.system_command(message)
      begin
        yield
      rescue Errno::ENOENT => e
        raise message
      end
    end

    def execute
      # usage: ffmpeg [options] [[infile options] -i infile]...
      #                         {[outfile options] outfile}...
      if (!@options[:force] and exists @output)
        #puts "'#{options[:folder]}#{title}.mkv' exist skipping" if options[:verbose]
        existing_file = FFMpeg::Movie.new @output
        new_file = FFMpeg::Movie.new @input
        #puts "#{existing_file.duration}, #{new_file.duration}"
        max = new_file.duration*1.02
        min = new_file.duration*0.98
        #puts "Duration #{new_file.duration}, min #{min}, max #{max}, new_file.duration > min: #{new_file.duration > min}, new_file.duration < max: #{new_file.duration < max}"
        puts "File exists" if @options[:verbose]
        raise "File exists" if new_file.duration > min && new_file.duration < max
      end

      cmd = if @options[:offset]
        offset_command
      elsif @options != nil
        options = ""
        @options.each do |key, value|
          options += " -#{key} #{value}" if !(key == :force || key == :verbose)
        end
        output = Shellwords.escape(@output)
        #Fix faulty escape
        output = output[1,output.length+1] if output[0,2] == '\~'
        output["&ouml;"] = "ö"
        puts output
        exit

        [self.class.base_command, "-i", Shellwords.escape(@input), options, output, "-y"]
      else
        [self.class.base_command, "-i", Shellwords.escape(@input), Shellwords.escape(@output), "-y"]
      end

      @@timeout = 30
      output = ""
      cmd = cmd.join(" ")
      #puts cmd

      begin
        Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
          @started = true
          begin
            yield(0.0) if block_given?
            next_line = Proc.new do |line|
              #fix_encoding(line)
              #process_output_line(line)

              #process start.
              if line =~ /^ffmpeg/i
                line.split("\n").each {|line|
                if line =~ /Press \[q\] to stop encoding/
                   self.capturing = :progress
                  elsif line =~ /^Input.*from/i
                    self.capturing = :input
                  elsif line =~ /^Output.*to/i
                    self.capturing = :output
                  elsif line =~ /\s*duration: (\d+):(\d+):(\d+.\d+)/i
                    self.total_time = ($1.to_i * 3600) + ($2.to_i * 60) + $3.to_f if self.capturing_input?
                  elsif line =~ /^\s*stream.*video:.*\s+([0-9.]+)\s*fps/i
                    if self.capturing_input?
                      self.input_fps = $1.to_f
                      self.total_frames = self.input_fps * self.total_time
                    end
                  end
                }
              end


              if line =~ /fps=(\d+)/
                #\s*(\d+)/i
                fps = $1.to_i
              else
                fps = 0
              end
              if line =~ /frame=\s*(\d+)/i
                frame = $1.to_i
              else
                frame = 0
              end
              if line =~ /bitrate=\s*(\d+.\d+)/i
                bitrate = $1.to_f
              else
                bitrate = 0
              end
              if line =~ /ime=(\d+):(\d+):(\d+.\d+)/ # ffmpeg 0.8 and above style
                time = ($1.to_i * 3600) + ($2.to_i * 60) + $3.to_f
              else # better make sure it wont blow up in case of unexpected output
                time = 0.0
              end
              progress = ((time/self.total_time)*100).round(2) #/ @movie.duration
              yield(progress, frame, time.round(2), fps, bitrate, self.total_time, self.total_frames) if block_given?

              output << line
            end

            begin
              if @@timeout
                #stderr.each_with_timeout(wait_thr.pid, @@timeout, 'size=', &next_line)
                stderr.each_with_timeout(wait_thr.pid, @@timeout, 'q=', &next_line)
              else
                stderr.each('size=', &next_line)
              end
            rescue SignalException => e
              if File.exists? @output
                puts "\nRemoving #{@output}."
                File.delete @output
              end
              raise e
            end


          rescue Timeout::Error => e
            FFMPEG.logger.error "Process hung...\n@command\n#{@command}\nOutput\n#{@output}\n"
            raise Error, "Process hung. Full output: #{@output}"
          end
        end
      rescue SignalException => e
        if File.exists? @output
          puts "\nRemoving #{@output}."
          File.delete @output
        end
        raise e
      end
    end

    def started
    end

    def completed
    end

    def offset_command
      # start with just our input video
      cmd = [self.class.base_command, "-i", @input]

      # add the amount of shift required (direction doesn't matter yet)
      cmd += ["-itsoffset", to_hms(@options[:offset].abs)]

      # reference our input file again to get the other track
      cmd += ["-i", @input]

      if @options[:offset] > 0
        # shift audio forward by :offset seconds
        # TODO : this assumes input file has one video and one audio stream.
        # add a way to determine input content and map streams appropriately
        cmd += %w(-map 0:0 -map 1:1)
      else
        # shift video forward by :offset seconds
        cmd += %w(-map 1:0 -map 0:1)
      end

      cmd << @output

      cmd
    end

    def progress
      return nil if frame.nil? || total_frames.nil?
      frame / total_frames.to_f
    end

    def capturing_input?
      @capturing == :input
    end

    def capturing_output?
      @capturing == :output
    end

    private


    def process_output_line(line)
      #OutputProcessor.process(self, line)
      @output << line
      if line.include?("time=")
        if line =~ /time=(\d+):(\d+):(\d+.\d+)/ # ffmpeg 0.8 and above style
          time = ($1.to_i * 3600) + ($2.to_i * 60) + $3.to_f
        else # better make sure it wont blow up in case of unexpected output
          time = 0.0
        end
        progress = time #/ @movie.duration
        yield(time) if block_given?
      end
    end

    def to_hms(seconds)
      seconds, ms      = seconds.divmod 1
      minutes, seconds = seconds.divmod 60
      hours, minutes   = minutes.divmod 60

      '%02d:%02d:%02d.%03d' % [hours, minutes, seconds, ms.round(10) * 1000]
    end
  end

  def self.convert(input, output, options={}, &block)
    return Convert.new(input, output, options).execute &block if block_given?
    return Convert.new(input, output, options).execute
  end
end
