# ***This repository is no longer maintained***
# It has been moved to the maidsafe-archive organisation for reference only
#
#
#
#

To run tests, first install LinkChecker (http://wummel.github.io/linkchecker).
Then clone this repository, cd into its root and run:

ctest -S ContinuousTest.cmake
or
ctest -S NightlyTest.cmake


To add a new website to be checked, create a suitably-named folder in Websites, then inside that
folder add 2 files; cmake.config and link_checker.config.  See Websites/MaidSafe for an example of
the contents required in the 2 files.  You do not need to add the website's repository, it will be
cloned automatically when CTest is run.
