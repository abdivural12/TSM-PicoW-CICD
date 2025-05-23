# CI/CD
Project to build a CI/CD pipeline for the RP2040 with docker.

## Cheat Sheet
- Create repository on GitHub
- Push repo to repository
- Verify it is building
- Create tunnel connection:
```
JLinkRemoteServerCL -UseTunnel -TunnelBySN -select="801048205"
```
- Tunnel connection to an IP based probe:
```
JLinkRemoteServerCL -UseTunnel -TunnelBySN -select="192.168.1.123"
```
- run docker desktop (to run its deamon), if not already running
- terminal/cd to root and create docker image (that might take a while):
```
docker build -t cicd-image .
```
- create container from image:
```
docker create -i -t --name cicd-container cicd-image
```
 
- start container:
```
docker start -i cicd-container
```

- Run tests with JRun:
```
cd /project
JRun --verbose --device RP2040_M0_0 --rtt -if SWD --ip "tunnel:801048205" --jlinkscriptfile "/project/src/tests/test_1.JLinkScript"  /project/build/debug-test/TSM_PicoW_CI_CD.elf
```

- Run test with ctest:
```
cd /project
ctest --verbose --extra-verbose --test-dir build/debug-test
```

- Inspect the files in the container, then use 'exit'
- Check .github/workflows folder which defines GitHub actions

## Debug Probe
- Note: depending on network latency, probe speed and characteristics, tunneling might be unstable.
- Identify serial number of SEGGER J-Link debug probe with JLinkConfig
- use serial number in launch.json:
```
"serialNumber": "261006357",
```
- for a tunnel connection:
```
"ipAddress": "tunnel:261006357"
```
- in the docker image, the J-Link files are here:
```
/opt/SEGGER/JLink/
```
- Settings for the J-Link connection ID: check the CMakeLists.txt inside the tests folder.
- running the tests locally in the docker container:
```
docker start -i tsmcicd-container
```
- Run test with JRun:
```
JRun --verbose --device RP2040_M0_0 --rtt -if SWD --ip "tunnel:801048205" --jlinkscriptfile "/project/src/tests/test_1.JLinkScript" /project/build/debug-test/TSM_PicoW_CI_CD.elf
```
- Run tests with CTtest:
```
ctest --verbose --extra-verbose --test-dir build/debug-test
```

## Trigger Action with Commit
Trigger the action with a tag push:
```
git tag v0.0.1
git push origin v0.0.1
```
## Links
- https://wiki.segger.com/J-Link_Docker_Container
- https://mcuoneclipse.com/2017/02/05/remote-board-debugging-j-link-remote-server-with-eclipse/
- https://mcuoneclipse.com/2023/10/02/ci-cd-for-embedded-with-vs-code-docker-and-github-actions/

