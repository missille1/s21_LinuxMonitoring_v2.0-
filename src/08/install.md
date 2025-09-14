### add json
Node Exporter Quickstart and Dashboard.json

### test stress
- ../02/main.sh
- stress -c 2 -i 1 -m 1 --vm-bytes 32M -t 10s
- stress -c 4 -i 1 -m 1 --vm-bytes 1000M -t 10m

### screen after test
![grafana my]( img/Screenshot%20From%202025-09-13%2001-43-52.png "Optional title")

### VM1 VM2 install iperf3 and test 
- sudo apt-get install -y iperf3
- VM2 
```
iperf3 -s
```
- VM1 
```
iperf3 -c 192.168.56.108 -t 30
iperf3 -u -b 200M -c 192.168.56.108 -t 30
```
### screen after test
![grafana my]( img/Screenshot%20From%202025-09-14%2015-37-22.png "Optional title")
