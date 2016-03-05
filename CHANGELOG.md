# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).



## [Unreleased]

### Changed
- Input is sent to containers in real-time instead of line by line
- Commands such as CTRL+C can now be sent to containers without killing the shell session

### Fixed
- BUG: Commands are no longer duplicated due to client side buffering of input



## [0.1.0] - 2016-02-23

### Added
- Session can now be created entirely from rancher-shell.yml
