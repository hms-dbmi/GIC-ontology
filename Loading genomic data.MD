# Loading Genomic Data
Step 1: Load the phenotypic data first. 
Step 2: Use the Jenkins jobs to load the genomic data: https://github.com/hms-dbmi/pic-sure-all-in-one/blob/master/initial-configuration/jenkins/jenkins-docker/jobs/Load%20Genomic%20Data/config.xml
More detailed resource: https://github.com/hms-dbmi/pic-sure-hpds-genotype-load-example

Step 3: Run the following Jenkins job after Step 2.
https://github.com/hms-dbmi/pic-sure-all-in-one/blob/master/initial-configuration/jenkins/jenkins-docker/jobs/Load%20Genomic%20Metadata/config.xml 
