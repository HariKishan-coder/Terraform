              #!/bin/bash
              yum update -y
              yum install -y httpd.x86_64
              systemctl start httpd.service
              systemctl enable httpd.service
              echo "DB address: ${db_address}" > /var/www/html/index.html
              echo "DB port: ${db_port}" > /var/www/html/index.html
              EOF