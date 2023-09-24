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
            MIIDBDCCAeygAwIBAgIUNKj/Ev9FRHflP96rk9e0YVTs4i0wDQYJKoZIhvcNAQEL
            BQAwGzEZMBcGA1UEAwwQbW9ua2V5LWF1dGhvcml0eTAeFw0yMzA5MjQxMDMwNDFa
            Fw0yNDA5MjMxMDMwNDFaMBsxGTAXBgNVBAMMEG1vbmtleS1hdXRob3JpdHkwggEi
            MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC6mGhQFSkB9PEXwo5YG+aPtXBY
            16VZkPt5kltxxE0Y2NbOhrrbyqS1YV7iNBh/3Qqz2ZLXo6teB7CGl/Wqz3JebB/4
            Yg2f0kvud3VZlDHWtlBkumrXs3bGpisEI6oVR+ck8qqe3RAjmAIruRuj/a5vxp/V
            fyrRx/+9Fx7nOaQfg9lVllg+Yvf3ZuN4a8fwkJLpiC1XB89kKfggrgVDGq7Y3uaa
            rI+roVZkfNNTIANVVUDmyvdTk4TQ3Vv3EAA+cqnyzBrgUQFlEKxahwQhnLUZsWpw
            gbhq+Yzzk61OA8KtqRQA3Ym97ZsEiEaYzU4PbxbMIZy6H4XdhCJtlN6y+1ZFAgMB
            AAGjQDA+MA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgKkMBsGA1UdEQQU
            MBKCEG1vbmtleS1hdXRob3JpdHkwDQYJKoZIhvcNAQELBQADggEBAJXkNDznnMO/
            QJGy5LHUM/yXfmWy13RdXD2BtN8whBedNwV281P79BOUNywDW1IqHooBbpuUaQG2
            2WrSOjU7hNdWbKGPbtdZDWsNyUT2i11O5iA3WWJfsGftkSQbCnwj61yHFPewLap7
            oBg0T8GR3Mk/CpuGwciETx/gKYbp35xtunzwXPL8Km7rwitXoTu8aFG7/sTImN+4
            +OCkB2zJVXvhHyZjsMdiv6TqmGKiQDrrGMw0U96dksPiqo5Iiyxz//TO/WYVKW7r
            7w6zTf/Bhglqr0Fa8o8Xvt9RGhruA6tILCFa9pcRkH7AG0HcP0NuGCggk+H4juIt
            5wKsCZEeL+A=
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
