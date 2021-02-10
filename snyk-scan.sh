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
numExitCodes=(0 0 0)

# mapping of manifest files to project type
projectTypes_javascript="package.json|yarn.lock"
projectTypes_python="requirements.txt|pyproject.toml"
projectTypes_java_maven="pom.xml"
projectTypes_java_gradle="build.gradle"
projectTypes_dotnet=".sln|.csproj|packages.config|project.json|paket.dependencies|project.assets.json"
projectTypes_ruby="gemfile.lock"
projectTypes_golang="go.mod|vendor/vendor.json|Gopkg.lock"
projectTypes_cocoapods="Podfile"
projectTypes_scala="build.sbt"
projectTypes_php="composer.lock"

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

snyk_gen_file_list(){
    file_array=($(echo $1 | tr '|' ' '))

    unset file_string

    for fname in ${file_array[@]}; do
        if [ -n "${file_string+set}" ]; then
            # we append a -o since this is the second file
            file_string+=" -o"
        fi
        file_string+=" -name *${fname}"
    done

    echo "$file_string"
}

snyk_scan_by_type(){
    echo "will look for files matching: ${!1}"
    echo ""
    search_string=$(snyk_gen_file_list ${!1})
    for manifest in $(find . -type f \( $search_string \) -not -path '*/\.*'); do 
        snyk_scan $manifest; currentExitCode=$?
        if [[ $currentExitCode -gt $finalExitCode ]]; then
          finalExitCode=$currentExitCode
        fi
        ((numExitCodes[$currentExitCode]=numExitCodes[$currentExitCode]+1))
    done 
}

# unless projectType is 'all' process the specific types of projects
if [[ "${projectType}" != "all" ]]; then
    pt="projectTypes_${projectType}"
    snyk_scan_by_type $pt
else # iterate through all known project types
    echo "will look for all known project types"
    echo ""
    # ${!projectTypes_*} expands to all our variables that start with projectType_
    for pt in ${!projectTypes_*}; do
        # ${pt#*_} chomps projectTypes_, giving us java, etc
        # ${!pt} takes the string "projectTypes_java" and uses it as a variable name instead
        echo "checking for ${pt#*_} manifests matching: ${!pt}"
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
