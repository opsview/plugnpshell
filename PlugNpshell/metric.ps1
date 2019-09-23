Enum Status {
    OK = 0
    WARNING = 1
    CRITICAL = 2
    UNKNOWN = 3
}

class Metric {
    [string] $Name
    [double] $Value = [long]::MinValue
    [string] $UOM = ''
    [string] $UOMprefix = ''
    [string] $WarningThreshold = $null
    [string] $CriticalThreshold = $null
    [boolean] $SiBytesConversion = $false
    [boolean] $ConvertMetric = $true
    [boolean] $DisplayInPerf = $true
    [boolean] $DisplayInSummary = $true
    [string] $ExitCode
    [int] $SummaryPrecision = 2
    [int] $PerfDataPrecision = 2
    [string] $Summary = ''
    [string] $PerfOutput = ''
    [string] $DisplayName = ''
    [string] $DisplayFormat = "{name} is {value}{unit}"
    [System.Object[]] $ByteConversionValuesP
    [System.Object[]] $DecConversionValuesP
    [System.Object[]] $DecConversionValuesN
    [System.Collections.ArrayList] $ByteUnits = @('b', 'B', 'bps', 'Bps')
    [System.Collections.ArrayList] $ConvertableUnitsN = @('s', 'Hz', 'W')
    [System.Collections.ArrayList] $ConvertableUnitsP = @('Hz', 'W')
    [System.Collections.ArrayList] $ConvertableUnits
    [int] $PRECISION = 2

    <#
    .DESCRIPTION
         Object to represent Metrics added to a Check object.

    .PARAMETERS
         Name -- Name of the Metric (Required)
         Value -- Value of the Metric (note: do not include unit of measure) (Required)
         Unit -- Unit of Measure of the Metric
         WarningThreshold -- Warning threshold for the Metric (default: '')
         CriticalThreshold -- Critical threshold for the Metric (default: '')
         DisplayFormat -- Formatting string to print the Metric (default: "{name} is {value} {unit}")
         DisplayName -- Name to be used in friendly output (default: value of name)
         DisplayInSummary -- Whether to print the metric in the summary (default: True)
         DisplayInPerf -- Whether to print the metric in performance data (default: True)
         ConvertMetric -- Whether to convert the metric value to a more human friendly unit (default: False)
         SiBytesConversion -- Whether to convert values using the SI standard, uses IEC by default (default: False)
         SummaryPrecision -- The number of decimal places to round the summary data metric value to (default 2)
         PerfDataPrecision -- The number of decimal places to round the performance data metric value to (default 2)
   #>
    Metric([HashTable] $Params) {
        $Params.GetEnumerator() | ForEach-Object {
            try {
                $key = $_.Key
                $this."$key" = $_.Value
            }
            catch {
                throw [ParamError] "Invalid Parameter '$key'. Check the correct naming of the argument."
            }
        }
        if ($this.Name -And $this.Value -ne [long]::MinValue) {
            $this.Init()
        }
        else {
            throw [ParamError] "Insufficient parameters. You must specify the Name and the Value of the metric."
        }
    }

    [void] Init() {
        $this.DisplayName = $( if ($this.DisplayName) { $this.DisplayName } else { $this.Name } )
        $this.ConvertableUnitsP += $this.ByteUnits
        $this.ConvertableUnits = $this.ConvertableUnitsN + $this.ConvertableUnitsP
        $this.ValidateName()
        $this.CreateConversionTables()
        if ($this.DisplayInSummary) {
            $this.CreateMetricSummary()
        }
        if ($this.DisplayInPerf) {
            $this.CreateMetricPerfOutput()
        }
        $this.ExitCode = $this.Evaluate($this.Value, $this.WarningThreshold, $this.CriticalThreshold)

    }

    [void] CreateConversionTables() {
        $EiB = [UnitCollection]::New("ExbiByte", "E", [Math]::Pow(1024, 6))
        $PiB = [UnitCollection]::New("PebiByte", "P", [Math]::Pow(1024, 5))
        $TiB = [UnitCollection]::New("TebiByte", "T", [Math]::Pow(1024, 4))
        $GiB = [UnitCollection]::New("GibiByte", "G", [Math]::Pow(1024, 3))
        $MiB = [UnitCollection]::New("MebiByte", "M", [Math]::Pow(1024, 2))
        $KiB = [UnitCollection]::New("KibiByte", "K", 1024)
        $this.ByteConversionValuesP = @($EiB, $PiB, $TiB, $GiB, $MiB, $KiB)

        $EB = [UnitCollection]::New("ExaByte", "E", 1e18)
        $PB = [UnitCollection]::New("PetaByte", "P", 1e15)
        $TB = [UnitCollection]::New("TeraByte", "T", 1e12)
        $GB = [UnitCollection]::New("GigaByte", "G", 1e9)
        $MB = [UnitCollection]::New("MegaByte", "M", 1e6)
        $KB = [UnitCollection]::New("KiloByte", "K", 1000)
        $this.DecConversionValuesP = @($EB, $PB, $TB, $GB, $MB, $KB)

        $Pico = [UnitCollection]::New("Pico", "p", [Math]::Pow(0.001, 4))
        $Nano = [UnitCollection]::New("Nano", "n", [Math]::Pow(0.001, 3))
        $Micro = [UnitCollection]::New("Micro", "u", [Math]::Pow(0.001, 2))
        $Milli = [UnitCollection]::New("Milli", "m", [Math]::Pow(0.001, 1))
        $this.DecConversionValuesN = @($Milli, $Micro, $Nano, $Pico)
    }

    [UnitCollection[]] GetConvertableUnitsArr($Val, $Unit) {
        # Returns the correct array to convert the value
        $ConversionArr = @()
        if ($Val -ge 1 -And $this.ConvertableUnitsP.Contains($Unit)) {
            if ($this.ByteUnits.Contains($Unit) -And -not($this.SiBytesConversion)) {
                $ConversionArr = $this.ByteConversionValuesP
            }
            else {
                $ConversionArr = $this.DecConversionValuesP
            }
        }
        elseif ($Val -lt 1 -And $this.ConvertableUnitsN.Contains($Unit)) {
            $ConversionArr = $this.DecConversionValuesN
        }
        return $ConversionArr
    }


    [double] ConvertValue($OldValue, $ConversionTable, $Precision) {
        # Converts values with the right prefix for display.
        [double] $NewValue = $OldValue
        for ($i = 0; $i -lt $ConversionTable.Count; $i++) {
            if ($OldValue -ge $ConversionTable[$i].GetValue()) {
                $NewValue = $OldValue / $ConversionTable[$i].GetValue()
                $this.UOMprefix = $ConversionTable[$i].GetUnitPrefix()
                break
            }
        }
        $NewValue = [math]::Round($NewValue, $Precision)
        return $NewValue
    }

    [void] ValidateName() {
        # Ensures that the syntax of the Name is valid.
        if ($this.Name -Match "'" -Or $this.Name -Match '"|=') {
            throw [InvalidMetricName]::new("Metric names cannot contain the following characters: '=" + '"')
        }
    }

    [string] Evaluate([float] $Value, $Warning, $Critical) {
        # Returns the status code of a check obtained by evaluating the value against warning and critical thresholds
        [int] $ReturnCode = [Status]::OK
        if ($Warning) {
            $WarningThresh = $this.ParseThreshold($Warning)
            if ( $this.EvaluateThreshold($Value, $WarningThresh.start, $WarningThresh.end, $WarningThresh.checkOutsideRange)) {
                $ReturnCode = [Status]::WARNING
            }
        }

        if ($Critical) {
            $CriticalThresh = $this.ParseThreshold($Critical)
            if ( $this.EvaluateThreshold($Value, $CriticalThresh.start, $CriticalThresh.end, $CriticalThresh.checkOutsideRange)) {
                $ReturnCode = [Status]::CRITICAL
            }
        }
        return $ReturnCode
    }

    [double] ConvertThreshold($Threshold) {
        # Convert threshold value.
        [string] $Threshold
        $ConvertVal = 1
        $Unit = $Threshold -replace ('\d|\.', '')
        $Val = $Threshold -replace ("([^\d]|\.)+", '')
        $ConvertUnit = $Unit.Substring(0, 1)
        $Unit = $Unit.Substring(1)
        If ($Unit -ne $this.UOM) {
            throw [InvalidMetricThreshold]
        }

        try {
            $NumericValue = [float]::Parse($Val)
        }
        catch {
            throw [InvalidMetricThreshold]
        }
        $ConversionArr = $this.GetConvertableUnitsArr($NumericValue, $Unit)
        if ($ConversionArr) {
            $ConvertVal = ($ConversionArr | Where-Object {
                    $_.UnitPrefix -eq $ConvertUnit
                }).Value
        }
        else {
            throw[InvalidMetricThreshold]
        }
        return $NumericValue * $ConvertVal
    }

    [double] ParseThresholdLimit($Val, $IsStart) {
        # Parses a numeric string with a unit prefix e.g. 10 -> 10.0, 10m -> 0.001, 10M -> 1000000.0, ~ -> -inf/inf.
        if ($Val -eq '~') {
            # infinite value
            if ($IsStart) {
                return [long]::MinValue
            }
            return [long]::MaxValue
        }
        if ($Val.Substring($Val.length - 1) -Match '\d') {
            return $Val
        }
        return $this.ConvertThreshold($Val)
    }

    [HashTable] ParseThreshold($Threshold) {
        # Parse threshold and return the range and whether we alert if value is out of range or in the range.
        # See: https://nagios-plugins.org/doc/guidelines.html# THRESHOLDFORMAT
        $Return = @{ }
        $Return.checkOutsideRange = $true
        try {
            if ( $Threshold.StartsWith('@')) {
                $Return.checkOutsideRange = $false
                $Threshold = $Threshold.Substring(1)
            }
            if (!$Threshold.Contains(':')) {
                $Return.start = 0
                $Return.end = $this.ParseThresholdLimit($Threshold, $false)
            }
            elseif ($Threshold.EndsWith(':')) {
                $Threshold = $Threshold.Substring(0, $Threshold.Length - 1)
                $Return.start = $this.ParseThresholdLimit($Threshold, $true)
                $Return.end = [long]::MaxValue
            }
            elseif ($Threshold.StartsWith(':')) {
                $Return.start = 0
                $Return.end = $this.ParseThresholdLimit($Threshold.Substring(1), $false)
            }
            else {
                $start, $end = $Threshold.Split(':')
                $Return.start = $this.ParseThresholdLimit($start, $true)
                $Return.end = $this.ParseThresholdLimit($end, $false)
            }
        }
        catch {
            throw [InvalidMetricThreshold] ("Invalid Threshold Syntax '$Threshold'")
        }
        return $Return
    }

    [boolean] EvaluateThreshold($MetricValue, $Start, $End, $checkOutsideRange) {
        # Check whether the value is inside/outside the range.
        $MetricValue = [float]::Parse($MetricValue)
        $Start = [float]::Parse($Start)
        $End = [float]::Parse($End)
        $isOutsideRange = $MetricValue -lt $Start -or $MetricValue -gt $End
        if ($checkOutsideRange) {
            return $isOutsideRange
        }
        return !$isOutsideRange
    }

    [void] CreateMetricSummary() {
        # Creates the summary data output string for the Check"""
        $ConvertedValue = $this.Value
        if ($this.ConvertMetric) {
            $ConvertableUnitsArr = $this.GetConvertableUnitsArr($this.Value, $this.UOM)
            $ConvertedValue = $this.ConvertValue($this.Value, $ConvertableUnitsArr, $this.SummaryPrecision)
        }
        $DisplayUOM = $this.UOMprefix + $this.UOM
        if ($this.DisplayInSummary) {
            $this.DisplayFormat = $this.DisplayFormat -Replace ('{name}', $this.DisplayName)
            $this.DisplayFormat = $this.DisplayFormat -Replace ('{unit}', $DisplayUOM)
            $this.DisplayFormat = $this.DisplayFormat -Replace ('{value}', $ConvertedValue)
            $this.Summary = $this.DisplayFormat
        }
    }

    [void] CreateMetricPerfOutput() {
        # Creates the performance data output string for the Check"""
        $MetricValue = [math]::Round($this.Value, $this.PerfDataPrecision)
        $MetricName = $( if ( $this.Name.Contains(' ')) { "'{0}'" -f $this.Name } else { $this.Name } )
        $HasThresholds = $this.WarningThreshold -Or $this.CriticalThreshold
        $this.PerfOutput = "{0}={1}{2}{3}{4}{5}{6} " -f $MetricName, $MetricValue, $this.UOM,
        $( If ($HasThresholds) { ';' } Else { '' } ), $this.WarningThreshold,
        $( If ($HasThresholds) { ';' } Else { '' } ), $this.CriticalThreshold
    }
}