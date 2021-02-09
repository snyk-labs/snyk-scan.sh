#!/usr/bin/env bash
#
# this script requires bash 4+, GNU egrep, and snyk CLI 
#
# recurse through directory structure and snyk scan each 
# project for a given list of file types
#
# $1 -> scanMode: one of [monitor, test]
# $2 -> projectType: one of [
#   javascript, python, java_maven, java_gradle, 
#   dotnet, ruby, golang, cocoapods, scala, php, all
# ]
# all is a special case that will iterate through each type
scanMode=$1
projectType=$2

# set default exitCode for the entire set of scans
finalExitCode=0

# track the number of projects that resulted in a specific exit code
declare -A numExitCodes
numExitCodes[0]=0
numExitCodes[1]=0
numExitCodes[2]=0

# mapping of manifest files to project type
declare -A projectTypes
projectTypes['javascript']="package\.json|yarn\.lock"
projectTypes['python']="requirements\.txt|pyproject\.toml"
projectTypes['java_maven']="pom\.xml"
projectTypes['java_gradle']="build\.gradle"
projectTypes['dotnet']="\.sln|\.csproj|packages\.config|project\.json|paket\.dependencies|project\.assets\.json"
projectTypes['ruby']="gemfile\.lock"
projectTypes['golang']="go\.mod|vendor/vendor\.json|Gopkg\.lock"
projectTypes['cocoapods']="Podfile"
projectTypes['scala']="build\.sbt"
projectTypes['php']="composer\.lock"

echo "scanMode set to: ${scanMode}"
echo "projectType set to: ${projectType}"

# snyk monitor snapshots will be stored under this grouping
projectGroup=$(basename `pwd`)

echo "projectGroup set to: ${projectGroup}"

snyk_scan(){
    echo "testing manifest: ${1}"
    projectName="${1:2}"
    echo "project name: ${projectName}"
    snyk $scanMode --file="${1}" --project-name="${projectName}" --remote-repo-url="${projectGroup}"
    return $?
}

snyk_scan_by_type(){
    echo "will look for files matching: ${projectTypes[$1]}"
    echo ""
    for manifest in $(find . -name "*" | egrep "${projectTypes[$1]}"); do 
        snyk_scan $manifest; currentExitCode=$?
        if [[ $currentExitCode -gt $finalExitCode ]]; then
          finalExitCode=$currentExitCode
        fi
        ((numExitCodes[$currentExitCode]=numExitCodes[$currentExitCode]+1))
    done 
}

# unless projectType is 'all' process the specific types of projects
if [[ "${projectType}" != "all" ]]; then
    snyk_scan_by_type $projectType
else # iterate through all known project types
    echo "will look for all known project types"
    echo ""
    for pt in "${!projectTypes[@]}"; do
        echo "checking for ${pt} manifests matching: ${projectTypes[$pt]}"
        snyk_scan_by_type $pt
    done
fi

echo ""

if [[ "${scanMode}" == "test" ]]; then
    echo "Project Test Summary by Exit Code:"
    echo " - (0) No Vulns: ${numExitCodes[0]}"
    echo " - (1) Vulns: ${numExitCodes[1]}"
    echo " - (2) Scanning Error: ${numExitCodes[2]}"
elif [[ "${scanMode}" == "monitor" ]]; then
    echo "Project Monitor Summary by Exit Code:"
    echo " - (0) Success: ${numExitCodes[0]}"
    echo " - (1) Error: ${numExitCodes[1]}"
    echo " - (2) Scanning Error: ${numExitCodes[2]}"
fi

echo ""
echo "Exiting with code ${finalExitCode}"
exit $finalExitCode
