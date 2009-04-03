script_path = Dir.chdir(File.expand_path(File.dirname(__FILE__))) { Dir.pwd }
lib_path = Dir.chdir(script_path + '/lib/') { Dir.pwd }
$:.unshift lib_path

require 'yaml'

module MyConfig
  attr_accessor :settings
  @settings = YAML.load_file('settings.yml')
end
