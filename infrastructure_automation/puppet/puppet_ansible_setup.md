
---

# Puppet Setup with Ansible on Ubuntu 24.04

---

## 1️⃣ Ansible Setup

### Inventory Configuration

```bash
sudo apt install ansible-core
```

```bash
sudo mkdir -p /etc/ansible
```

```bash
sudo nano /etc/ansible/hosts
```

Inventory file: `/etc/ansible/hosts`

```ini
[puppet_nodes]
puppetclient ansible_host=192.168.0.8 ansible_user=puppetclient ansible_become_pass=puppet
puppetserver ansible_host=192.168.0.77 ansible_user=puppetserver ansible_become_pass=puppet
```

---

### SSH Key Setup (Control Machine)

1. **Generate SSH key pair**

```bash
ssh-keygen
```

2. **Copy public key to nodes**

```bash
ssh-copy-id puppetclient@192.168.0.8
ssh-copy-id puppetserver@192.168.0.77
```

---

### Update, Upgrade, and Reboot All Hosts

```yaml
---
- name: Update, upgrade, and reboot all hosts
  hosts: all
  become: true
  tasks:

    - name: Update apt cache
      ansible.builtin.apt:
        update_cache: yes

    - name: Upgrade all packages
      ansible.builtin.apt:
        upgrade: dist
        autoremove: yes

    - name: Reboot if needed
      ansible.builtin.reboot:
        reboot_timeout: 600
        pre_reboot_delay: 10
        post_reboot_delay: 30
```

---

### Configure `/etc/hosts` on All Nodes

```yaml
---
- name: Configure /etc/hosts on all nodes
  hosts: all
  become: true
  vars:
    hosts_entries:
      - "192.168.0.8 puppetclient"    # replace with actual puppet client IP
      - "192.168.0.77 puppetmaster"   # replace with actual puppet master IP

  tasks:
    - name: Add entries to /etc/hosts
      ansible.builtin.lineinfile:
        path: /etc/hosts
        line: "{{ item }}"
        state: present
        insertafter: EOF
      loop: "{{ hosts_entries }}"
```

---

## 2️⃣ Manual Puppet Setup

### Install and Configure Puppet Server (Master Node)

1. **Update package repository index**

```bash
sudo apt update
```

2. **Install Puppet server**

```bash
sudo apt install puppet-master -y
```

3. **Check Puppet version**

```bash
puppet --version
```

4. **Edit Puppet server default configuration**

```bash
sudo nano /etc/default/puppetserver
```

5. **Modify memory settings**

```text
JAVA_ARGS="-Xms1g -Xmx1g -Djruby.logger.class=com.puppetlabs.jruby_utils.jruby.Slf4jLogger"
```

6. **Save and exit the file.**

7. **Start Puppet service**

```bash
sudo systemctl start puppetserver
```

8. **Enable Puppet service on boot**

```bash
sudo systemctl enable puppetserver
```

9. **Check Puppet service status**

```bash
sudo systemctl status puppetserver
```

* Output should show service as **active (running)**.

---

### Install and Configure Puppet Agent (Client Node)

1. **Update package repository index**

```bash
sudo apt update
```

2. **Install Puppet agent**

```bash
sudo apt install puppet-agent -y
```

3. **Edit Puppet configuration file**

```bash
sudo nano /etc/puppet/puppet.conf
```

4. **Add Puppet master information**

```ini
[main]
certname = puppetclient
server = puppetserver
```

5. **Save and exit the file.**

6. **Start Puppet agent service**

```bash
sudo systemctl start puppet
```

7. **Enable Puppet agent on boot**

```bash
sudo systemctl enable puppet
```

8. **Check Puppet agent service status**

```bash
sudo systemctl status puppet
```

* Output should show **active (running)**.

---

### Sign Puppet Agent Certificates (On Puppet Master)

1. **List available certificates**

```bash
sudo /usr/bin/puppetserver ca list --all
```

2. **Sign all certificates**

```bash
sudo /usr/bin/puppetserver ca sign --all
```

---
