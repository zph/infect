module Infect
  class Command
    class Bundle < Command
      attr_reader :bundle, :name, :location, :options
      def initialize(arg, opts)
        @bundle = arg
        @options = opts
        @name = File.basename(bundle)
        @location = File.expand_path("#{BUNDLE_DIR}/#{name}")
      end

      def url
        "git@github.com:#{bundle}.git"
      end

      def install
        notice "Installing #{name}... "
        mkdir BUNDLE_DIR
        chdir BUNDLE_DIR
        before(options)
        git "clone '#{url}'"
        after(options)
      end

      def update
        notice "Updating #{name}... "
        chdir @location
        before(options)
        git "pull"
        after(options)
      end

      def call
        if File.exists? @location
          update
        else
          install
          after_install(options)
        end
      end

      def before(args=options)
        hook(:before, args)
      end

      def after(args=options)
        hook(:after, args)
      end

      def after_install(args=options)
        hook(:after_install, args)
      end

      def hook(type, args=options)
        return unless args
        script_hook = args.fetch(type) { nil }
        return unless script_hook
        out, status = Open3.capture2(script_hook)
        STDOUT.puts out
      end

      private

      def git(args)
        `git #{args}`
      end
    end
  end
end
