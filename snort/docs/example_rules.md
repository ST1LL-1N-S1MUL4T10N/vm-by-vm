alert icmp any any -> $HOME_NET any (msg:"U GOT PINGED!!!"; sid:100001; rev:1;)

alert tcp/udp any any -> $HOME_NET any (msg:"Your message here!"; sid:next_number; rev:1;)

---

# Honeypot
alert tcp any any -> $HOME_NET 22 (msg:"SOMEONE TRAPPED IN HONEYPOT!!!"; sid:100001; rev:1;)

# SSH
alert tcp any any -> $HOME_NET 2200 (msg:"SSH ATTEMPT TO REAL HOST DETECTED!!!"; sid:100002; rev:1;)

# DNS
alert udp any any -> $HOME_NET 53 (msg:"[DNS] Query to Local DNS Server"; sid:100003; rev:1;)

# DHCP
alert udp any 67 -> $HOME_NET 68 (msg:"[NET] DHCP Offer Detected"; sid:100004; rev:1;)

# netboot.xyz
alert udp any any -> $HOME_NET 69 (msg:"SOMEONE IS USING [NETBOOT]"; sid:100008; rev:1;)
