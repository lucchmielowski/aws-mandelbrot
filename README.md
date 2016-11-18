# aws-mandelbrot

## Philosophie

Le but était de créer une application en Go qui dessine un fractal de mandelbrot, puis qui est provisionnée à Amazon Web Services en utilsant une pipeline de déploiement continu.


## Explication du projet

Le code de ce projet est écrit en Go et permet de créer un fractal de mandelbrot. Il le tout étant déployé sur AWS (eu-west-1) en utilisant:
* **des EC2s t2.micro** pour faire tourner le serveur Go
* **un bucket S3** qui héberge les différentes révisions du code de l'application
* un **Elastic Load Balancer** pour rediriger les requêtes sur les EC2s
* **L' autoscaling d'AWS** pour pouvoir supporter la montée en charge
* **AWS CodeDeploy** pour diffuser le code sur l'ensemble des EC2s

## Infrastructure as Code

Le déploiement de l'infrastructure pouvant être une tache fastidieuse et longue si elle est faite manuellement, j'ai utilisé [Terraform](https://www.terraform.io/) (voir le dossier *conf* pour les fichiers de configuration.)

Pour déployer la structure de l'application il suffit donc d'aller dans le dossier *conf* et d'exécuter la commande: `terraform apply -var 'key_name=KEY_PAIR_NAME'`

Il est aussi possible de détruire tout ce qui a été généré par Terraform en exécutant `terraform apply -var 'key_name=KEY_PAIR_NAME'`

## Continuous deployment
Une autre problématique de ce projet était de mettre en place du **déploiement continu** pour le provisionnement de nos machines.

La mise en place d'un Jenkins aurait été trop longue, j'ai donc opté pour [Codeship](https://codeship.com/) qui nous permet de créer un pipeline de déploiement.

Quand on push du code sur Github, Codeship effectue les actions suivantes:
1. Build notre application

2. Effectuer les tests

3. Si tout les tests sont passés, déployer le build au format zip

Une fois le build terminé, Codeship envoit le build à [AWS Codedeploy](https://aws.amazon.com/fr/codedeploy/), et ce dernier se charge alors de **déployer le nouveau code sur toutes les instances ec2 associées à notre Scalling Group** (pour plus d'informations sur la procédure de déploiement voir le fichier *appspec.yml*)

#### Résumé du pipeline de déploiement:
***[local, git push to github]***------> ***[codeship build]***------>***[codeship test]*** ----(fails?)--->***[codeship deploy]***------>***[AWS Codedeploy provisioning to auto-scaling group instances]***

## ELB + autoscalling

Pour pouvoir supporter des montées en charges brutales, on utilise les *policies* suivantes:
* Crée 50% d'instances en plus si le l'utilisation de CPU moyenne est > 70% pour 2 périodes consécutives de 1 minute et attends 300s avant d'autoriser le prochain scaling.

* Supprime 1 instance si le l'utilisation de CPU moyenne est < 40% pour 2 périodes consécutives de 1 minute et attends 300s avant d'autoriser le prochain scaling.

* Crée 50% d'instances en plus si la latence moyenne sur le load balancer est > 3000ms pendant 1 minute et attends 300s avant d'autoriser le prochain scaling.

Chaque nouvelle machine crée lors de la procédure de scaling est provisionnée automatiquement en utilisant CodeDeploy

## Hubot
Afin de pouvoir administrer mes déploiements depuis Slack, j'ai crée un bot pour Slack en utilisant [Hubot](https://hubot.github.com/), il est disponible ici: [Mandelbot](https://github.com/lucchmielowski/mandelbot)
