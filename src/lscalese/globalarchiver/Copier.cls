Class lscalese.globalarchiver.Copier
{

Parameter PAUSEXRECORDS = 10000;

Parameter PAUSETIME = 5;

/// Copy a part of a global from a database to another database
ClassMethod Copy(Global As %String, LastId As %Integer, ArchiveDatabase As %String) As %Status
{
    Set sc = $$$OK
    Set:$Extract(Global)'="^" Global = "^" _ Global

    If $TLEVEL > 0 {  ; Huge transaction security
        Quit $$$ERROR($$$GeneralError, "Please commit your transaction before calling this method to avoid an huge transaction. $TLEVEL:" _ $TLEVEL )
    }

    Set targetDirectory = ##class(lscalese.globalarchiver.Utils).GetDirectoryByName(ArchiveDatabase, .sc, .Server)

    Quit:$$$ISERR(sc) sc

    If Server '= "" { ; is remote database
        Set targetNode = $$$FormatText("^[""%1"",""%2""]%3", targetDirectory, server, $Extract(Global, 2, *) )
    } Else {
        Set targetNode = $$$FormatText("^[""^^%1""]%2", targetDirectory, $Extract(Global, 2, *) )
    }



    Try {
        Set id = "", counter = 0

        For  {
            Set id = $Order(@Global@(id), 1)
            Quit:(id>LastId)||(id="")

            TSTART
            Merge @targetNode@(id) = @Global@(id)
            TCOMMIT

            Set counter = counter + 1
            CONTINUE:''..#PAUSEXRECORDS

            If counter # ..#PAUSEXRECORDS = 0 {
                Hang ..#PAUSETIME
            }
        }

        Set sc = ..ApplyMapping(Global, ArchiveDatabase)

    } Catch (ex) {

        TROLLBACK
        Set sc = ex.AsStatus()

    }

    Return sc
}

/// Set global mapping for archived nodes
ClassMethod ApplyMapping(Global As %String, ArchiveDatabase As %String) As %Status
{
    Set sc = $$$OK
    
    $$$QuitOnError(##class(lscalese.globalarchiver.Utils).CalculateGlobalMapping(Global, ArchiveDatabase, .Config))

    $$$QuitOnError(##class(lscalese.globalarchiver.Utils).DeleteCurrentMapping(Global, ArchiveDatabase))

    Set currentNamespace = $Namespace

    New $Namespace
    Set $Namespace = "%SYS"
    
    Set properties("Database") = Config.Database
    Set sc = ##class(Config.MapGlobals).Create(Config.Namespace, Config.Name, .properties)
    
    Set $Namespace = currentNamespace
    
    If $$$ISOK(sc) {
        Set ^lscalese.globalarchive(Global, ArchiveDatabase) = $ListBuild($ZDateTime($Horolog,3,1), Config.Namespace, Config.Name, Config.Database )
    }

    Return sc
}

}
