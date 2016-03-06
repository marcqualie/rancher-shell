# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).



## [0.2.0] - 2016-03-06

### Added

- Commands: list-projects, list-containers
- Multi level configuration including root, project and stack level customization
- Custom command on boot rather than always using /bin/bash

### Changed
- Input is sent to containers in real-time instead of line by line
- Commands such as CTRL+C can now be sent to containers without killing the shell session

### Fixed
- BUG: Commands are no longer duplicated back to client due to local buffer caching



## [0.1.0] - 2016-02-23

### Added
- Session can now be created entirely from rancher-shell.yml
