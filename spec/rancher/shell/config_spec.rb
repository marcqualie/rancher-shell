require 'rancher/shell/config'

describe Rancher::Shell::Config do

  let(:config_file_path_home) { "#{ENV['HOME']}/.rancher-shell.yml" }
  let(:config_file_path_pwd) { "#{Dir.pwd}/.rancher-shell.yml" }

  describe "self.load" do

    before do
      [config_file_path_home, config_file_path_pwd].each do |file_path|
        allow(File).to receive(:exists?).with(file_path).and_return false
      end
    end

    # TODO: Move this to a helper, can't remember the syntax off the top of my head
    def set_config_file_content file_path, hash_data
      expect(File).to receive(:exists?).with(file_path).and_return true
      expect(YAML).to receive(:load_file).with(file_path).and_return hash_data
    end

    context "no config specified" do
      it "should be empty" do
        Rancher::Shell::Config.load {}
        expect(Rancher::Shell::Config.get_all).to eq('options' => {}, 'projects' => {})
      end
    end

    context "config specified via files" do
      let(:home_config) { { 'test1' => { 'stack' => 'qa', 'api' => { 'host' => 'rancher.example.com' } } } }
      let(:pwd_config) { { 'test1' => { 'api' => { 'host' => 'rancher.example.net' } } } }
      it "populate config from ~/.rancher-shell.yml" do
        set_config_file_content config_file_path_home, { 'projects' => [ home_config ] }
        Rancher::Shell::Config.load
        expect(Rancher::Shell::Config.get_all).to eq('options' => {}, 'projects' => [ home_config ])
      end
      it "~/.rancher-shell.yml is deep_merged with ./.rancher-shell.yml" do
        set_config_file_content config_file_path_home, { 'projects' => home_config }
        set_config_file_content config_file_path_pwd, { 'projects' => pwd_config }
        Rancher::Shell::Config.load
        expect(Rancher::Shell::Config.get_all['projects']).to eq('test1' => { 'stack' => 'qa', 'api' => { 'host' => 'rancher.example.net' } } )
      end
      it "identifies the project via options" do
        set_config_file_content config_file_path_home, { 'projects' => home_config }
        Rancher::Shell::Config.load('project' => 'test1')
        expect(Rancher::Shell::Config.get('project')).to eq home_config['test1']
      end
      context "options.stack is supplied" do
        let(:stack_config) { home_config.deep_merge('test1' => { 'stacks' => {'qa' => {'options' => { 'container' => 'qa_web_1' } }, 'production' => { 'options' => { 'container' => 'production_web_1' }  } }}) }
        it "ignores stack when no match is found" do
          set_config_file_content config_file_path_home, { 'projects' => stack_config }
          Rancher::Shell::Config.load('project' => 'test1', 'stack' => 'staging')
          expect(Rancher::Shell::Config.get('options')['container']).to eq nil
        end
        it "sets container when a stack is set via config file" do
          set_config_file_content config_file_path_home, { 'projects' => stack_config.deep_merge('test1' => { 'options' => { 'stack' => 'qa' } }) }
          Rancher::Shell::Config.load('project' => 'test1')
          expect(Rancher::Shell::Config.get('options')['container']).to eq 'qa_web_1'
        end
        it "sets container when a stack is set via CLI" do
          set_config_file_content config_file_path_home, { 'projects' => stack_config }
          Rancher::Shell::Config.load('project' => 'test1', 'stack' => 'qa')
          expect(Rancher::Shell::Config.get('options')['container']).to eq 'qa_web_1'
        end
        context "defined at root level" do
          it "cannot override a stack set via CLI" do
            set_config_file_content config_file_path_home, { 'options' => { 'stack' => 'qa' } }
            Rancher::Shell::Config.load('stack' => 'production')
            expect(Rancher::Shell::Config.get('options')['stack']).to eq 'production'
          end
        end
        context "defined at project level" do
          it "cannot override a stack set via CLI" do
            set_config_file_content config_file_path_home, { 'projects' => stack_config.deep_merge('test1' => { 'options' => { 'stack' => 'qa' } }) }
            Rancher::Shell::Config.load('project' => 'test1', 'stack' => 'production')
            expect(Rancher::Shell::Config.get('options')['container']).to eq 'production_web_1'
          end
          it "cannot override a container set via CLI" do
            set_config_file_content config_file_path_home, { 'projects' => stack_config }
            Rancher::Shell::Config.load('project' => 'test1', 'stack' => 'qa', 'container' => 'qa_web_2')
            expect(Rancher::Shell::Config.get('options')['container']).to eq 'qa_web_2'
          end
        end
      end
      context "options.container is specified" do
        let(:container_config) { home_config.deep_merge('test1' => { 'options' => {'container' => 'qa_web_1'} }) }
        it "sets container if passed as part of project options" do
          set_config_file_content config_file_path_home, { 'projects' => container_config }
          Rancher::Shell::Config.load('project' => 'test1')
          expect(Rancher::Shell::Config.get('options')['container']).to eq 'qa_web_1'
        end
        it "cannot override a container set via CLI" do
          set_config_file_content config_file_path_home, { 'projects' => container_config }
          Rancher::Shell::Config.load('project' => 'test1', 'container' => 'qa_web_2')
          expect(Rancher::Shell::Config.get('options')['container']).to eq 'qa_web_2'
        end
      end
      context "options.command is specified" do
        let(:command_config) { home_config.deep_merge('test1' => { 'options' => {'command' => 'bash'}, 'stacks' => { 'staging' => { 'options' => { 'command' => '/bin/bash' } } } }) }
        it "sets command if passed as part of project options" do
          set_config_file_content config_file_path_home, { 'projects' => command_config }
          Rancher::Shell::Config.load('project' => 'test1')
          expect(Rancher::Shell::Config.get('options')['command']).to eq 'bash'
        end
        it "sets command if passed as part of stack options" do
          set_config_file_content config_file_path_home, { 'projects' => command_config }
          Rancher::Shell::Config.load('project' => 'test1', 'stack' => 'staging')
          expect(Rancher::Shell::Config.get('options')['command']).to eq '/bin/bash'
        end
        it "cannot override a container set via CLI" do
          set_config_file_content config_file_path_home, { 'projects' => command_config }
          Rancher::Shell::Config.load('project' => 'test1', 'command' => 'bundle exec rails console')
          expect(Rancher::Shell::Config.get('options')['command']).to eq 'bundle exec rails console'
        end
      end
    end

  end

end
