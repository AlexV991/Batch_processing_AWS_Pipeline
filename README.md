# AWS Batch-Pipeline erstellt mit Infrastructure as Code
<img width="1100" height= 420 alt="image" src="https://github.com/AlexV991/Batch_processing_AWS_Pipeline/assets/70948466/e527c5ba-aa43-4979-9109-5ee4a04760ac">

## Die Ausgangssituation 
Mit diesem Repository wird eine Batch-Pipeline umgesetzt, die als Backend für eine datenintensive Maschine Learning Applikation dient. Die Batch-Pipeline verfolgt das Ziel große Mengen an Daten aufzunehmen, zu speichern, zu prozessieren, zu aggregieren und anschließend für die Nutzung in einer Maschine Learning Applikation zu Verfügung zu stellen. Um die Daten möglichst effizient und ressourcenschonend zu verarbeiten und den Kriterien der Verlässlichkeit, Skalierbarkeit und Wartbarkeit Rechnung zu tragen, wird die Batch-Pipeline innerhalb der AWS-Umgebung umgesetzt. Die verwendeten Services werden mithilfe von Terraform als IaC zur Verfügung gestellt.

Konkret soll die Batch-Pipeline eine lokal gespeicherten CSV-Datei, die Daten zu Verbrechen in den USA seit 2020 enthält (ca. 800.000 Fälle), verarbeiten. Aus dieser CSV-Datei soll darauffolgend ein Datensatz erzeugt werden, der die kumulierte Anzahl der Verbrechen pro Tag seit 01/2020 enthält. Um einen besseren Überblick über die Daten zu erhalten, werden diese anschließend mithilfe eines Liniendiagramm grafisch dargestellt. 

## Die Batch-Pipeline
<img width="1916" alt="image" src="https://github.com/AlexV991/Batch_processing_AWS_Pipeline/assets/70948466/e708f330-28b3-4fc6-90a0-73a335a6b547">

Die Batch-Pipeline wurde komplett im AWS-Ökosystem entwickelt und mithilfe von python, boto3, pandas und terraform umgesetzt. Dabei kann sie in verschiedene Layer unterteilt werden, die im folgenden vorgestellt werden kurz erläutert werden: 

### 1. Data Ingestion Layer
Eine lokal gespeicherte CSV_Datei wird hithilfe eines Python- und Terraform-Skript in die AWS-Cloud-Umgebung migriert.<br>
Dabei dient das **Terraform-Skript** dazu die benötigten AWS-Services zu erstellten. Es werden folgende AWS-Services erstellt: S3-Bucket, Lambda-Funktion, Glue, Identity and Access Management (IAM) & Key Management Service (KMS). Das **Python-Skript** dient dazu die lokal gespeichert CSV-Datei, das AWS-Glue-Skript und das Manifest für QuickSight in den durch Terraform erstellten S3-Bucket hochzuladen. <br>
Um die AWS-Umgebung zu erstellen und das Python-Skript auszuführen müssen vorher zwei manuelle Schritte durchgeführt werden. <br>

**Das Bash-Skript ausführbar machen** <br>
Zuerst muss das Bash-Skript angepasst werden, wobei der genaue Pfad der Ausführung definiert wird.
```
#apply Terraform- change the path! 
cd /Users/path-to-folder/Batch_Pipeline_AWS/terraform
terraform init
terraform plan -out=plan.out
terraform apply -auto-approve plan.out

#cron job to upload script - change the path! 
cd /Users/path-to-folder/Batch_Pipeline_AWS/upload
python3 upload_s3.py
```
Anschließend muss das Bash-Skript ausführbar gemacht werden. 
```
chmod +x /path-to-script-file/run_terraform_python.sh
```
Dabei muss `/path-to-script-file/`durch den genauen Pfad zum lokal abgelegten Bash-Skript ersetzt werden. <br>

Darauf folgend kann der CronJob definiert werden, um das Skript in einem festen Intervall hochzuladen. <br>
```
0 0 15 1-12/3 * /path-to-script-file/run_terraform_python.sh
```
Wieder muss `/path-to-script-file/` durch den genauen Pfad zum lokal abgelegten Bash-Skript ersetzt werden. Dieser Befehl führt dazu, dass das Bash-Skript alle drei Monate, jeweils am 15 Tag des Monats um 00:00 Uhr ausgeführt wird. Das Intervall kann durch Anpassung des Codes flexibel verändert werden. 

### 2. Data Storage Layer 
Nachdem die CSV (Crime_Data_from_2020_to_Present.csv) hochgeladen wurde, wird diese in einem S3-Bucket gespeichert. Ebenso dient der S3-Bucket als Speicherort für das Manifest (crime_data_manifest.json), das AWS-Glue-Skript (script_glue.py) und dem Ergebnis der Datenverarbeitung mit AWS-Glue (glue_result.csv). Um eine möglichst umfassende Datensicherheit zu gewährleisten werden durch **Amazon KMS** alle eingehenden Daten vor der Speicherung auf verschlüsselt und bei der weiter wieder entschlüsselt. 

### 3. Data Processing Layer
Im nächsten Schritt wird die CSV-Datei mithilfe von Amazon Glue verarbeitet. Dabei wird das im Ingestion Layer hochgeladene Verarbeitungsskript ausgeführt (script_glue.py), welches einen Datensatz erzeugt, der die kumulierte Anzahl der Verbrechen pro Tag seit 01/2020 enthält (glue_result.csv). Das Ergebnis wird anschließend wieder in dem S3-Bucket gespeichert. . 

### 4. Presentation Layer
Das Ergebnis der Verarbeitung durch Amazon Glue wird im Anschluss in Form eines Liniendiagramm mithilfe von Amazon QuickSight dargestellt. Hierzu wird das in den S3-Bucket hochgeladene Manifest benötigt, um Amazon QuickSight zugriff auf glue_result.csv zu gewährleisten. 

### 5. Orchestierung
Das Python-Skript wird in einem definierten Abstand von drei Monaten ausgeführt. Hierzu wird das Bash-Skript verwendet welches in einem dreimonatigen Intervall einen CronJob ausführt. Ebenso überwacht die Lambda-Funktion den S3-Bucket, um die Verarbeitung der CSV-Datei mit Amazon Glue auszuführen, sobald eine neue Version der CSV-Datei hochgeladen wurde. 

### 6. Security
Um die Datensicherheit zu gewährleisten werden AWS IAM und AWS KMS verwendet. **AWS IAM** dient dazu die Zugriffsberechtigungen der Services zu definieren, um ausschließlich autorisierten Nutzern und Services Zugriff auf diese zu gewährleisten. Hierzu werden für jeden Service individuelle Rollen mithilfe von Terraform erstellt. Mithilfe von **Amazon KMS** werden außerdem alle Daten auf der physischen Ebene verschlüsselt und bei Verwendung wieder entschlüsselt, um diese sicher in den S3-Bucket zu speichern. 

## Einrichtung des AWS-Kontos um die Pipeline nutzen zu können
Um die vorgestellte Batch-Pipeline nutzen zu können und die IAC Struktur nutzen zu können, müssen im vorhinein einige Einstellungen vorgenommen werden. 
### 1. AWS Account
Sie müssen über einen aktiven AWS-Acocount verfügen. Sollten Sie keinen Account besitzen, können Sie sich unter folgenden Link regestrien:
<a href="https://portal.aws.amazon.com/billing/signup?nc2=h_ct&src=header_signup&refid=3f93bdb7-cca2-4053-94a7-a03fb33c9dfa&redirect_url=https%3A%2F%2Faws.amazon.com%2Fregistration-confirmation&language=de_de#/start/email">AWS</a>
### 2. IAM Benutzer
- Navigieren Sie zum IAM-Dashboard
- Erstellen Sie einen neuen IAM-Benutzer
- Geben Sie den IAM-Benutzer die entsprechenden Berechtigungen. Der IAM-Benutzer benötigtig mindestens Zugriff auf S3, IAM, Glue, Lambda, Cloud-Watch, QuickSight.
### 3. Access Keys
Nachdem der IAM-Benutzer erstellt wurde, müssen der Access Key und der Secret Access Key erzeugt werden. Speichern Sie die beiden Keys an einem sicheren Ort. Der Secret Access Key wird nur einmalig erzeugt und kann danach nicht erneut in AWS abgerufen werden.
### 4. Das AWS CLI einrichten
Anschließend kann die AWS CLI genutzt werden. Hier muss diese installiert werden.
```
pip install awscli
```
und kann darauffolgend konfiguriert werden. 
```
aws configure
Access Key ID = your Access Key
Secret Access Key = your Secret Access Key 
default region = your Region (eu-central-1 für Deutschland)
default output format = json 
```
Nachdem die entsprechenden Informationen in der AWS CLI hinterlegt wurden, kann die Batch-Pipline mit Terraform erzeugt werden. 

