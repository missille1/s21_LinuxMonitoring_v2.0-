### install prometheus

```
sudo apt-get install -y prometheus
```
```
sudo systemctl status prometheus
```
- add autostart
```
sudo systemctl enable --now prometheus
sudo systemctl enable --now prometheus-node-exporter
sudo systemctl enable --now grafana-server
```
### install grafana

- connect to download grafana
```
ssh -D 8092 <username>@<ip> -p <port> -N -f
```
- download grafana deb 
```
curl --socks5 127.0.0.1:8092 -LO https://dl.grafana.com/oss/release/grafana_10.4.2_amd64.deb
```
- install deb
```
sudo dpkg -i grafana_*.deb
```
- reload grafana
```
sudo systemctl daemon-reload
```
```
sudo systemctl enable grafana-server
```
```
sudo systemctl start grafana-server
```
```
sudo systemctl status grafana-server
```
### default ports

Prometheus: 9090

node_exporter: 9100

Grafana: 3000

### config
```
sudo sed -n '1,200p' /etc/prometheus/prometheus.yml
```
```
sudo systemctl restart prometheus
```
### open prometheus and grafana on host
apply hostonly adapter 2 virtualbox
```
http://192.168.56.104:9090
http://192.168.56.104:3000 (admin/admin)
```
### connect prometheus to grafana
Grafana: Connections → Data sources → Add data source → Prometheus.
URL: http://192.168.56.104:9090 → Save & Test.

### add graph
cpu
```
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)
```
ram
```
node_memory_MemAvailable_bytes / 1024 / 1024 / 1024
(node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100 
```
disk
```
sum by (instance, mountpoint) (
  node_filesystem_avail_bytes{fstype!~"tmpfs|devtmpfs|overlay"}
) / 1024 / 1024 / 1024
```
write and read disk
```
sum by (instance) (rate(node_disk_writes_completed_total{device=~"sd.*|vd.*|nvme.*"}[1m]))
sum by (instance) (rate(node_disk_reads_completed_total{device=~"sd.*|vd.*|nvme.*"}[1m]))
```
###
![grafana my]( img/Screenshot%20From%202025-09-13%2000-35-23.png "Optional title")

### test
- ../02/main.sh
- stress -c 2 -i 1 -m 1 --vm-bytes 32M -t 10s
- stress -c 4 -i 1 -m 1 --vm-bytes 1000M -t 10m
