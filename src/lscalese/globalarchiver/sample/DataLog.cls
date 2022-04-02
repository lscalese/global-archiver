Class lscalese.globalarchiver.sample.DataLog Extends %Persistent
{

Property Username As %String(MAXLEN = 128);

Property AccessToPatientId As %Integer;

Property DateTime As %TimeStamp;

Index IdxDT On DateTime;

/// Description
ClassMethod GenerateData(number As %Integer = 100000) As %Status
{
    Set sc = $$$OK

    For i=1:1:number {
        Set obj = ..%New()
        Set obj.Username = ##class(%PopulateUtils).FirstName()
        Set obj.AccessToPatientId = ##class(%PopulateUtils).Random(1000)
        Set obj.DateTime = ##class(%PopulateUtils).TimeStamp($ZDT($H-365,3,1), $ZDT($H,3,1))
        Do obj.%Save()
    }

    Return sc
}

ClassMethod GetLastId(retention As %Integer = 30) As %Integer
{
    Set limit = $Order(^lscalese.globalarcCA13.DataLogI("IdxDT", $zdt($h-retention _ ",0" ,3,1)), -1)
    Set lastId = $Order(^lscalese.globalarcCA13.DataLogI("IdxDT", limit, ""), -1)
    Return lastId
}

/// Description
ClassMethod Test() As %Status
{
    Set sc = $$$OK

    Do ##class(lscalese.globalarchiver.sample.DataLog).CreateDB("ARCHIVE")

    Do ..GenerateData(10000)

    Set ArchiveDatabase = "ARCHIVE"
    Set Global = $Name(^lscalese.globalarcCA13.DataLogD)

    ; Archive data older than 30 days
    Set lastId = ..GetLastId(30)
    
    Set sc = ##class(lscalese.globalarchiver.Copier).Copy(Global, lastId, ArchiveDatabase)
    Quit:$$$ISERR(sc) sc

    Set sc = ##class(lscalese.globalarchiver.Cleaner).DeleteArchivedData(Global,ArchiveDatabase)

    Return sc
}

ClassMethod CreateDB(Name As %String = "ARCHIVE") As %Status
{
    New $Namespace
    Set $Namespace = "%SYS"

    If ##class(Config.Databases).Exists(Name) { ; already exists do nothing
        Quit $$$OK
    }

    Set Properties("Directory") = $zcvt($ZU(12, Name), "l")

    Do ##class(%File).CreateDirectoryChain(Properties("Directory"))
    
    Set db=##Class(SYS.Database).%New()
    Set db.Directory = Properties("Directory")
    $$$QuitOnError(db.%Save())

    $$$QuitOnError(##Class(Config.Databases).Create(Name,.Properties))
    
    Return sc
}

Storage Default
{
<Data name="DataLogDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Username</Value>
</Value>
<Value name="3">
<Value>AccessToPatientId</Value>
</Value>
<Value name="4">
<Value>DateTime</Value>
</Value>
</Data>
<DataLocation>^lscalese.globalarcCA13.DataLogD</DataLocation>
<DefaultData>DataLogDefaultData</DefaultData>
<IdLocation>^lscalese.globalarcCA13.DataLogD</IdLocation>
<IndexLocation>^lscalese.globalarcCA13.DataLogI</IndexLocation>
<StreamLocation>^lscalese.globalarcCA13.DataLogS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
