require 'pmap'
require 'shellwords'
require 'open3'

module Infect
  # Globals be global
  VIMHOME = ENV['VIM'] || "#{ENV['HOME']}/.vim"
  VIMRC = ENV['MYVIMRC'] || "#{ENV['HOME']}/.vimrc"
  BUNDLE_DIR = "#{VIMHOME}/bundle"

  class Runner
    def self.call(*args)
      force = args.include? "-f"

      commands = [Command::Prereqs.new()]

      File.open( VIMRC ).each_line do |line|
        if line =~ /^"=/
          command, arg, opts = parse_command(line.gsub('"=', ''))
          commands << Command.build(command, arg, opts)
        end
      end

      commands.compact.peach(&:call)

      Cleanup.new(commands, :force => force).call

    end

    private

    def self.parse_command(line)
      # TODO: pass in named params after for things like branches
      #
      # So this will split the command into 3 parts

      command, arg, opts_string = line.split ' ', 3
      [command, arg, parse_opts(opts_string)]
    end

    def self.parse_opts(string)
      # Woah now. Much options.
      #
      # The first split on commas will separate the commands.
      #
      # The second split on the commands happens on the first '='.
      parts = format_into_hash(string).inject(&:merge)
    end

    def self.format_into_hash(str)
      parts = str.split(",").map(&:strip).reject(&:empty?).map do |i|
        array = i.split("=", 2).map(&:strip)

        Hash[*array].map do |k,v|
          {k.downcase.to_sym => v}
        end.first
      end
    end
  end
end
