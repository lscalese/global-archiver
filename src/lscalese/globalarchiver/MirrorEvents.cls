Class lscalese.globalarchiver.MirrorEvents
{

/// Called from ZSTART routine to configure the correct global mapping on become primary.
/// When an archiving process is performed the global mapping is not automatically setup on the backup node.
/// We must check\setup the global on become primary event.
ClassMethod NotifyBecomePrimary() As %Status
{
    Set sc = $$$OK, currentNamespace = $Namespace

    New $Namespace

    Set global = ""
    
    For  {
        Set global = $Order(^lscalese.globalarchive(global))
        Quit:global=""

        Set db = ""
        For  {
            set db = $Order(^lscalese.globalarchive(global, db), 1, data)
            Quit:db=""

            Set $Namespace = "%SYS"

            If '##class(Config.MapGlobals).Exists($ListGet(data,2), $ListGet(data,3)) {
                
                Set $Namespace = currentNamespace
                Do ##class(lscalese.globalarchiver.Utils).DeleteCurrentMapping(global, db)
                
                Set $Namespace = "%SYS"
                Set properties("Database") = $ListGet(data,4)
                Set sc = $$$ADDSC(sc, ##class(Config.MapGlobals).Create($ListGet(data,2), $ListGet(data,3), .properties))

            }

            Set $Namespace = currentNamespace
        }
    }

    Return sc
}

}
