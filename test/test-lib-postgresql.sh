#!/bin/bash
#
# Functions for tests for the PostgreSQL image in OpenShift.
#
# IMAGE_NAME specifies a name of the candidate image used for testing.
# The image has to be available before this script is executed.
#

THISDIR=$(dirname ${BASH_SOURCE[0]})

source "${THISDIR}"/test-lib.sh
source "${THISDIR}"/test-lib-openshift.sh
source "${THISDIR}"/test-lib-remote-openshift.sh

function test_postgresql_integration() {
  local service_name=postgresql
  TEMPLATES="postgresql-ephemeral-template.json
  postgresql-persistent-template.json"
  for template in $TEMPLATES; do
    ct_os_test_template_app_func "${IMAGE_NAME}" \
                                 "${THISDIR}/examples/${template}" \
                                 "${service_name}" \
                                 "ct_os_check_cmd_internal '<SAME_IMAGE>' '${service_name}-testing' 'PGPASSWORD=testp pg_isready -t 15 -h <IP> -U testu -d testdb' 'accepting connections' 120" \
                                 "-p POSTGRESQL_VERSION=${VERSION} \
                                  -p DATABASE_SERVICE_NAME="${service_name}-testing" \
                                  -p POSTGRESQL_USER=testu \
                                  -p POSTGRESQL_PASSWORD=testp \
                                  -p POSTGRESQL_DATABASE=testdb"
  done
}

# Check the imagestream
function test_postgresql_imagestream() {
  local tag="-el7"
  if [ "${OS}" == "rhel8" ]; then
    tag="-el8"
  elif [ "${OS}" == "rhel9" ]; then
    tag="-el9"
  fi
  # TODO
  # Delete this as soon as postgresql image reached GA
  if [ "${VERSION}" == "15" ]; then
    echo "WARNING: Version ${VERSION} does not reach GA."
    echo "WARNING: Remove this condition as soon as it will be available."
    return 0
  fi
  ct_os_test_image_stream_template "${THISDIR}/imagestreams/postgresql-${OS%[0-9]*}.json" "${THISDIR}/examples/postgresql-ephemeral-template.json" postgresql "-p POSTGRESQL_VERSION=${VERSION}${tag}"
}


function run_latest_imagestreams_test() {
  local result=1
  # Switch to root directory of a container
  echo "Testing the latest version in imagestreams"
  pushd "${THISDIR}/.." >/dev/null || return 1
  ct_check_latest_imagestreams
  result=$?
  popd >/dev/null || return 1
  return $result
}

# vim: set tabstop=2:shiftwidth=2:expandtab:
