#==================================================================================================#
#                                                                                                  #
#  Copyright 2014 MaidSafe.net limited                                                             #
#                                                                                                  #
#  This MaidSafe Software is licensed to you under (1) the MaidSafe.net Commercial License,        #
#  version 1.0 or later, or (2) The General Public License (GPL), version 3, depending on which    #
#  licence you accepted on initial access to the Software (the "Licences").                        #
#                                                                                                  #
#  By contributing code to the MaidSafe Software, or to this project generally, you agree to be    #
#  bound by the terms of the MaidSafe Contributor Agreement, version 1.0, found in the root        #
#  directory of this project at LICENSE, COPYING and CONTRIBUTOR respectively and also available   #
#  at: http://www.maidsafe.net/licenses                                                            #
#                                                                                                  #
#  Unless required by applicable law or agreed to in writing, the MaidSafe Software distributed    #
#  under the GPL Licence is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF   #
#  ANY KIND, either express or implied.                                                            #
#                                                                                                  #
#  See the Licences for the specific language governing permissions and limitations relating to    #
#  use of the MaidSafe Software.                                                                   #
#                                                                                                  #
#==================================================================================================#


# Set hostname
find_program(HostnameCommand NAMES hostname)
execute_process(COMMAND ${HostnameCommand} OUTPUT_VARIABLE Hostname OUTPUT_STRIP_TRAILING_WHITESPACE)
set(CTEST_SITE "${Hostname}")
set(CTEST_BUILD_NAME "N.A.")

# Set dirs
get_filename_component(CTEST_SOURCE_DIRECTORY ./maidsafe.github.io ABSOLUTE)
get_filename_component(CTEST_BINARY_DIRECTORY . ABSOLUTE)

# Find Git
include(CMake/maidsafe_find_git.cmake)
set(CTEST_GIT_COMMAND "${Git_EXECUTABLE}")

# Find LinkChecker
find_program(LINK_CHECKER NAMES linkchecker)
if(NOT LINK_CHECKER)
  set(Msg "\nCouldn't find the LinkChecker executable.  See http://wummel.github.io/linkchecker for installation details.")
  set(Msg "${Msg}  If LinkChecker is laready installed, run:\n  ctest -DLINK_CHECKER=\"<path to exe>\" -S ContinuousTest.cmake")
  message(FATAL_ERROR "${Msg}")
endif()
file(TO_CMAKE_PATH "${LINK_CHECKER}" LINK_CHECKER)

# Set commands
set(CTEST_UPDATE_COMMAND "${CTEST_GIT_COMMAND}")
set(CTEST_COMMAND "")

# Clone source if required
if(NOT EXISTS "${CTEST_SOURCE_DIRECTORY}")
  message("Cloning repository (this may take a long time).")
  set(CTEST_CHECKOUT_COMMAND "${CTEST_GIT_COMMAND} clone git@github.com:maidsafe/maidsafe.github.io ${CTEST_SOURCE_DIRECTORY}")
  set(IsFreshlyCloned ON)
else()
  message("Updating repository.")
endif()

# Configure tests
configure_file(CMake/CTestTestfile.cmake.in CTestTestfile.cmake @ONLY)
ctest_start(Continuous TRACK Continuous)

# Run tests
ctest_update(RETURN_VALUE UpdatedCount)
if(${UpdatedCount} LESS 0)
  message(FATAL_ERROR "Failed to update the repository.")
elseif(${UpdatedCount} EQUAL 0 AND NOT IsFreshlyCloned)
  message("No updates; tests won't run.")
  return()
endif()
message("Running tests.")
ctest_test()
message("Submitting results.")
ctest_upload(FILES /home/maidsafe/Maidsafe-Website-Testing/WebsiteChecker/maidsafe_links_check.html)
ctest_submit(RETRY_COUNT 3 RETRY_DELAY 5)
