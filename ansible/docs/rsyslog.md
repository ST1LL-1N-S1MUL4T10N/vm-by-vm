(Not tried out yet) https://medium.com/@meheraskri/how-to-configure-centralized-rsyslog-server-using-ansible-1a684e2e3f11
---

## 📘 Centralized Logging with Ansible + rsyslog

This setup uses **Ansible** to configure a **central rsyslog server** to receive logs over TCP and configure **client nodes** to forward error-level logs to the central server.

---

### 📁 Project Structure

```
rsyslog_test/
├── ansible.cfg
├── myinventory
├── playbook.yml
└── templates/
    └── remote.conf.j2
```

---

### 🔧 Step 1: Setup Inventory

**File:** `myinventory`

```
node1
node2
```

---

### ⚙️ Step 2: Ansible Configuration

**File:** `ansible.cfg`

```ini
[defaults]
inventory = myinventory
remote_user = ansible
host_key_checking = false

[privilege_escalation]
become = true
become_user = root
become_method = sudo
become_ask_pass = false
```

---

### 📜 Step 3: rsyslog Client Template

**File:** `templates/remote.conf.j2`

```conf
*.error @@10.1.1.100:514
```

> `@@` means TCP.
> If using UDP, use `@` instead.

---

### 🚀 Step 4: Playbook to Apply Configuration

**File:** `playbook.yml`

```yaml
- hosts: localhost
  tasks:
    - name: configure TCP rsyslog reception
      lineinfile:
        path: /etc/rsyslog.conf
        regexp: "{{ item.match }}"
        line: "{{ item.newline }}"
      loop:
        - { match: '^#module\(load="imtcp"\)', newline: 'module(load="imtcp")' }
        - { match: '^#input\(type="imtcp" port="514"\)', newline: 'input(type="imtcp" port="514")' }

    - name: create template
      blockinfile:
        block: |
          $template meher,"/mylogs/%HOSTNAME%/%syslogseverity-text%.log"
          *.*     -?meher
        path: /etc/rsyslog.conf
        state: present
      notify: restart_rsyslog

    - name: create the logs directory
      file:
        path: /mylogs
        state: directory

    - name: open the firewall port
      firewalld:
        port: 514/tcp
        state: enabled
        immediate: yes
        permanent: yes

  handlers:
    - name: restart_rsyslog
      service:
        name: rsyslog
        state: restarted

- name: configure clients
  hosts: node1,node2
  tasks:
    - name: create a jinja2 template
      template:
        src: templates/remote.conf.j2
        dest: /etc/rsyslog.d/remote.conf
        mode: '644'
        owner: root
        group: root

    - name: restart rsyslog
      service:
        name: rsyslog
        state: restarted
```

---

### ✅ Step 5: Run the Playbook

```bash
ansible-playbook playbook.yml
```

---

### 🔄 Expected Result

* Central server:

  * Listens on TCP port 514.
  * Stores logs in `/mylogs/<hostname>/<severity>.log`.

* Clients:

  * Forward all `error` or higher priority logs to the central server at `10.1.1.100` via TCP.

---
