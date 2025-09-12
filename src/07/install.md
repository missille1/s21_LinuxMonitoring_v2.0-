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
