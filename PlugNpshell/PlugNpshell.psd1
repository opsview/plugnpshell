@{

# Version number of this module.
ModuleVersion = '1.0'

# ID used to uniquely identify this module
GUID = '710a4e57-db59-4c53-af03-a1e67a88ce8b'

# Author of this module
Author = 'Opsview'

# Company or vendor of this module
CompanyName = 'Opsview'

# Copyright statement for this module
Copyright = 'Copyright (C) 2003 - 2024 Opsview Limited. All rights reserved'

# Description of the functionality provided by this module
Description = 'A Simple Powershell Library for creating Opsview Opspack plugins'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

#FormatsToProcess = '.ps1xml'
ScriptsToProcess = @('exception.ps1' , 'unitcollection.ps1', 'metric.ps1' , 'check.ps1')

# Variables to export from this module
VariablesToExport = '*'
}
