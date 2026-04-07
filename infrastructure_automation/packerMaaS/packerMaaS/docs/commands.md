sudo snap install maas
sudo snap install maas-test-db
sudo maas init region+rack --database-uri maas-test-db:///
sudo maas createadmin

wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install packer
sudo apt update
sudo apt install qemu-utils qemu-system ovmf cloud-image-utils make curtain git libnbd-bin nbdkit fuse2fs

ls
pwd

git clone https://github.com/canonical/packer-maas.git
sudo packer init ubuntu-cloudimg.pkr.hcl
sudo make custom-cloudimg.tar.gz

la
ls

sudo maas apikey --username=omega > ~/api-key-file

cat ~/api-key-file

maas login omega http://localhost:5240/MAAS/api/2.0/ $(head -1  ~/api-key-file)

maas omega boot-resources create name='custom/cloudimg-tgz' title='Ubuntu Custom TGZ' architecture='amd64/generic' filetype='tgz' content@=custom-cloudimg.tar.gz
