# Tutorial para criação de aplicação na AWS com Terraform
Este tutorial irá guiá-lo passo a passo na criação de uma aplicação na AWS utilizando o Terraform. A aplicação será composta por vários recursos, incluindo um Internet Gateway, NAT Gateway, Amazon Elastic File System (EFS), Amazon Relational Database Service (RDS), Auto Scaling, Application Load Balancer (ALB) e um container com Wordpress na porta 80.

### O que é terraform:
Terraform é uma ferramenta de código aberto usada para automatizar a criação e configuração de infraestrutura de TI. Com ele, é possível escrever código para definir recursos, como servidores, bancos de dados e redes, e o Terraform se encarrega de criar esses recursos de maneira automatizada. Isso permite que as equipes de TI gerenciem a infraestrutura de forma mais eficiente e consistente, reduzindo erros e aumentando a produtividade.


# Pré-requisitos
Antes de começar, você precisará ter uma conta na AWS e instalar o Terraform em seu computador. Certifique-se de ter as credenciais da AWS configuradas em sua máquina para poder provisionar os recursos, é interessante possuir o git na máquina para facilitar o provisionamento da aplicação. 
  
Você pode configurar suas credenciais com o comando:
  terraform
  ```
   export AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY
   export AWS_SECRET_ACCESS_KEY=YOUR_SECRET_ACCESS_KEY
  ```
   
Você também precisa ter o aws cli configurado com suas credenciais de acesso e para a região us-east-1(Você pode saber mais sobre a configuração do aws cli clicando [aqui](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure..html)).

É imoportante criar um par de chaves na aws para iniciar o provisionamento e ter acesso as instâncias caso necessário. Para criar um par de chaves na AWS pelo CLI, você pode usar o seguinte comando:
`AWS CLI`
```
aws ec2 create-key-pair --key-name my-key-pair --query 'KeyMaterial' --output text > my-key-pair.pem
```

Nesse comando, substitua my-key-pair pelo nome que deseja dar ao par de chaves. O comando irá gerar um arquivo my-key-pair.pem que contém a chave privada. É interessante deixar o mesmo nome de chave que está no código _autoscailing.tf_, caso deseje criar sua chave com outro nome, é necessário alterar o nome da chave no script, substituindo o ```key_name = "KeyPair"``` para ```key_name = "Nome_da_sua_chave"```.


Se preferir, você pode gerar o par de chaves na interface da AWS também. Para isso, acesse o serviço EC2, vá em "Key Pairs" e clique em "Create Key Pair". Escolha um nome para o par de chaves e faça o download do arquivo .pem contendo a chave privada.
### 1 -
![image](https://github.com/MarcoBosc/atividade-aws-docker/assets/105826129/e27b9c95-61d9-4e9d-b61d-335146a57464)

### 2 -
![image](https://github.com/MarcoBosc/atividade-aws-docker/assets/105826129/01fe7dc9-55d9-4496-a99f-ff5cdef2e141)

Lembre-se de baixar a chave e guardá-la com segurança pois ela apenas pode ser visualizada uma vez pelo console. Caso perca a chave você **perderá o acesso a todas as máquinas virtuais** criadas com a chave em questão.

## Iniciando o provisionamento pelo terraform 
Para iniciar o provisionamento basta utilizar três comandos em sequência no diretório **terraform-provisioning**.

O primeiro comando a ser realizado é:
```
terraform init
```
 
Que irá inicializar um diretório de trabalho do Terraform, incluindo a instalação de plugins e a configuração de backends de estado.

### A saída esperada para o comando *terraform init*: 

![output terraform init](https://github.com/MarcoBosc/akigaraiow/assets/105826129/0dc12e2f-16ea-4a16-b071-21d3b119e3d9)

Após inicializar o ambiente de trabalho do terraform, utilize o comando: 
```
terraform plan -out=plan.out
```
 
Que será usado para criar um arquivo de plano de execução da infraestrutura.


### A saída esperada para o comando *terraform plan -out=plan.out*:

![output terraform plan -out=plan.out](https://github.com/MarcoBosc/akigaraiow/assets/105826129/bafa33bb-3f30-46d2-9ca3-e5d31aa689b8)


O terceiro comando a ser executado é o comando:
```
terraform apply plan.out
```

O comando irá aplicar a infraestrutura projetada nos arquivos do Terraform dentro ambiente da aws. Utilizando como base os arquivos do plano de execução *plan.out* criado anteriormente.

Após isso iniciará o processo de provisionamento do ambiente com base na infraestrutura presente nos arquivos terraform. O processo leva cerca de 5 minutos para a completa execução.

## O processo de execução irá seguir as seguintes etapas:

### 1. Criar a VPC.
 O primeiro recurso a ser provisionado será a VPC. Ela será usada para criar uma rede virtual personalizada que pode ser conectada com outros recursos da AWS, como instâncias EC2, RDS, EFS, ELB, entre outros. Nessa fase também serão criadas as subnets públicas e privadas necessárias para a aplicação. O arquivo responsável pela criação da VPC e sub-redes públicas e privadas é o _network.tf_.

### 2. Provisionar o Internet Gateway.
Após isso, será provisionado o Internet Gateway. Que será usado para permitir que nossa aplicação se comunique com a Internet. Ainda com responsabilidade do arquivo _network.tf_.

### 3. Provisionar o NAT Gateway.
Em seguida, será criado um NAT Gateway. Ele será usado para permitir que nossos recursos privados na VPC acessem a Internet por meio de uma subnet pública. O NAT Gateway será privisionado pelo arquivo _private-network.tf_.

### 4. Criar os Security Groups
O arquivo _security-groups_ irá criar os security groups e suas regras. Servirão como recursos de segurança na nuvem usados para controlar o tráfego de entrada e saída das instâncias ou recursos da nuvem. Eles funcionam como uma espécie de firewall virtual que permite especificar quais protocolos, portas e endereços IP podem acessar um determinado recurso na nuvem.

### 5. Provisionar o EFS.
O próximo recurso criado é o EFS. Ele será usado para armazenar os arquivos de criação e volumes do **Wordpress** da nossa aplicação. Bem como será o responsável por compartilhar os arquivos entre todas as instancias. O arquivo responsável pela criação do efs e seu security group é o _EFS.tf_.

### 6. Provisionar o RDS.
Agora, será provisionado um Amazon RDS com mysql para armazenar os dados do container **Wordpress** na nossa aplicação. O arquivo que irá criar o RDS e seu grupo de subredes é o _mysql-rds.tf_.

### 7. Provisionar o Auto Scaling.
Após a finalização do recurso RDS e obtenção do endpoint do mesmo, será criado o Auto Scaling a partir do arquivo _autoscaling.tf_. Ele será usado para aumentar ou diminuir automaticamente o número de instâncias da nossa aplicação com base na demanda. Ele também será o responsável por carregar dentro do launch template o **user data** de nossas máquinas virtuais que irão executar os containers.

### Nesse *user data* serão executados aluguns comandos importantes de serem destacados:

```
#!/bin/bash
              yum update -y
              yum upgrade -y
              yum install docker -y
              usermod -a -G docker ec2-user
              systemctl start docker && systemctl enable docker
              curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              yum install amazon-efs-utils -y
              systemctl start efs && systemctl enable efs
              mkdir /efs
              cd /
              mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_mount_target.efs_mount_target_a.ip_address}:/ /efs
              echo ${aws_efs_mount_target.efs_mount_target_a.ip_address}:/ /efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0 | sudo tee -a /etc/fstab
              cd /efs
              mkdir db_data && mkdir wp_data
              echo '
version: "3"
services:
  wordpress:
    image: wordpress:latest
    ports:
      - 80:80
    restart: always
    environment:
      - WORDPRESS_DB_HOST=${aws_db_instance.my_db_instance.endpoint}
      - WORDPRESS_DB_USER=admin
      - WORDPRESS_DB_PASSWORD=wordpress
      - WORDPRESS_DB_NAME=wordpress
    volumes:
      - /efs/wp_data:/var/www/html
  db:
    image: mysql:latest
    volumes:
      - /efs/db_data:/var/lib/mysql
    restart: always
    environment:
      - MYSQL_DATABASE=wordpress
      - MYSQL_USER=admin
      - MYSQL_PASSWORD=wordpress
      - MYSQL_ROOT_PASSWORD=wordpress
      - MYSQL_HOST=${aws_db_instance.my_db_instance.endpoint}
      - MYSQL_PORT=3306
volumes:
  wp_data:
  db_data:' > compose.yaml
              docker-compose up -d 
```

Comandos responsáveis pela instalação do *docker-compose* que será utilizado para a criação dos containeres *Wordpress* e *Mysql*.

```
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

Comandos responsáveis pela montagem do Amazon Elastic File System (EFS), que irá armazenar o arquivo *compose.yaml*.

```
sudo mkdir /efs
cd /
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_mount_target.efs_mount_target_a.ip_address}:/ /efs
sudo echo ${aws_efs_mount_target.efs_mount_target_a.ip_address}:/ /efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0 | sudo tee -a /etc/fstab
```

Aqui será adicionado ao diretório os arquivos necessários para execução dos containers docker(docker-compose.yaml), onde os mesmos serão movidos para dentro do ponto de montagem do efs para dentro de um arquivo chamado compose.yaml.

```
echo '
version: "3"
services:
  wordpress:
    image: wordpress:latest
    ports:
      - 80:80
    restart: always
    environment:
      - WORDPRESS_DB_HOST=${aws_db_instance.my_db_instance.endpoint}
      - WORDPRESS_DB_USER=admin
      - WORDPRESS_DB_PASSWORD=wordpress
      - WORDPRESS_DB_NAME=wordpress
    volumes:
      - /efs/wp_data:/var/www/html
  db:
    image: mysql:latest
    volumes:
      - /efs/db_data:/var/lib/mysql
    restart: always
    environment:
      - MYSQL_DATABASE=wordpress
      - MYSQL_USER=admin
      - MYSQL_PASSWORD=wordpress
      - MYSQL_ROOT_PASSWORD=wordpress
      - MYSQL_HOST=${aws_db_instance.my_db_instance.endpoint}
      - MYSQL_PORT=3306
volumes:
  wp_data:
  db_data:' > compose.yaml
  ```
  
Por fim serão inicializados os containeres que irão virtualizar as aplicações *Wordpress* e *Mysql*.
```
docker-compose up 
```

### 8. Provisionar o ALB.
Por último, será criado o Application Load Balancer (ALB) e target groups pelo arquivo _ALB.tf_. Ele será usado para distribuir o tráfego entre as instâncias da nossa aplicação.

### A saída esperada para o comando **terraform apply plan.out**:
O terraform irá mostrar uma mensagem de sucesso da aplicação juntamente com a quantidade de itens provisionados. E logo abaixo os outputs configurados no terraform para mostrar as saídas necessárias.
![output terraform apply plan.out](https://github.com/MarcoBosc/akigaraiow/assets/105826129/2d939a0f-2263-4288-bd04-ef4847570e57)

## Conseguindo o DNS do load balancer para o acesso:
O DNS de acesso para as instâncias criadas será mostrado abaixo após a validação dos processos de criação, como no exemplo abaixo:
![image](https://github.com/MarcoBosc/atividade-aws-docker/assets/105826129/f1ae5b89-dbbe-4961-a954-1f10e8925824)

Caso perca o DNS após o final do provisionamento da infraestrutura na aws, será possível conseguir o endereço dns do load balancer da aplicação construida anteriormente através de um comando cli:
```
aws elbv2 describe-load-balancers --query 'LoadBalancers[*].DNSName' --output text
```

![image](https://github.com/MarcoBosc/akigaraiow/assets/105826129/26694534-b917-4637-a517-609dee392261)

Após isto basta colar o DNS no seu navegador para acessar a aplicação:

![image](https://github.com/MarcoBosc/akigaraiow/assets/105826129/4b1e3ec5-2455-4040-be26-a10069ce1229)

### Observações:
Em caso do erro 502 - Bad Gateway, pode ser necessário esperar alguns minutos até que as instâncias estejam 100% online para que o serviço funcione corretamente e não gere nenhum tipo erro.

## IMPORTANTE
Caso seja necessário realizar alguma alteração na aplicação, segue outros comandos terraform úteis para suas modificações.

O comando ```terraform fmt``` é capaz de formatar todos seus arquivos .tf para prevenir erros de identação, a saída do comando retorna todos os arquivos em que alguma alteração na identação foi necessária. Caso seja necessária alguma formatação, saída do comando **terraform fmt** será a seguinte:

![output docker fmt](https://github.com/MarcoBosc/PBProjetoAwsDocker/assets/105826129/7e070e58-7e09-49fd-9d97-5a6f174677ff)

O comando ```terraform validate``` é responsável pela validação dos scripts .tf presentes no diretório, caso seja encontrada alguma incoerência ele irá retornar o erro, caso esteja tudo certo sua saída será:
![output validate](https://github.com/MarcoBosc/akigaraiow/assets/105826129/236d6d47-df3a-4c3c-93a2-1b295de12ea6)

Você pode ter acesso a toda a documentação do terraform clicando [aqui](https://developer.hashicorp.com/terraform/docs).

# Conclusão
Em resumo, Terraform é uma ferramenta de código aberto que ajuda a automatizar a criação e configuração de infraestrutura de TI. Neste tutorial, o Terraform é usado para criar uma aplicação na AWS composta por vários recursos, incluindo um Internet Gateway, NAT Gateway, Amazon Elastic File System (EFS), Amazon Relational Database Service (RDS), Auto Scaling, Application Load Balancer (ALB) e um container com Wordpress na porta 80. Antes de começar, é necessário ter uma conta na AWS e instalar o Terraform em seu computador. Depois de baixar a chave privada e seguir algumas etapas, você pode executar o processo de provisionamento com base na infraestrutura presente nos arquivos terraform e criar sua aplicação na AWS.

