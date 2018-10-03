# SFDC Sandbox Loader

This is a set of scripts that will extract data from one Salesforce org and import it into another.
Under the hood these scripts use the [Dataloader](https://github.com/forcedotcom/dataloader) JAR from Salesforce.
You will likely want to customize the files under conf for your own data.
See Development for more information.

## Setting up for the demo

I have created a few sample conf files to demonstrate this data loader.
In order to run the demo you will need to do the following:

- Login to your destination org
	- Add your current IP address to Network Access
	- Create new fields on the Account and Contact objects called External_ID__c and make them external id fields
- Login to your source org 
	- Add your current IP address to Network Access
	- Create three new accounts with the following names:
  		- Parent
  		- Child
  		- Grandchild
	- Set up your account hierarchy so Parent is the parent account for Child and Child is the parent account for Grandchild
	- Create some contacts on these accounts

The conf files are initally setup to extract a few fields from accounts and contacts.
Note that if your destination org has a namespace then you will need to edit the conf files and add your namespace. 
If you're not sure what a namespace is then you probably don't have one.


## Getting Started

### Prerequisites
- Java (you probably already have it)
- Git (needed to clone the repo - https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

### Open a bash terminal
- Any terminal on Mac/Linux will do. For Windows you will probably want to use the Git Bash terminal.
- Test out your prerequisites:
	- `java -version` should print the version of java installed
	- `git --version` should print the version of git installed
	- If any of these commands fail then... fix it.

### Setup Credentials
- Optional - create a file called `variables.sh` to place your login variables (recommended). You can copy `variables.sh.template` to get started, just make sure you change the usernames.
- run `./setupAuth.sh`
- Enter the following when prompted:
	- Source Sandbox: the name of the sandbox from which we will extract data
	- Dest Sandbox: the name of the sandbox into which we will import data
	- Source Username: you salesforce username for the source sandbox without a sandbox prefix
	- Dest Username: you salesforce username for the destination sandbox without a sandbox prefix
	- Source Password: your password for the source sandbox.
	- Dest Password: your password for the destination sandbox.
	- NOTE: if you leave the Sandbox blank then it will assume you're working with a production org (https://login.salesforce.com)
- This will setup the `work` directory with your configuration:
	- work/conf/extract/config.properties will be used to extract data from the Source Sandbox
	- work/conf/import/config.properties will be used to import data into the Destination Sandbox
	- inspect these files to ensure you're not doing anything dumb like importing into your production org
	- All passwords will be encrypted using the randomly generated key.txt file. This file is regenerated everytime you run `./setupAuth.sh`

### Run Sandbox Refresh ETL

#### Full Load
- Run `./fullLoad.sh` to run ETLs for accounts and contacts. It will extract and import all data.
	- you can run this script multiple times on the same sandbox if you need to refresh the data at a later time. It will do upserts on your data.
	- You can run the extract and import processes separately with `./fullLoad.sh extract` and `./fullLoad.sh import`. This allows you to change the csv data before importing it.
- The ETL will log to the console. You can pipe this to a log file if you wish to review it later, eg `./fullLoad.sh > fullLoad.log 2>&1`
- ETL success/error status reports are created under `work/status`
- CSVs used by the ETL process are stored under `work/csv`
- When you're done you can cleanup the data using `./clean.sh`


## Advancd Usage

### Run an ETL Set
- The script `runEtlSet.sh` will run a set of ETLs. It accepts two arguments:
	- A text file with the ETLs to run - required
	- An optional phase to run - extract or import. If you do not specify a phase then the script will run both extract and import phases.
- Run `./runEtlSet.sh etls/sales_data.txt` to run ETLs for sandbox refresh data. This example will run all ETLs listed in the file `etls/sales_data.txt`
- You can run the extract and import processes separately with `./runEtlSet.sh etls/sales_data.txt extract` and `./runEtlSet.sh etls/sales_data.txt import`. This allows you to change the csv data before importing it.

### Run a Single ETL
- The script `runEtl.sh` will run a single ETL. It accepts two arguments:
	- The name of the ETL to run. The ETL name must match the name of the bean.xml and the map.sdl files it will use.
	- An optional phase to run - extract or import. If you do not specify a phase then the script will run both extract and import phases.
- All ETLs are located in the conf directory. An ETL requires a bean file and a map file. The names of the bean and map files must match.
- Run `./runEtl.sh etlName` where etlName is the name of the bean file you wish to run.
- To perform an extract only run `./runEtl.sh accounts extract`
- To perform an import only run `./runEtl.sh accounts import`

### Changing ETL Data Manually
- You can manually manipulate the extracted data before loading.
	- Run `./runEtl.sh accounts extract` to create a csv extract
	- Find the csv file under `work/csv` and make changes as necessary 
	- Run `./runEtl.sh accounts import` to import the csv


## Development

### Adding fields to an existing ETL
- Locate the ETL bean under `conf/beans`.
- Add your fields to the SOQL statement
- Locate the ETL map under `conf/maps`
- Add your fields to the mapping:
	- mappings take the form of CSV_FIELD=Sf_Field
	- The CSV Field must be in all upper case
	- If the SF Field is a child field (i.e. Account.External_ID__c) you must change it to use escaped colon notation (i.e. Account\\:External_ID__c)
	- To map a constant use "constant"=Sf_Field

### Creating a new ETL
- Create a new bean under `conf/beans`. Use an existing bean as your template
	- The name of the file will be referred to at etlName in this example. It should reflect the type of object you're going to load.
	- Change the name properties to `etlNameExtract` and `etlNameImport`
	- Change the dataAccess.name to `csv/etlName.csv`
	- Change the sfdc.entity to the name of your object
	- Change the sfdc.extractionSOQL to your SOQL query
	- Change the process.mappingFile to `maps/etlName.sdl`
	- Change process.outputError to `status/errors_etlName.csv`
	- Change process.outputSuccess to `status/success_etlName.csv`
	- Change sfdc.externalIdField to the name of your externalId field that will be used as an upsert key
	- Test your extract by running `./runEtl.sh etlName extract`
- Create a new mapping file under `conf/maps`.
	- You can use the dataloader UI to create the mapping from the CSV generated in the last step above.
	- Name the mapping file `etlName.sdl`
	- Map every field in the SOQL statement, or remove the unmapped fields from your SOQL. Unmapped fields generate extra log output that we do not want.

### Adding a simple filter
- There is a file called filter.txt that can be used to filter your data.
- The rows in filter.txt will get injected into your SOQL during the extract phase. They will get stubbed in anywhere it finds REPLACE_ME

Example:

- You have the following in your filter.txt
```
11111
22222
33333
```

- You have the following Where clause in your SOQL `WHERE Number__c IN (REPLACE_ME)`
- The final SOQL query will have `WHERE Number__c IN ('11111','22222','33333')`

### Controlling the order of execution of ETLs
- For a new category of ETLs to exectute create a new .txt file in etls folder
	- add a reference to this into fullLoad.sh
	- Use # for comments
	- on each line add the name of the xml file stored in conf/beans in the appropriate order of execution