
---

## **1. Install prerequisites**

```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
```

* Ensures `gnupg` (for verifying GPG keys) and `software-properties-common` (for managing repositories) are installed.
* In your case, both packages were already the latest version.

---

## **2. Add the HashiCorp GPG key**

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
```

* Downloads HashiCorp’s GPG key.
* Converts it to a keyring and stores it at `/usr/share/keyrings/hashicorp-archive-keyring.gpg`.

---

## **3. Verify the GPG key**

```bash
gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint
```

* Ensures the key is valid.
* Output shows a valid RSA4096 key for HashiCorp:

```
pub   rsa4096 2023-01-10 [SC] [expires: 2028-01-09]
uid           [ unknown] HashiCorp Security (HashiCorp Package Signing)
sub   rsa4096 2023-01-10 [S] [expires: 2028-01-09]
```

---

## **4. Add the HashiCorp APT repository**

```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" \
| sudo tee /etc/apt/sources.list.d/hashicorp.list
```

* Adds the official HashiCorp repository for your Ubuntu version (`noble`) and architecture (`arm64`).
* Repository is signed with the key previously added.

---

## **5. Update package lists**

```bash
sudo apt update
```

* Pulls package information from the newly added HashiCorp repository.
* Confirms availability of `terraform`.

---

## **6. Install Terraform**

```bash
sudo apt-get install terraform
```

* Installs Terraform from HashiCorp’s official repository.

---

✅ **Outcome:**

* HashiCorp GPG key added and verified.
* HashiCorp repository added.
* Terraform installed on your system.

---
