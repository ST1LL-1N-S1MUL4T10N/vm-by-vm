
```bash
cd /tmp
wget https://packages.ntop.org/apt-stable/24.04/all/apt-ntop-stable.deb
sudo apt install ./apt-ntop-stable.deb
```

---

✅ After the `.deb` installs successfully, you can run:

```bash
sudo apt update
sudo apt install ntopng
sudo systemctl enable --now ntopng
```

Then access the web UI at `http://localhost:3000` (login: `admin/admin`).

---

