﻿begin {
    if ($host.Version.Major -gt 1) { $host.Runspace.ThreadOptions = "ReuseThread" }
    if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) { Add-PSSnapin "Microsoft.SharePoint.PowerShell" }
}
process {

Get-SPWebApplication | Get-SPContentDatabase | Get-SPSite -Limit ALL | Get-SPWeb -Limit ALL | ForEach {
    $web = $_

    $WebUrl = $web.Url
    $SiteUrl = $web.Site.Url

    Write-Host "Processing SPWeb $($webUrl)"

    $web.Lists | ForEach {
        $list = $_
        
        $ListName = $list.Title
        $ListUrl = "$($web.Url)/$($list.RootFolder.Url)"
        $ListLastItemModifiedDate = $list.LastItemModifiedDate
        $ListLastItemDeletedDate = $list.LastItemDeletedDate
        $ListItemCount = $list.ItemCount

        $vti_timelastmodified = $list.RootFolder.Properties["vti_timelastmodified"]
        $vti_dirlateststamp = $list.RootFolder.Properties["vti_dirlateststamp"]
        $vti_timecreated = $list.RootFolder.Properties["vti_timecreated"]

        $list.ContentTypes | ForEach {
            $contentType = $_

            $hasInfoPathNewItemForm = $contentType.NewFormUrl -like "*newifs.aspx"
            $hasInfoPathEditItemForm = $contentType.EditFormUrl -like "*editifs.aspx"
            $hasInfoPathDisplayForm = $contentType.DisplayFormUrl -like "*displayifs.aspx"

            if($hasInfoPathNewItemForm -or $hasInfoPathEditItemForm -or $hasInfoPathDisplayForm) {
                $info = New-Object PSObject -Property @{
                    SiteUrl = $SiteUrl
                    WebUrl = $WebUrl
                    ListUrl = $ListUrl
                    ListName = $ListName
                    ListLastItemModifiedDate = $ListLastItemModifiedDate
                    ListLastItemDeletedDate = $ListLastItemDeletedDate
                    ListItemCount = $ListItemCount
                    ListRootFolder_timelastmodified = $vti_timelastmodified
                    ListRootFolder_dirlateststamp = $vti_dirlateststamp
                    ListRootFolder_timecreated = $vti_timecreated
                    ContentTypeName = $contentType.Name
                    HasInfoPathNewItemForm = $hasInfoPathNewItemForm
                    HasInfoPathEditItemForm = $hasInfoPathEditItemForm
                    HasInfoPathDisplayForm = $hasInfoPathDisplayForm
                }
                Write-Output $info
            }
        }
    }
} | Export-Csv "$PSScriptRoot\ListsWithInfoPathForms.csv" -NoTypeInformation 

}

end {
    Write-Host "Done"
}