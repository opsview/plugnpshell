#Check class, contains Check Object that controls the check execution.

Class Check {
    [string] $Name
    [string] $Version = "V1.0"
    [string] $Preamble = "Preamble"
    [string] $Description = "Description"
    [string] $StateType = "METRIC"
    [string] $OK = "OK"
    [string] $WARNING = "WARNING"
    [string] $CRITICAL = "CRITICAL"
    [string] $UNKNOWN = "UNKNOWN"
    [string] $OutputMessage = ''
    [Metric[]] $MetricArr = @()
    [String] $Sep = ', '
    <#
    .Description
        Object for defining and running Opsview Service Checks.

     .PARAMETERS
        Name -- Name of the Check (required)
        Version -- Version of the Check
        Preamble -- Preamble of the Check
        Description --A description of the check
        StateType --The string printed before the Service Check status (default: METRIC)
        Sep -- The string separating each metric's output (default: ', ')
    #>

    Check([string]$Name, [string]$Version, [string]$Preamble, [string]$Description, [string]$StateType) {
        $this.Init($Name, $Version, $Preamble, $Description, $StateType)
    }
    Check([string]$Name, [string]$Version, [string]$Preamble, [string]$Description) {
        $this.Init($Name, $Version, $Preamble, $Description, 'Metric')
    }
    Check() {
    }

    [void] Init([string]$Name, [string]$Version, [string]$Preamble, [string]$Description, [string]$StateType) {
        $this.Name = $Name
        $this.Version = $Version
        $this.Preamble = $Preamble
        $this.Description = $Description
        $this.StateType = $StateType
    }

    [void]HelpText($Description) {
        Write-Host  "$( $this.Name ) $( $this.Version )`n"
        Write-Host "$( $this.Preamble )`n"
        Write-Host "Usage:`n`t$( $this.Name ) [OPTIONS]`n"
        Write-Host "Default Options:`n`t-h`tShow this help message`n"
        Write-Host "$Description`n"
        exit 3

    }

    [void] HelpText() {
        $this.helpText($this.Description)

    }

    [void] AddMetricObj([Metric] $MetricObj) {
        # Add a metric to the check's performance data from an existing Metric object
        $this.MetricArr += $MetricObj
    }

    [void] AddMetricObj([System.Object[]] $MetricObjects) {
        # Add a metric to the check's performance data from an existing Array of Metric objects
        for ($i = 0; $i -lt $MetricObjects.Count; $i++) {
            $this.AddMetricObj($MetricObjects[$i])
        }
    }

    [void] AddMetric([HashTable] $Params) {
        <#
        .DESCRIPTION
             Add a metric to the checks performance data

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
        $metricObj = [Metric]::New($Params)
        $this.AddMetricObj($MetricObj)
    }

    [String] CreateOutput() {
        # Creates the output message from the metric objects
        [string] $Output, $SummaryOutput, $PerfOutput = "", "", ""
        for ($i = 0; $i -lt $this.MetricArr.Count; $i++) {
            $SummaryOutput += $this.MetricArr[$i].Summary
            $PerfOutput += $this.MetricArr[$i].PerfOutput
            if ($i -lt $this.MetricArr.Count - 1 -And $this.MetricArr[$i + 1].DisplayInSummary) {
                $SummaryOutput += $this.sep
            }
        }
        $Output = "{0}{1}{2}" -f $SummaryOutput, $(if ($PerfOutput) { ' | ' } else { '' }), $PerfOutput
        return $Output
    }

    [void] Final() {
        # Calculates the final check output and exit status, prints and exits with the appropriate code.
        $ExitCode = ($this.MetricArr.ExitCode | Measure-Object -Maximum).Maximum
        [string]$Output = "{0} {1} - {2}" -f $this.StateType, $this.GetStatus($ExitCode),
        $this.CreateOutput()
        $this.OutputMessage = $Output
        $this.ExitMain($ExitCode, $Output)
    }

    [string] GetStatus($ReturnCode) {
        # Returns the appropriate string depending on the return code
        $Status = ""
        Switch ($ReturnCode) {
            0 { $Status = $this.OK; Break }
            1 { $Status = $this.WARNING; Break }
            2 { $Status = $this.CRITICAL; Break }
            Default { $Status = $this.UNKNOWN; Break }
        }
        return $Status
    }

    [void] ExitOK([string]$Message) {
        # Exits with specified message and OK exit status.
        # Note: existing messages and metrics are discarded.
        $this.ExitMain(0, $Message)
    }

    [void] ExitWarning([string]$Message) {
        # Exits with specified message and WARNING exit status.
        # Note: existing messages and metrics are discarded.
        $this.ExitMain(1, $Message)
    }

    [void] ExitCritical([string]$Message) {
        # Exits with specified message and CRITICAL exit status.
        # Note: existing messages and metrics are discarded.
        $this.ExitMain(2, $Message)
    }

    [void] ExitUnknown([string]$Message) {
        # Exits with specified message and UNKNOWN exit status.
        # Note: existing messages and metrics are discarded.
        $this.ExitMain(3, $Message)
    }

    [void] ExitMain([int]$ExitCode, [String]$Message) {
        # Exits with specified message and specified exit status.
        # Note: existing messages and metrics are discarded.
        Write-Host $Message
        exit $ExitCode
    }

}