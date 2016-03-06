require 'yaml'

module Rancher
  module Shell
    class Config
      def self.load options = {}
        config_file_paths = [
          "#{ENV['HOME']}/.rancher-shell.yml",
          "#{Dir.pwd}/.rancher-shell.yml",
        ]
        @data ||= {}
        config_file_paths.each do |file_path|
          next unless File.exists? file_path
          config = YAML.load_file file_path
          @data.merge! config if config
        end
        options.each do |key, value|
          @data[key] = value unless value.nil? || value === ''
        end
      end

      def self.get key
        @data[key]
      end

      def self.get_all
        @data
      end
    end
  end
end
