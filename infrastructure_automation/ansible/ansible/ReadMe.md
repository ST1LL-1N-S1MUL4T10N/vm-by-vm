# Ansible Quick Overview

---

### **What is Ansible?**
Ansible is an automation tool for configuring systems and deploying applications using YAML files.

---

### **Core Concepts**

- **Playbook**: A YAML file with tasks.
  ```yaml
  - hosts: all
    tasks:
      - name: Install nginx
        apt:
          name: nginx
          state: present
  ```

- **Inventory**: List of servers to manage.
  ```ini
  [webservers]
  192.168.1.10
  ```

- **Modules**: Actions like `apt`, `copy`, `service`.

---

### **Key Commands**

- **Check if hosts are reachable**:
  ```bash
  ansible all -m ping
  ```

- **Run Playbook**: 
  ```bash
  ansible-playbook playbook.yml
  ```


<img width="2514" height="994" alt="firstAnsible" src="https://github.com/user-attachments/assets/1aca9b4d-7f2e-419d-9ff2-2295ce43e7cc" />

<img width="2558" height="970" alt="firstPlaybook" src="https://github.com/user-attachments/assets/375f1177-1f4b-4ad1-9dee-6737d2f7c2eb" />
