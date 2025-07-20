# **capture and save the packets to a pcap file**:

```bash
sudo tcpdump -i ens18 udp port 123 -vv -w ntp_capture.pcap
```

* This will write the captured packets to `ntp_capture.pcap` in the current directory.
* It won’t show you packets on the terminal while capturing (unless you also add `-v` or `-vv`, but that usually doesn't print to stdout when writing to a file).
* To stop capturing, press `Ctrl+C`.

Later, you can **read the capture file** with tcpdump or Wireshark:

```bash
tcpdump -r ntp_capture.pcap -vv
```

```bash
sudo apt install wireshark -y && sudo wireshark
```

---

<img width="1776" height="1446" alt="ntptraffic" src="https://github.com/user-attachments/assets/fcf92c43-43b8-40dc-a0bf-2c1fe8b46d37" />

