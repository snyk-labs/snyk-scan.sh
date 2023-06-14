![snyk-oss-category](https://github.com/snyk-labs/oss-images/blob/main/oss-example.jpg)

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
