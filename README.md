# RancherShell

[![Gem Version](https://badge.fury.io/rb/rancher-shell.svg)](https://badge.fury.io/rb/rancher-shell)
[![Build Status](https://travis-ci.org/marcqualie/rancher-shell.svg?branch=master)](https://travis-ci.org/marcqualie/rancher-shell)

A console utility for shelling into [Rancher](http://rancher.com) containers



## Installation

RancherShell runs as a binary on your system and only needs rubygems to be installed:

``` ruby
gem install rancher-shell
```


## Confguration

Configuration files are loaded in the following order if they exist:

- ~/.rancher-shell.yml
- ./.rancher-shell.yml

Files are merged using the following schema:

``` yaml
---
# ~/.rancher-shell.yml
projects:
  project1:
    name: "My First Project"
    options:
      container: production_web_1
      command: bundle exec rails console
    stacks:
      staging:
        options:
          container: staging_web_1
    api:
      host: rancher.yourdomain.com
      key: XXXXX
      secret: XXXXX
```

``` yaml
---
# /path/to/project1/.rancher-shell.yml
options:
  project: project1
projects:
  project1:
    stacks:
      qa:
        options:
          container: qa_web_1
```

Running `rancher-shell exec` with the above config will run command `bundle exec rails console` on `project1` within container `production_web_1`. Running `rancher-shell exec -s staging` will run the same command but within container `staging_web_1`. Full usage instructions on how to override these configs is at `rancher-shell help exec`.



## Usage

After configuring you can shell into your container using the following command:

``` shell
rancher-shell exec [-p project] [-s stack] [-c container] [command]
```

Run `rancher-shell help` for full usage instructions



## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).



## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marcqualie/rancher-shell. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.



## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
