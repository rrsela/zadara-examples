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
  user_data              = <<-EOF
                    #!/bin/bash
                    set -e
                    cat ${file(var.root_ca_cert_path)} > /usr/local/share/ca-certificates/root_ca.crt
                    update-ca-certificates
                  EOF
  tags = {
    Name = "bastion"
  }
  depends_on = [aws_route.igw, aws_route_table_association.public_to_public]
}
