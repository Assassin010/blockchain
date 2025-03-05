resource "aws_vpc" "blockchain_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "blockchain-vpc"
  }
}

resource "aws_subnet" "blockchain_subnet" {
  vpc_id            = aws_vpc.blockchain_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"
  tags = {
    Name = "blockchain-subnet"
  }
}

resource "aws_internet_gateway" "blockchain_igw" {
  vpc_id = aws_vpc.blockchain_vpc.id
  tags = {
    Name = "blockchain-igw"
  }
}


resource "aws_route_table" "blockchain_rt" {
  vpc_id = aws_vpc.blockchain_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.blockchain_igw.id
  }
  tags = {
    Name = "blockchain-route-table"
  }
}

resource "aws_route_table_association" "blockchain_rta" {
  subnet_id      = aws_subnet.blockchain_subnet.id
  route_table_id = aws_route_table.blockchain_rt.id
}

resource "aws_security_group" "blockchain_sg" {
  name   = "blockchain-sg"
  vpc_id = aws_vpc.blockchain_vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }
}



resource "aws_iam_role" "ecs_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "ecs_execution_role_policy" {
  name       = "ecs_execution_role_policy"
  roles      = [aws_iam_role.ecs_execution_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "ecs_task_role_policy" {
  name       = "ecs_task_role_policy"
  roles      = [aws_iam_role.ecs_task_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_ecs_cluster" "blockchain_cluster" {
  name = "blockchain-cluster"
}

resource "aws_ecs_task_definition" "blockchain_task" {
  family                   = "blockchain-task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"  # Increased CPU from 256 to 512
  memory                   = "1024" # Increased Memory from 512 to 1024
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "blockchain-client"
      image     = "${aws_ecr_repository.blockchain_ecr.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region        = "eu-west-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
  depends_on = [
    aws_iam_role.ecs_execution_role,
    aws_iam_role.ecs_task_role,
    aws_ecr_repository.blockchain_ecr,
    aws_cloudwatch_log_group.ecs_logs

  ]
}


resource "aws_ecs_service" "blockchain_service" {
  name                   = "blockchain-service"
  cluster                = aws_ecs_cluster.blockchain_cluster.id
  task_definition        = aws_ecs_task_definition.blockchain_task.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  force_new_deployment   = true
  enable_execute_command = true
  network_configuration {
    subnets          = [aws_subnet.blockchain_subnet.id]
    security_groups  = [aws_security_group.blockchain_sg.id]
    assign_public_ip = true
  }
  depends_on = [aws_vpc.blockchain_vpc]
}

resource "aws_ecr_repository" "blockchain_ecr" {
  name = "blockchain-client"
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/blockchain-service"
  retention_in_days = 7
}
