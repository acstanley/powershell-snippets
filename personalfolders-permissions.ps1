$HomeFoldersPath = "F:\Shares\PersonalDrives\"

$HomeFolders = Get-ChildItem $HomeFoldersPath | where{$_.PSIsContainer -eq 'True'}

foreach ($HomeFolder in $HomeFolders) {
    $Path = $HomeFolder.FullName
    Write-Host $Path
    $Acl = (Get-Item $Path).GetAccessControl('Access')
    
    # add modify permissions to the user with the same username as the folder
    $Username = $HomeFolder.Name
    $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($Username, 'Modify','ContainerInherit,ObjectInherit', 'None', 'Allow')
    $Acl.SetAccessRule($Ar)
    Set-Acl -path $Path -AclObject $Acl

    # add modify permissions for IT Dept SA
    $ITDeptSA = "IT Dept SA"
    $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($ITDeptSA, 'Modify','ContainerInherit,ObjectInherit', 'None', 'Allow')
    $Acl.SetAccessRule($Ar)
    Set-Acl -path $Path -AclObject $Acl

    # disable inheritance, convert existing ACEs to explicit
    icacls $HomeFolder.FullName /inheritance:d /t /c
}
