require 'yaml'
require 'active_support'

module Rancher
  module Shell
    class Config
      def self.load options = {}
        config_file_paths = [
          "#{ENV['HOME']}/.rancher-shell.yml",
          "#{Dir.pwd}/.rancher-shell.yml",
        ]
        @data = {}
        @data['options'] ||= options.dup
        @data['projects'] ||= {}
        config_file_paths.each do |file_path|
          next unless File.exists? file_path
          config = YAML.load_file file_path
          if config
            if config['options']
              config['options'].each do |key, value|
                @data['options'][key] = value unless options[key]
              end
              config.delete('options')
            end
            @data.deep_merge! config
          end
        end
        return unless @data['options']['project']
        @data['project'] = @data['projects'][@data['options']['project']]
        if @data['project']['options']
          @data['project']['options'].each do |key, value|
            @data['options'][key] = value unless options[key]
          end
        end
        if @data['options']['stack'] && @data['project']['stacks'] && @data['project']['stacks'][@data['options']['stack']]
          if @data['project']['stacks'][@data['options']['stack']]['options']
            @data['project']['stacks'][@data['options']['stack']]['options'].each do |key, value|
              @data['options'][key] = value unless options[key]
            end
          end
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
