require 'open3'
require_relative 'Logging'
require_relative 'SimcConfig'

module SimcHelper
  # Write SimC default profiles path to GeneratedConfig.simc in generated
  def self.GenerateSimcConfig()
    File.open("#{SimcConfig['GeneratedFolder']}/GeneratedConfig.simc", 'w') do |file|
      file.puts "$(simc_profiles_path)=\"#{SimcConfig['SimcPath']}/profiles\""
    end
  end

  # Convert string into simc name, e.g. "Fortune's Strike" -> "fortunes_strike"
  def self.TokenizeName(name)
    return name.downcase.gsub(/[^0-9a-z_+.% ]/i, '').gsub(' ', '_')
  end

  # Run a simulation with all args applied in order
  def self.RunSimulation(args)
    command = []

    # Call executable
    command.push("#{SimcConfig['SimcPath']}/simc")

    # Set number of threads to use
    command.push("threads=#{SimcConfig['Threads']}")

    # Set global configurations
    command.push("#{SimcConfig['ConfigFolder']}/SimcGlobalConfig.simc")
    GenerateSimcConfig()
    command.push("#{SimcConfig['GeneratedFolder']}/GeneratedConfig.simc")

    command += args

    # Run simulation with logging and redirecting output to the terminal
    Open3.popen3(*command) do |stdin, stdout, stderr, thread|
      Thread.new do
        until (line = stdout.gets).nil? do
          line.chomp!
          Logging.LogSimcInfo(line)
        end
      end
      Thread.new do
        until (line = stderr.gets).nil? do
          line.chomp!
          Logging.LogSimcError(line)
        end
      end
      thread.join # Wait for simc process to end
    end
  end
end
