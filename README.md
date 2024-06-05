# Descripción
Plantilla para crear la infraestructura usando aws cloudformation de un cluster de ECS que ejecuta una Task usando un cron de EventBridge

<img width="600px" src='https://github.com/CrissAlvarezH/aws-ecs-iac-template/blob/main/infra-diagram.png'/>

# Variables de entorno
Encontrarás un archivo `.env.example` con el contenido mostrado a continuación, debes copiarlo y pegarlo en un archivo `.env` y 
establecer los valores que te interesen.
```
PROJECT_NAME="ecs-example"
CRON_EXECUTION_EXPRESSION="*/5 * * * ? *"
SUBNET_IDS="subnet-111111111\,subnet-00000000\"
```
Cada vez que ejecutes alguno de los siguientes scripts estas variables serán leidas y usadas para su ejecución.

# Scripts
En el codigo puede encontrar un archivo `scripts.sh` el cual contiene el codigo necesario para deployar la infraestructura y manipularla

### Setup de la infraestructura

`sh scripts.sh setup-infra`

Este comando ejecuta un comando del `cli` de aws para crear el stack de cloudformation.

### Actualizar infraestructura

`sh scripts.sh update-infra`

En caso de que realice cambios en `cloudformation.yaml` para que estos se vean reflejados en el stack de aws puede utilizar este comando.

### Eliminar infraestructura

`sh scripts.sh delete-infra`

### Desplegar aplicación

`sh scripts.sh deploy`

Este comando realizará lo siguiente:
1. Contruye la imagen docker usando el `Dockerfile` de la raiz del proyecto
2. Se loguea en el servidor de ECR de aws
3. Aplica tags a la imagen usando el ultimo commit hash y 'latest'
4. Push la imagen al repositorio de ECR

### Construir docker image

`sh scripts.sh build`

Crea la imagen docker usando el `Dockerfile` de la raiz del proyecto

### Obtener repository uri

`sh scripts.sh repo-uri`

Obtiene la uri del repositorio de ECR que fue creado usando el comando **setup-infra**

### Obtener default subnets

`sh scripts.sh default-subnets`

Obtiene las subnets de la vpc por defecto de aws en el formato apropiado para establecer en las variables de entorno en el archivo `.env`
