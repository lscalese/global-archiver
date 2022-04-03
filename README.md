## global-archiver

This is a tool to move a part of a global from a database to another database.  
A sample involves mirroring and ecp will be added soon.  


## Run with Docker

Build: 

```bash
docker-compose build --no-cache
```

Start container : 
```bash
docker-compose up -d
```

## Installation ZPM

```
zpm "install global-archiver"
```

## How to Test it

Create a database named "ARCHIVE"

```objectscript
Do ##class(lscalese.globalarchiver.sample.DataLog).CreateDB("ARCHIVE")
```

Open IRIS terminal:

Generate 10 000 records in a sample table.

```objectscript
Do ##class(lscalese.globalarchiver.sample.DataLog).GenerateData(10000)
```

Get the last id older than 30 days: 
```objectscript
Set lastId = ##class(lscalese.globalarchiver.sample.DataLog).GetLastId(30)
```

Copy data older than 30 days to the ARCHIVE database:
```objectscript
Set Global = $Name(^lscalese.globalarcCA13.DataLogD)
Set sc = ##class(lscalese.globalarchiver.Copier).Copy(Global, lastId, "ARCHIVE")
```

Delete data from the source database:
```objectscript
Set sc = ##class(lscalese.globalarchiver.Cleaner).DeleteArchivedData(Global,"ARCHIVE")
```
