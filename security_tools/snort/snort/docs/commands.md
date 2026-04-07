1. Install
```
sudo apt install snort
```
2. Config
```
sudo nano /etc/snort/snort.conf  
```
(change $HOME_NET "any" to IP Adress Host (HIDS) /  or .0/24 instead of /32 for Subnet (NIDS)

```
sudo nano /etc/snort/rules/local.rules
```
3. for promisc mode on: 
```
sudo ip link set ens18 promisc on
```

4. Test Config with: 
```
sudo snort -T -i ens18 -c /etc/snort/snort.conf
```
5. Run:
```
sudo snort -q -l /var/log/snort -i ens18 -A console -c /etc/snort/snort.conf
```
