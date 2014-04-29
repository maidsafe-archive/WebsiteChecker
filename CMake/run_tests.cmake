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


# Get websites' config info (repository name and website URL)
file(GLOB Websites RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}/Websites" "${CMAKE_CURRENT_SOURCE_DIR}/Websites/*")

# Set hostname
find_program(HostnameCommand NAMES hostname)
execute_process(COMMAND ${HostnameCommand} OUTPUT_VARIABLE Hostname OUTPUT_STRIP_TRAILING_WHITESPACE)
set(CTEST_SITE "${Hostname}")

# Find Git
include(CMake/maidsafe_find_git.cmake)
set(CTEST_GIT_COMMAND "${Git_EXECUTABLE}")

# Find LinkChecker
find_program(LINK_CHECKER NAMES linkchecker)
if(NOT LINK_CHECKER)
  set(Msg "\nCouldn't find the LinkChecker executable.  See http://wummel.github.io/linkchecker for installation details.")
  set(Msg "${Msg}  If LinkChecker is already installed, run:\n  ctest -DLINK_CHECKER=\"<path to exe>\" -S ContinuousTest.cmake")
  message(FATAL_ERROR "${Msg}")
endif()
file(TO_CMAKE_PATH "${LINK_CHECKER}" LINK_CHECKER)

# Set commands
set(CTEST_UPDATE_COMMAND "${CTEST_GIT_COMMAND}")
set(CTEST_COMMAND "")

foreach(Website ${Websites})
  # Get website's config info (repository name and website URL)
  include(Websites/${Website}/config.cmake)
  set(CTEST_BUILD_NAME "${Website} Website")

  # Set dirs
  get_filename_component(CTEST_SOURCE_DIRECTORY ./Websites/${Website}/repository ABSOLUTE)
  get_filename_component(CTEST_BINARY_DIRECTORY . ABSOLUTE)

  # Clone source if required
  if(NOT EXISTS "${CTEST_SOURCE_DIRECTORY}")
    message("Cloning ${Website} website repository (this may take a long time).")
    set(CTEST_CHECKOUT_COMMAND "${CTEST_GIT_COMMAND} clone ${Repository} ${CTEST_SOURCE_DIRECTORY}")
    set(IsFreshlyCloned ON)
  else()
    message("Updating ${Website} website repository.")
  endif()

  # Configure tests
  string(TOLOWER ${Website} WebsiteLowerCase)
  configure_file(CMake/CTestTestfile.cmake.in CTestTestfile.cmake @ONLY)
  ctest_start(${TestType} TRACK ${TestType})

  # Run tests
  ctest_update(RETURN_VALUE UpdatedCount)
  if(${UpdatedCount} LESS 0)
    message(FATAL_ERROR "Failed to update the ${Website} website repository.")
  elseif(${UpdatedCount} EQUAL 0 AND NOT IsFreshlyCloned AND "${TestType}" STREQUAL "Continuous")
    message("No updates to the ${Website} website repository; tests won't run.")
  else()
    message("Running tests for ${Website} website.")
    ctest_test(RETURN_VALUE Result)
    message("Submitting results for ${Website} website.")
    if(NOT ${Result} EQUAL 0)
      ctest_upload(FILES ${CTEST_BINARY_DIRECTORY}/Testing/${WebsiteLowerCase}_links_check.html)
    endif()
    ctest_submit(RETRY_COUNT 3 RETRY_DELAY 5)
  endif()
endforeach()
