IP='139.68.100.156'

sshpass -p 'Bose123' scp -O -oHostKeyAlgorithms=+ssh-rsa jack_dep root@${IP}:/home/root
sshpass -p 'Bose123' scp -O -oHostKeyAlgorithms=+ssh-rsa libfmt.so.10 root@${IP}:/usr/lib
sshpass -p 'Bose123' scp -O -oHostKeyAlgorithms=+ssh-rsa libboost_program_options.so.1.66.0 root@${IP}:/usr/lib
