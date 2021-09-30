# snyk-scan.sh
prototype monorepo utility wrapper for Snyk CLI
###  Basic Examples
```
snyk-scan.sh --mode=test --type=java_gradle
```
```
snyk-scan.sh --mode=test --type=all
```
```
snyk-scan.sh --mode=monitor --type=javascript
```
```
snyk-scan.sh --mode=monitor --type=all
```
### Other uses
You can also provide a version string, if you want to track multiple versions of the same repo/app
```
snyk-scan.sh --mode=monitor --version=1.2.3
```
You can also generate a local html report for each project tested. This will result in a test only, regardless of --mode value.  If you require monitor, call the script twice.
This requires [https://github.com/snyk/snyk-to-html](https://github.com/snyk/snyk-to-html) to be available.
```
snyk-scan.sh --html=1 --type=all
```
You can use snyk-scan.sh with [snyk-delta](https://github.com/snyk-tech-services/snyk-delta) for --mode=test, allowing you to fail the tests in situations where the issues are only new to the project being scanned. This is useful in a CI context to prevent adding new vulnerabilities to a repository. This requires snyk-delta is installed and present in $PATH of the script.
```
snyk-scan.sh --mode=test --type=java_maven --delta=1
```
Snyk's excludes are also supported, by using --ignore (to prevent overlapping with snyk's built in --exclude flag) when calling the script. These ignores are in addition to the baseline ignores: ` ! -path */\.* ! -path */node_modules/* ! -path */vendor/* ! -path */submodules/*`
```
snyk-scan.sh --mode=test --type=java_maven --delta=1 --ignore=ci-cd,resources
```