```
sudo nano /etc/ansible/hosts
```

```
[linux_nodes]
nodeA ansible_host=192.168.0.X ansible_user=nodeA ansible_become_pass=passwordforA
nodeB ansible_host=192.168.0.Y ansible_user=nodeB ansible_become_pass=passwordforB
nodeC ansible_host=192.168.0.Z ansible_user=nodeC ansible_become_pass=passwordforC
```
