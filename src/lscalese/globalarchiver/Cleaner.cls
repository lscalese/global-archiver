Class lscalese.globalarchiver.Cleaner
{

/// After archiving make you sure you have a backup of the archive database,
/// we can delete archived data from the source database.
ClassMethod DeleteArchivedData(Global As %String, ArchiveDatabase As %String) As %Status
{
    Set sc = $$$OK
    
    Set:$Extract(Global)="^" Global = $Extract(Global, 2, *)

    Do ##class(lscalese.globalarchiver.Utils).GetSourceDatabase(Global, .initialGblDir)

    Set currentNamespace = $Namespace
    New $Namespace
    Set $Namespace = "%SYS"


    Set $Namespace = currentNamespace

    Set archiveDirectory = ##class(lscalese.globalarchiver.Utils).GetDirectoryByName(ArchiveDatabase, .sc, .Server)
    Quit:$$$ISERR(sc) sc

    If Server '= "" {
        Set archiveNode = $$$FormatText("^[""%1"",""%2""]%3", archiveDirectory, Server, Global)
    } Else {
        Set archiveNode = $$$FormatText("^[""^^%1""]%2", archiveDirectory, Global)
    }

    Set nsNode = $$$FormatText("^[""^^%1""]%2", initialGblDir, Global)
    
    Set id = ""
    For  {
        Set id = $Order(@nsNode@(id))
        Quit:id=""

        If '$Data(@archiveNode@(id)) { ; node does not exist on archive database --> we can stop
            Quit
        }

        Kill @nsNode@(id)

    }

    Return sc
}

}
