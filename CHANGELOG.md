# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## [v0.9.0](https://github.com/TwistingTwists/fluid/compare/v0.8.0...v0.9.0) (2024-06-26)




### Features:

* allocations with the tanks

### Bug Fixes:

* add relevant error

* rename functions

## [v0.8.0](https://github.com/TwistingTwists/fluid/compare/v0.7.0...v0.8.0) (2024-06-23)




### Features:

* connect/2 takes ids

* warehosue_tests passing with world.id

* new migrations

## [v0.7.0](https://github.com/TwistingTwists/fluid/compare/v0.6.3...v0.7.0) (2024-05-31)




### Features:

* module 009 allocations for pools

* add volume to tank and pools

* allocations module

### Bug Fixes:

* migrations for allocations - string

* factory setup with volumes + tank api updated

* Tag Rank is now represented as Tuple

## [v0.6.3](https://github.com/TwistingTwists/fluid/compare/v0.6.2...v0.6.3) (2024-05-03)




## [v0.6.2](https://github.com/TwistingTwists/fluid/compare/v0.6.1...v0.6.2) (2024-05-03)




## [v0.6.1](https://github.com/TwistingTwists/fluid/compare/v0.6.0...v0.6.1) (2024-05-02)




## [v0.6.0](https://github.com/TwistingTwists/fluid/compare/v0.5.0...v0.6.0) (2024-05-02)




### Features:

* two pps from two different warehouses

* excessive circularity between two warehouses

* tests pass with new pps definition

* overlap algorithm in PPS

### Bug Fixes:

* upgrade elixir and erlang

## [v0.5.0](https://github.com/TwistingTwists/fluid/compare/v0.4.0...v0.5.0) (2024-04-24)




### Features:

* pps = 2 , wh = 1

## [v0.4.0](https://github.com/TwistingTwists/fluid/compare/v0.3.0...v0.4.0) (2024-04-24)




### Features:

* detailed table for all cases for module 003

* more tests for pps

* first test for pps passes

* working pps analysis

* setup for PPS

* tag

* outline module definitions

* async tests in circularity

### Bug Fixes:

* more tests passing

* test naming in sync with Table in readme.md

* warehouse circularity

* mix of circularity - det and indet extracted out to Factory module

* filter only those WH where CT tags >= pool

## [v0.3.0](https://github.com/TwistingTwists/fluid/compare/v0.2.0...v0.3.0) (2024-03-21)




### Features:

* more refactoring

* refactoring basic

* classify indeterminate and determinate warehouses

* more warehouse tests

* subclassification for warehouse determinate is complete

* inbound and outbound connections tested

* basic circularity module in place

* update old interderminate tests

* circularity - determinate_classes as int array of ascii values

* circularity: determinate and indeterminate classes

* circularity: working Circularity logic

* circularity: Model.check_circularity/1 for list of warehouses

* circularity: added tests for a circular world

* circularity: Basic circularity for one warehouse

* errors: setup for custom errors

* fixtures for preventing connecting tanka nd pools in same warehouse

* can connect pool to a tank (both from different warehouses)

* pools can be added to warehouse

* add_tanks api

* make DefaultUCT Changeset more generic

### Bug Fixes:

* add script to test group of tests together

* added documentation to run circularity tests

* preserve inbound connections

* manual inspect shows postive results

* more test cases for indeterminate and determinate ONLY worlds

* ModelError

* calculations for uct in warehouse

* configure git_ops to include feat , fix , backends

## [v0.2.0](https://github.com/TwistingTwists/fluid/compare/v0.1.3...v0.2.0) (2024-01-31)




### Features:

* errors: setup for custom errors

* fixtures for preventing connecting tanka nd pools in same warehouse

* can connect pool to a tank (both from different warehouses)

* pools can be added to warehouse

* add_tanks api

* make DefaultUCT Changeset more generic

### Bug Fixes:

* calculations for uct in warehouse

## [v0.1.3](https://github.com/TwistingTwists/fluid/compare/v0.1.2...v0.1.3) (2024-01-28)




### Bug Fixes:

* configure git_ops to include feat , fix , backends

## [v0.1.2](https://github.com/TwistingTwists/fluid/compare/v0.1.2...v0.1.2) (2024-01-28)
