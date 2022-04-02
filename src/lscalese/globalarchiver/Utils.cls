Class lscalese.globalarchiver.Utils
{

/// Get directory from database name
ClassMethod GetDirectoryByName(DatabaseName As %String, ByRef sc As %Status = {$$$OK}) As %String
{
    New $Namespace
    Set $Namespace = "%SYS"

    If '##class(Config.Databases).Exists(DatabaseName) {
        Set sc = $$$ERROR($$$GeneralError, "Database does not exists "_DatabaseName)
        Return ""
    }

    Do ##class(Config.Databases).Get(DatabaseName, .properties)

    Return properties("Directory")
}

ClassMethod DeleteCurrentMapping(Global As %String, ArchiveDatabase As %String) As %Status
{
    Set sc = $$$OK

    Set:$Extract(Global)="^" Global = $Extract(Global, 2, *)

    Set currentNamespace = $Namespace

    New $Namespace
    Set $Namespace = "%SYS"

    Try {
        ; Check if a global mapping already exists for this global and database
        ; If yes, we must delete it before creating our new map.

        Set tStatement = ##class(%SQL.Statement).%New()
        Set sc = tStatement.%PrepareClassQuery("Config.MapGlobals","List")
        
        If $$$ISERR(sc) $$$ThrowStatus(sc)

        Set tResult = tStatement.%Execute(currentNamespace, Global _ "*")
        If (tResult.%SQLCODE'=0)&&(tResult.%SQLCODE'=100) $$$ThrowStatus($$$ERROR($$$SQLError, tResult.%SQLCODE, tResult.%Message)) 
        
        While tResult.%Next() {
            
            If tResult.%Get("Global") = Global, tResult.%Get("Database") = ArchiveDatabase {
                Set toDelete(tResult.%Get("Name")) = ""
            }

        }

        Kill tResult,tStatement

        Return:'$Data(toDelete) sc

        Set k = ""
        For  {
            Set k = $Order(toDelete(k), 1)
            Quit:k=""

            Set sc = $$$ADDSC(sc, ##class(Config.MapGlobals).Delete(currentNamespace, k))
        }

    } Catch (ex) {
        Set sc = ex.AsStatus()
    }

    Return sc
}

/// Calculate the global mapping for the archived database
ClassMethod CalculateGlobalMapping(Global As %String, ArchiveDatabase, ByRef Config As %DynamicObject = {{}}) As %Status
{
    Set sc = $$$OK
    
    Set Directory = ..GetDirectoryByName(ArchiveDatabase, .sc)
    Quit:$$$ISERR(sc) sc
    
    Set:$Extract(Global)="^" Global = $Extract(Global, 2, *)

    Set node = $$$FormatText("^[""^^%1""]%2", Directory, Global)

    Set firstId = $Order(@node@(""))
    Set lastId = $Order(@node@(""),-1) + .5

    Set name = $$$FormatText("%1(%2):(%3)", Global, firstId, lastId)

    Set Config = {
        "Name" : (name),
        "Namespace" : ($Namespace),
        "Database" : (ArchiveDatabase)
    }

    Return sc
}

/// Description
ClassMethod GetSourceDatabase(Global As %String, ByRef SourceDirectory As %String = "") As %String
{
    Set sc = $$$OK
    Set currentNamespace = $Namespace

    New $Namespace
    Set $Namespace = "%SYS"

    If ##class(Config.MapGlobals).Exists(currentNamespace, Global) { ; case : the global is not on the default namespace database
        Do ##class(Config.MapGlobals).Get(currentNamespace, Global, .map)
        Set db = map("Database")
    } Else {
        Do ##class(Config.Namespaces).Get(currentNamespace, .p)
        Set db = p("Globals")
    }

    Do ##class(Config.Databases).Get(db, .properties)
    Set SourceDirectory = properties("Directory")

    Return db
}

}
