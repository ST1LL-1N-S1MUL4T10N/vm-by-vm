alert icmp any any -> $HOME_NET any (msg:"U GOT PINGED!!!"; sid:100001; rev:1;)

alert tcp/udp any any -> $HOME_NET any (msg:"Your message here!"; sid:next_number; rev:1;)
