data "cloudinit_config" "root-ca-trust-config" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content      = <<-EOF
      #cloud-config
      ca-certs:
        trusted:
          - |
            -----BEGIN CERTIFICATE-----
            MIIDBDCCAeygAwIBAgIUIfgV/b7LgG4Irp0lgQoj5pDiXXAwDQYJKoZIhvcNAQEL
            BQAwGzEZMBcGA1UEAwwQbW9ua2V5LWF1dGhvcml0eTAeFw0yMzA5MjQwOTEyMjha
            Fw0yNDA5MjMwOTEyMjhaMBsxGTAXBgNVBAMMEG1vbmtleS1hdXRob3JpdHkwggEi
            MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDhc5nngkp6ZAHiq7kOX2bDQb3Z
            dbqytKeKY9vdvNn/RQuPrF4ARycDQeKQq3aroT9CTGaiWRGm1Ujah2UgbvDb1VkL
            V8+lGTxonkVrinoA9SruYoVrc/eI0egY9fYV18zRjFD2bT8EZecm/wLBbXcEXKfe
            X2ABSBP7aT+ShByxjTEA94XjTkbTXmoNIc2yPaSxeHeqf127Al0aODoFd3Kkh0VN
            zYnkuVUJip8HfpkSt3CqSM9c2UyA0QIM2DV21ITdjquE0oU1Lf7iLX+5yVSmwXxQ
            o2KyHrCFNQZz4fNPhT1zdR4XFTlkucKBrnyHEVhZKozMxqH7qxsCspARaM77AgMB
            AAGjQDA+MA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgKkMBsGA1UdEQQU
            MBKCEG1vbmtleS1hdXRob3JpdHkwDQYJKoZIhvcNAQELBQADggEBAFI6XkOk5rN9
            byVt35vBDL2WgLL9yfn0KtIAuuGpto+TfH2bwoYlcB9DxEaebQveaBHTcmQfzme4
            zyX13Pj+jLOzvnAZm6mjyWqtWdWkEA4wrjBjZCIznTmw6ehHB8qG+RuZLdiuY4jz
            74uXwAurqgEjwVUVkSFLBfceEcCFL9lrXbcFBdq0eFjpbkXEFbk7Jyu8b4UnExDN
            8pIKdX9h9zRxHpIzoMzfuPImdr/Er1iBg//XXvSErbXIWqG0fJwSr7rckvcbOQ2J
            vqz3GAqsYzw8BWes++ymSpJEaNwAi1JfLKdpJgmrpK7TbRtRGCORzKMhtBh12laP
            YS21qZJjhbc=
            -----END CERTIFICATE-----
    EOF
  }
}

resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  vpc      = true

  depends_on = [aws_vpc.eksd_vpc, aws_subnet.eksd_public, aws_subnet.eksd_private]
}

resource "aws_instance" "bastion" {
  ami                    = var.bastion_ami
  instance_type          = var.bastion_instance_type
  key_name               = var.bastion_keyname
  subnet_id              = aws_subnet.eksd_public.id
  vpc_security_group_ids = [aws_security_group.eksd_k8s.id]
  user_data              = data.cloudinit_config.root-ca-trust-config.rendered

  tags = {
    Name = "bastion"
  }
  depends_on = [aws_route.igw, aws_route_table_association.public_to_public]
}
