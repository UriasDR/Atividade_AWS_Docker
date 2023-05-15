# Tutorial para criação de aplicação na AWS com Terraform
Este tutorial irá guiá-lo passo a passo na criação de uma aplicação na AWS utilizando o Terraform. A aplicação será composta por vários recursos, incluindo um Internet Gateway, NAT Gateway, Amazon Elastic File System (EFS), Amazon Relational Database Service (RDS), Auto Scaling, Application Load Balancer (ALB) e um container com Wordpress na porta 80.

# Pré-requisitos
Antes de começar, você precisará ter uma conta na AWS e instalar o Terraform em seu computador. Certifique-se de ter as credenciais da AWS configuradas em sua máquina para poder provisionar os recursos, é interessante possuir o git na máquina para facilitar o provisionamento da aplicação. 
  
Você pode configurar suas credenciais com o comando:
  ```terraform
   export AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY
   export AWS_SECRET_ACCESS_KEY=YOUR_SECRET_ACCESS_KEY
   ```

## Iniciando o provisionamento pelo terraform 
Para iniciar o provisionamento basta utilizar três comandos em sequência no diretório **terraform-provisioning**.

O primeiro comando a ser realizado é:
```terraform
terraform init
``` 
Que irá inicializar um diretório de trabalho do Terraform, incluindo a instalação de plugins e a configuração de backends de estado.

### A saída esperada para o comando **terraform init**: 

![output terraform init](https://github.com/MarcoBosc/akigaraiow/assets/105826129/0dc12e2f-16ea-4a16-b071-21d3b119e3d9)

Após inicializar o ambiente de trabalho do terraform, utilize o comando: 
```terraform
terraform plan -out=plan.out
``` 
Que será usado para criar um arquivo de plano de execução da infraestrutura.


### A saída esperada para o comando **terraform plan -out=plan.out**:

![output terraform plan -out=plan.out](https://github.com/MarcoBosc/akigaraiow/assets/105826129/bafa33bb-3f30-46d2-9ca3-e5d31aa689b8)


O terceiro comando a ser executado é o comando:
```terraform
terraform apply plan.out
```
O comando irá aplicar a infraestrutura projetada nos arquivos do Terraform dentro ambiente da aws. Utilizando como base os arquivos do plano de execução **plan.out** criado anteriormente.

Após isso iniciará o processo de provisionamento do ambiente com base na infraestrutura presente nos arquivos terraform. O processo leva cerca de 5 minutos para a completa execução.

## O processo de execução irá seguir as seguintes etapas:

### 1. Criar a VPC.
 O primeiro recuso a ser provisionado será a VPC. Ela será usada para criar uma rede virtual personalizada que pode ser conectada com outros recursos da AWS, como instâncias EC2, RDS, EFS, ELB, entre outros. Nessa fase também serão criadas as subnets públicas e privadas necessárias para a aplicação.

### 2. Provisionar o Internet Gateway.
Após isso, será provisionado o Internet Gateway. Que será usado para permitir que nossa aplicação se comunique com a Internet.

### 3. Provisionar o NAT Gateway.
Em seguida, será criado um NAT Gateway. Ele será usado para permitir que nossos recursos privados na VPC acessem a Internet por meio de uma subnet pública.

### 4. Provisionar o EFS.
O próximo recurso criado é o EFS. Ele será usado para armazenar os arquivos de criação e volumes do **Wordpress** da nossa aplicação. Bem como será o responsável por compartilhar os arquivos entre todas as instancias.

### 5. Provisionar o RDS.
Agora, será provisionado um Amazon RDS com mysql para armazenar os dados do container **Wordpress** na nossa aplicação.

### 6. Provisionar o Auto Scaling.
Agora, será criado o Auto Scaling. Ele será usado para aumentar ou diminuir automaticamente o número de instâncias da nossa aplicação com base na demanda. Ele também será o responsável por carregar dentro do launch template o **user data** de nossas máquinas virtuais que irão executar os containers.
```bash
#!/bin/bash
sudo yum update -y
sudo yum upgrade -y
sudo yum install -y git
sudo yum -y install docker
sudo service docker start
sudo usermod -a -G docker ec2-user
sudo systemctl enable docker
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo yum install amazon-efs-utils -y
sudo systemctl start efs && sudo systemctl enable efs
sudo mkdir /efs
cd /
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_mount_target.efs_mount_target_a.ip_address}:/ /efs
sudo echo ${aws_efs_mount_target.efs_mount_target_a.ip_address}:/ /efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0 | sudo tee -a /etc/fstab
git clone https://github.com/MarcoBosc/atividade-aws-docker.git
mv atividade-aws-docker /efs
cd /efs
mkdir db_data && mkdir wp_data
cd atividade-aws-docker
docker-compose up 
```
### Nesse **user data** serão executados aluguns comandos importantes de serem destacados:
```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```
Comandos responsáveis pela instalação do **docker-compose** que será utilizado para a criação dos containeres **Wordpress** e **Mysql**.

```bash
sudo mkdir /efs
cd /
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_mount_target.efs_mount_target_a.ip_address}:/ /efs
sudo echo ${aws_efs_mount_target.efs_mount_target_a.ip_address}:/ /efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0 | sudo tee -a /etc/fstab
```
Comandos responsáveis pela montagem do Amazon Elastic File System (EFS), que irá armazenar o arquivo **compose.yaml**.
```bash
git clone https://github.com/MarcoBosc/atividade-aws-docker.git
mv atividade-aws-docker /efs
cd /efs
mkdir db_data && mkdir wp_data
cd atividade-aws-docker
```
Aqui será baixado do repositório os arquivos necessários para execução dos containers docker, onde os mesmos serão movidos para dentro do ponto de montagem do efs, então serão criados os diretórios que irão ser utilizados de volume para os containeres.

```bash
docker-compose up 
```
Por fim será inicializado os containeres que irão virtualizar a aplicação **Wordpress** e **Mysql**.


### 7. Provisionar o ALB.
Por último, será criado o Application Load Balancer (ALB). Ele será usado para distribuir o tráfego entre as instâncias da nossa aplicação.

### A saída esperada para o comando **terraform apply plan.out**:
![output terraform apply plan.out](https://github.com/MarcoBosc/akigaraiow/assets/105826129/2d939a0f-2263-4288-bd04-ef4847570e57)

## Conseguindo o DNS do load balancer para o acesso:
Após o final do provisionamento da infraestrutura na aws, será possível conseguir o endereço dns do load balancer da aplicação construida anteriormente.

Com o aws cli configurado com seus dados e para a região us-east-1, basta executar o comando abaixo para conseguir o endereço DNS para acessar sua aplicação já funcional. (Você pode saber mais sobre a configuração do aws cli clicando [aqui](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure..html)).

```bash
aws elbv2 describe-load-balancers --query 'LoadBalancers[*].DNSName' --output text
```
![image](https://github.com/MarcoBosc/akigaraiow/assets/105826129/26694534-b917-4637-a517-609dee392261)

Após isso basta colar o DNS no seu navegador para acessar a aplicação:

![image](https://github.com/MarcoBosc/akigaraiow/assets/105826129/4b1e3ec5-2455-4040-be26-a10069ce1229)


## IMPORTANTE
Caso seja necessário realizar alguma alteração na aplicação, segue outros comandos terraform úteis para suas modificações.

O comando ```terraform fmt``` é capaz de formatar todos seus arquivos .tf para prevenir erros de identação, a saída do comando retorna todos os arquivos em que alguma alteração na identação foi necessária. Caso seja necessária alguma formatação, saída do comando **terraform fmt** será a seguinte:

![output docker fmt](https://github.com/MarcoBosc/PBProjetoAwsDocker/assets/105826129/7e070e58-7e09-49fd-9d97-5a6f174677ff)

O comando ```terraform validate``` é responsável pela validação dos scripts .tf presentes no diretório, caso seja encontrada alguma incoerência ele irá retornar o erro, caso esteja tudo certo sua saída será:
![output validate](https://github.com/MarcoBosc/akigaraiow/assets/105826129/236d6d47-df3a-4c3c-93a2-1b295de12ea6)

Você pode ter acesso a toda a documentação do terraform clicando [aqui](https://developer.hashicorp.com/terraform/docs).

# Conclusão
Com o Terraform, você pode facilmente gerenciar e implantar seus recursos na AWS. Nesse caso fomos capazes de provisionar com facilidade uma infraestrutura relativamente complexa em menos de cinco minutos e com a execução de apenas alguns comandos. Este tutorial é apenas uma introdução aos recursos mais comuns. Você pode explorar mais opções e personalizar sua configuração para atender às suas necessidades específicas, implementando processos ainda mais complexos de maneira muito mais rápida e eficaz. 
