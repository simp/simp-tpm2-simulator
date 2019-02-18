require 'yaml'
require 'rake'

# rubocop:disable Style/ClassAndModuleChildren
# rubocop:disable Metrics/LineLength, Metrics/MethodLength

# Read build config from a YAML file
class SIMP::RPM::SpecBuilderConfig
  include (Rake.verbose == true ? FileUtils::Verbose : FileUtils)
  def self.load_config(file_name = 'things_to_build.yaml')
    file = File.file?(file_name) ? file_name : find_yaml_config_path(file_name)
    YAML.load_file(file)
  end

  private

  # This method exists because `vagrant up` dereferences symlinks
  def self.find_yaml_config_path(file_name)
    dir = File.expand_path Rake.application.find_rakefile_location.last
    puts "===== Looking for yaml config file in '#{dir}'..." if Rake.verbose == true
    yaml_file = nil
    while yaml_file.nil? && dir !~ %r{^\/$}
      file = File.join(dir, file_name)
      if File.file? file
        yaml_file = file
        break
      else
        dir = File.dirname dir
      end
    end
    raise "ERROR: couldn't find yaml config file '#{file_name}'" unless yaml_file
    yaml_file
  end
end

# rubocop:enable Style/ClassAndModuleChildren
# rubocop:enable Metrics/LineLength, Metrics/MethodLength
