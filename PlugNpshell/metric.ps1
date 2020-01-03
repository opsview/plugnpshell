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

    [System.Collections.ArrayList] static $ByteUnits = @('b', 'B', 'bps', 'Bps')
    [System.Collections.ArrayList] static $ConvertableUnitsN = @('s', 'Hz', 'W')
    [System.Collections.ArrayList] static $ConvertableUnitsPositive = @('Hz', 'W')
    [System.Collections.ArrayList] static $ConvertableUnitsP = [metric]::ConvertableUnitsPositive + [metric]::ByteUnits
    [System.Collections.ArrayList] static $ConvertableUnits = [metric]::ConvertableUnitsN + [metric]::ConvertableUnitsP
    [int] $PRECISION = 2

    [UnitCollection] static $EiB = [UnitCollection]::New("ExbiByte", "E", [Math]::Pow(1024, 6))
    [UnitCollection] static $PiB = [UnitCollection]::New("PebiByte", "P", [Math]::Pow(1024, 5))
    [UnitCollection] static $TiB = [UnitCollection]::New("TebiByte", "T", [Math]::Pow(1024, 4))
    [UnitCollection] static $GiB = [UnitCollection]::New("GibiByte", "G", [Math]::Pow(1024, 3))
    [UnitCollection] static $MiB = [UnitCollection]::New("MebiByte", "M", [Math]::Pow(1024, 2))
    [UnitCollection] static $KiB = [UnitCollection]::New("KibiByte", "K", 1024)
    [System.Object[]] static $ByteConversionValuesP = @([metric]::EiB, [metric]::PiB, [metric]::TiB, [metric]::GiB, `
                                                        [metric]::MiB, [metric]::KiB)

    [UnitCollection] static $EB = [UnitCollection]::New("ExaByte", "E", 1e18)
    [UnitCollection] static $PB = [UnitCollection]::New("PetaByte", "P", 1e15)
    [UnitCollection] static $TB = [UnitCollection]::New("TeraByte", "T", 1e12)
    [UnitCollection] static $GB = [UnitCollection]::New("GigaByte", "G", 1e9)
    [UnitCollection] static $MB = [UnitCollection]::New("MegaByte", "M", 1e6)
    [UnitCollection] static $KB = [UnitCollection]::New("KiloByte", "K", 1000)
    [System.Object[]] static $DecConversionValuesP = @([metric]::EB, [metric]::PB, [metric]::TB, [metric]::GB, `
                                                       [metric]::MB, [metric]::KB)

    [UnitCollection] static $Pico = [UnitCollection]::New("Pico", "p", [Math]::Pow(0.001, 4))
    [UnitCollection] static $Nano = [UnitCollection]::New("Nano", "n", [Math]::Pow(0.001, 3))
    [UnitCollection] static $Micro = [UnitCollection]::New("Micro", "u", [Math]::Pow(0.001, 2))
    [UnitCollection] static $Milli = [UnitCollection]::New("Milli", "m", [Math]::Pow(0.001, 1))
    [System.Object[]] static $DecConversionValuesN = @([metric]::Milli, [metric]::Micro, [metric]::Nano, [metric]::Pico)

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
                throw [ParamError]::new("Invalid Parameter '$key'. Check the correct naming of the argument.")
            }
        }
        if ($this.Name -And $this.Value -ne [long]::MinValue) {
            $this.Init()
        }
        else {
            throw [ParamError]::new("Insufficient parameters. You must specify the Name and the Value of the metric.")
        }
    }

    [void] Init() {
        $this.DisplayName = $( if ($this.DisplayName) { $this.DisplayName } else { $this.Name } )
        $this.ValidateName()
        if ($this.DisplayInSummary) {
            $this.CreateMetricSummary()
        }
        if ($this.DisplayInPerf) {
            $this.CreateMetricPerfOutput()
        }
        $this.ExitCode = $this.Evaluate($this.Value, $this.WarningThreshold, $this.CriticalThreshold)

    }

    [UnitCollection[]] static GetConvertableUnitsArr($Val, $Unit, $SiConversion) {
        # Returns the correct array to convert the value
        $ConversionArr = @()
        if ($Val -ge 1 -And [Metric]::ConvertableUnitsP.Contains($Unit)) {
            if ([Metric]::ByteUnits.Contains($Unit) -And -Not($SiConversion)) {
                $ConversionArr = [Metric]::ByteConversionValuesP
            }
            else {
                $ConversionArr = [Metric]::DecConversionValuesP
            }
        }
        elseif ($Val -lt 1 -And [Metric]::ConvertableUnitsN.Contains($Unit)) {
            $ConversionArr = [Metric]::DecConversionValuesN
        }
        return $ConversionArr
    }


    [HashTable] static ConvertValueMethod($OldValue, $Unit, $ConversionTable, $Precision) {
        # Converts values with the right prefix for display.
        $UOMprefix = ''
        [hashtable] $conversion = @{ }
        [double] $newValue = $OldValue
        for ($i = 0; $i -lt $ConversionTable.Count; $i++) {
            if ($OldValue -ge $ConversionTable[$i].GetValue()) {
                $newValue = $OldValue / $ConversionTable[$i].GetValue()
                $UOMprefix = $ConversionTable[$i].GetUnitPrefix()
                break
            }
        }
        $conversion.Value = [math]::Round($newValue, $Precision)
        $conversion.UOM = "$UOMprefix$Unit"
        return $conversion
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

    [double] static ConvertThreshold([string]$Threshold, [string]$Uom, [boolean]$SiConversion) {
        # Convert threshold value.
        $ConvertVal = 1
        $Unit = $Threshold -replace ('\d|\.', '')
        $Val = $Threshold -replace ('([^\d.])+','')
        $ConvertUnit = $Unit.Substring(0, 1)
        $Unit = $Unit.Substring(1)
        If ($Uom -ne $Unit) {
            throw [InvalidMetricThreshold]::new("Unit '$Uom' doesn't match '$Unit'")
        }

        try {
            $NumericValue = [float]::Parse($Val)
        }
        catch {
            throw [InvalidMetricThreshold]::new("'$Val' is not a numeric value")
        }
        $ConversionArr = [Metric]::GetConvertableUnitsArr($NumericValue, $Uom, $SiConversion)
        if ($ConversionArr) {
            $ConvertVal = ($ConversionArr | Where-Object {
                    $_.UnitPrefix -eq $ConvertUnit
                }).Value
        }
        else {
            throw [InvalidMetricThreshold]::new("Error make sure the '$Uom' is correct")
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
        return [Metric]::ConvertThreshold($Val, $this.UOM, $this.SiBytesConversion)
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
        catch [InvalidMetricThreshold] {
            throw [InvalidMetricThreshold]::new("Invalid Threshold Syntax '$Threshold'. $($_.Exception.ErrorMessage)")
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

    [hashtable] static ConvertValue($Value, $Unit, $SummaryPrecision, $SiConversion) {
        $convertableUnitsArr = [Metric]::GetConvertableUnitsArr($Value, $Unit, $SiConversion)
        $convertedMetric = [Metric]::ConvertValueMethod($Value, $Unit, $convertableUnitsArr, $summaryPrecision)
        return $convertedMetric
    }

    [void] CreateMetricSummary() {
        # Creates the summary data output string for the Check"""
        [hashtable] $convertedMetric = @{}
        $convertedMetric.Value = $this.Value
        $convertedMetric.UOM = $this.UOM
        if ($this.ConvertMetric) {
            $convertedMetric = [Metric]::ConvertValue($this.Value, $this.UOM, $this.SummaryPrecision, $this.SiBytesConversion)
        }
        $displayUOM = $convertedMetric.UOM
        if ( $displayUOM -eq 'per_second') {
            $displayUOM = '/s'
        }
        if ($this.DisplayInSummary) {
            $this.DisplayFormat = $this.DisplayFormat -Replace ('{name}', $this.DisplayName)
            $this.DisplayFormat = $this.DisplayFormat -Replace ('{unit}', $displayUOM)
            $this.DisplayFormat = $this.DisplayFormat -Replace ('{value}', $convertedMetric.Value)
            $this.Summary = $this.DisplayFormat
        }
    }

    [void] CreateMetricPerfOutput() {
        # Creates the performance data output string for the Check"""
        $MetricValue = [Math]::Round($this.Value, $this.PerfDataPrecision)
        $MetricName = $( if ( $this.Name.Contains(' ')) { "'{0}'" -f $this.Name } else { $this.Name } )
        $HasThresholds = $this.WarningThreshold -Or $this.CriticalThreshold
        $this.PerfOutput = "{0}={1}{2}{3}{4}{5}{6} " -f $MetricName, $MetricValue, $this.UOM,
        $( If ($HasThresholds) { ';' } Else { '' } ), $this.WarningThreshold,
        $( If ($HasThresholds) { ';' } Else { '' } ), $this.CriticalThreshold
    }
}