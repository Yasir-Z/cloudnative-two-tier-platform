resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

#======================Subnets AZ_A===================

resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.AZ_A

  tags = {
    Name                                = "public-subnet-1"
    "kubernetes.io/role/elb"            = "1"
    "kubernetes.io/cluster/eks_cluster" = "shared"
  }
}

resource "aws_subnet" "eks_private_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = var.AZ_A

  tags = {
    Name                                = "eks-private-subnet"
    "kubernetes.io/role/internal-elb"   = "1"
    "kubernetes.io/cluster/eks_cluster" = "shared"
  }
}

resource "aws_subnet" "rds_private_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = var.AZ_A

  tags = {
    Name = "rds-private-subnet-1"
  }
}

#=======================Subnet AZ_B=======================

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.AZ_B

  tags = {
    Name                                = "public-subnet-2"
    "kubernetes.io/role/elb"            = "1"
    "kubernetes.io/cluster/eks_cluster" = "shared"
  }
}

resource "aws_subnet" "eks_private_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = var.AZ_B

  tags = {
    Name = "eks-private-subnet-2"
  }
}

resource "aws_subnet" "rds_private_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = var.AZ_B

  tags = {
    Name = "rds-private-subnet-2"
  }
}

#===================Internet Gateway==================

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "inter-gateway"
  }
}

#================Elastic IP====================

resource "aws_eip" "nat_eip_1" {

  domain = "vpc"
}

resource "aws_eip" "nat_eip_2" {

  domain = "vpc"
}

#================NAT gateway===================

resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.nat_eip_1.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "NAT_1"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.nat_eip_2.id
  subnet_id     = aws_subnet.public_subnet_2.id

  tags = {
    Name = "NAT-Gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

#================Route Table====================

resource "aws_route_table" "public_rt_1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt-1"
  }
}

resource "aws_route_table" "public_rt_2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt-2"
  }
}

resource "aws_route_table" "eks_rt_1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1.id
  }

  tags = {
    Name = "eks-rt-1"
  }
}

resource "aws_route_table" "eks_rt_2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_2.id
  }

  tags = {
    Name = "eks-rt-2"
  }
}

resource "aws_route_table" "rds_rt_1" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "rds-rt-1"
  }
}

resource "aws_route_table" "rds_rt_2" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "rds-rt-2"
  }
}

#============Route Table Associations================

resource "aws_route_table_association" "public_rta_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt_1.id
}

resource "aws_route_table_association" "public_rta_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt_2.id
}

resource "aws_route_table_association" "eks_rta_1" {
  subnet_id      = aws_subnet.eks_private_subnet_1.id
  route_table_id = aws_route_table.eks_rt_1.id
}

resource "aws_route_table_association" "eks_rta_2" {
  subnet_id      = aws_subnet.eks_private_subnet_2.id
  route_table_id = aws_route_table.eks_rt_2.id
}

resource "aws_route_table_association" "rds_rta_1" {
  subnet_id      = aws_subnet.rds_private_subnet_1.id
  route_table_id = aws_route_table.rds_rt_1.id
}

resource "aws_route_table_association" "rds_rta_2" {
  subnet_id      = aws_subnet.rds_private_subnet_2.id
  route_table_id = aws_route_table.rds_rt_2.id
}

#===============Network ACL=========================

#======================= 1. Public NACL =======================
resource "aws_network_acl" "public_nacl" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  # Inbound HTTP & HTTPS from Anywhere
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Inbound Return Traffic (Ephemeral Ports)
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound to Anywhere
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "public-nacl"
  }
}

#======================= 2. EKS Private NACL =======================
resource "aws_network_acl" "eks_nacl" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.eks_private_subnet_1.id, aws_subnet.eks_private_subnet_2.id]

  # Allow Traffic ONLY from Public Subnet 1 & 2
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.1.0/24" # Public Subnet 1
    from_port  = 5000
    to_port    = 5000
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "10.0.2.0/24" # Public Subnet 2
    from_port  = 5000
    to_port    = 5000
  }

  # Allow Internal EKS Pod/Node Communication within EKS Subnets
  ingress {
    protocol   = "-1"
    rule_no    = 120
    action     = "allow"
    cidr_block = "10.0.11.0/24" # EKS Subnet 1
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 130
    action     = "allow"
    cidr_block = "10.0.12.0/24" # EKS Subnet 2
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 140
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 150
    action     = "allow"
    cidr_block = "10.0.22.0/24"
    from_port  = 1024
    to_port    = 65535
  }


  # Outbound for Updates & DB connection
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "eks-nacl"
  }
}

#======================= 3. RDS Private NACL =======================
resource "aws_network_acl" "rds_nacl" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.rds_private_subnet_1.id, aws_subnet.rds_private_subnet_2.id]

  # Allow MySQL/PostgreSQL Traffic ONLY from EKS Subnets
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.11.0/24"
    from_port  = 5432
    to_port    = 5432
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "10.0.12.0/24"
    from_port  = 5432
    to_port    = 5432
  }

  # Allow Ephemeral Ports for Return Traffic back to EKS
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.11.0/24"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "10.0.12.0/24"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "rds-nacl"
  }
}

#=================== ALB Security Group ==================

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow public HTTPS traffic to the ALB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "alb-security-group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

resource "aws_vpc_security_group_egress_rule" "alb_all_ipv4" {
  security_group_id = aws_security_group.alb_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}


#=================== EKS Security Group ==================

resource "aws_security_group" "eks_sg" {
  name        = "eks-sg"
  description = "Allow application traffic from the ALB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "eks-security-group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "eks_from_alb" {
  security_group_id = aws_security_group.eks_sg.id

  referenced_security_group_id = aws_security_group.alb_sg.id
  from_port                    = 5000
  ip_protocol                  = "tcp"
  to_port                      = 5000
}

resource "aws_vpc_security_group_egress_rule" "eks_all_ipv4" {
  security_group_id = aws_security_group.eks_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}


#=================== RDS Security Group ==================

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow PostgreSQL traffic only from EKS"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "rds-security-group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_eks" {
  security_group_id = aws_security_group.rds_sg.id

  referenced_security_group_id = aws_security_group.eks_sg.id
  from_port                    = 5432
  ip_protocol                  = "tcp"
  to_port                      = 5432
}

resource "aws_vpc_security_group_egress_rule" "rds_all_ipv4" {
  security_group_id = aws_security_group.rds_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

#========================RDS Subnet Group===================

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.rds_private_subnet_1.id, aws_subnet.rds_private_subnet_2.id]

  tags = {
    Name = "rds-subnet-group"
  }
}

#======================PostgreSQL Instance=================

resource "aws_db_instance" "postgresql" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "postgres"
  engine_version       = "15.7"
  instance_class       = "db.t3.micro"
  username             = "eks_postgresql"
  password             = var.db_password
  parameter_group_name = "default.postgres15"
  skip_final_snapshot  = true

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false

  tags = {
    Name = "eks-postgresql-db"
  }
}


