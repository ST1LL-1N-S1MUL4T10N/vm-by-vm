```
sudo nano /etc/apt/apt.conf.d/01proxy
```

```
Acquire::http { Proxy "http://SERVER_IP:3142"; };
```

To Test if connected:
```
curl -x http://your-proxy-ip:port http://archive.ubuntu.com/ubuntu/README
```
