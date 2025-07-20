## ELK Stack Installation and Setup Documentation

1. Add Elasticsearch GPG key:

```bash
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
```

2. Install apt HTTPS transport:

```bash
sudo apt-get install apt-transport-https
```

3. Add Elasticsearch repository:

```bash
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/9.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-9.x.list
```

4. Update and install Elasticsearch:

```bash
sudo apt-get update && sudo apt-get install elasticsearch
```

5. Edit Elasticsearch config:

```bash
sudo nano /etc/elasticsearch/elasticsearch.yml
```

Set:

```yaml
network.host: 192.168.0.X
```

*(can be IP, localhost, or 0.0.0.0)*

6. Manage Elasticsearch service:

```bash
sudo systemctl status elasticsearch
sudo systemctl start elasticsearch
sudo systemctl enable elasticsearch
```

7. Install Logstash:

```bash
sudo apt-get install logstash
sudo systemctl start logstash
sudo systemctl enable logstash
```

8. Install Kibana:

```bash
sudo apt-get install kibana
```

*(Do not start or enable Kibana yet)*

9. Edit Kibana config:

```bash
sudo nano /etc/kibana/kibana.yml
```

Set:

```yaml
server.host: 0.0.0.0
server.port: 5601
```

*(can be 0.0.0.0, localhost, or its IP)*

At the end of the file, add username/password for web GUI.

10. Generate Kibana verification code:

```bash
sudo /usr/share/kibana/bin/kibana-verification-code
```

11. Reset passwords:

```bash
sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password --username kibana_system
```

*(kibana_system does not have sudo for web GUI)*

Use instead for web GUI login:

```bash
sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password --username elastic
```

12. Start and enable Kibana:

```bash
sudo systemctl start kibana
sudo systemctl enable kibana
```

13. Restart Elasticsearch and Kibana:

```bash
sudo systemctl restart elasticsearch
sudo systemctl restart kibana
```

Log in to Kibana web GUI at:

```
http://IP:5601
```
