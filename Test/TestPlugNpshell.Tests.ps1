Import-Module $PSScriptRoot/../PlugNpshell -Force

Function Get-Final(){
    param(
        [Check]$Check
    )
        $ExitCode = ($Check.MetricArr.ExitCode | Measure-Object -Maximum).Maximum
        [string]$Output = "{0} {1} - {2}" -f $Check.StateType, $Check.GetStatus($ExitCode),
                                             $Check.CreateOutput()
        return $Output
}

Describe 'CheckUnitCollection'{
    $Unit = [UnitCollection]::New('Bytes', 'B', 1)

    It 'Correctly Returns Name'{
        $name = $Unit.GetName()
        $expected = "Bytes"

        ($name | Should -Be $expected)
    }
    It 'Correctly Returns Unit Prefix'{
        $prefix = $Unit.GetUnitPrefix()
        $expected = "B"

        ($prefix | Should -Be $expected)
    }
    It 'Correctly Returns Unit Value'{
        $prefix = $Unit.GetValue()
        $expected = 1

        ($prefix | Should -Be $expected)
    }
}

Describe 'CheckMetricException'{
    It 'Should throw a ParamError exception when insufficient args passed'{
        $out = {
            $Metric = [Metric]::New(@{UOM = 'b';})
        } | Should -Throw -PassThru
        $out.Exception.ErrorMessage | Should -Match "Insufficient parameters."
    }
    It 'Should throw a ParamError exception when insufficient args passed Name included'{
        $out = {
            $Metric = [Metric]::New(@{Name = 'Metric'; UOM = 'b';})
        } | Should -Throw -PassThru
        $out.Exception.ErrorMessage | Should -Match "Insufficient parameters."
    }
    It 'Should throw a ParamError exception when insufficient args passed Value included'{
        $out = {
            $Metric = [Metric]::New(@{Value = 10; UOM = 'b';})
        } | Should -Throw -PassThru
        $out.Exception.ErrorMessage | Should -Match "Insufficient parameters."
    }
    It 'Should throw a ParamError when the variable passed doesnt exist'{
        $out = {
            $Metric = [Metric]::New(@{Name = 'Metric'; Value = 10; UO = 'b';})
        } | Should -Throw -PassThru
        $out.Exception.ErrorMessage | Should -Match "Invalid Parameter 'UO'. Check the correct naming of the argument."
    }

}
Describe 'CheckExceptions'{
    It 'should match the exception Assumed OK'{
            $out = { throw [AssumedOK]"Error"} | Should -Throw -PassThru
            $out.Exception | Should -Match "AssumedOK"
    }

    It 'should match the exception ResultError'{
        $out = { throw [ResultError]"Error"} | Should -Throw -PassThru
            $out.Exception | Should -Match "ResultError"
    }
}

Describe 'CheckInvalidMetricName'{
    It 'Should throw an InvalidMetricName exception'{
        $out = {
            $Metric = [Metric]::New(@{Name = "Metric=A"; Value = 1024; UOM = 'b';})
        } | Should -Throw -PassThru
        $out.Exception.ErrorMessage | Should -Match 'Metric names cannot contain.'
    }
    It 'Should throw an InvalidMetricName exception'{
        $out = {
            $Metric = [Metric]::New(@{Name = "Metric'A"; Value = 1024; UOM = 'b';})
        } | Should -Throw -PassThru
        $out.Exception.ErrorMessage | Should -Match "Metric names cannot contain."
    }
    It 'Should throw an InvalidMetricName exception'{
        $out = {
            $Metric = [Metric]::New(@{Name = 'Metric"A'; Value = 1024; UOM = 'b';})
        } | Should -Throw -PassThru
        $out.Exception.ErrorMessage | Should -Match "Metric names cannot contain."
    }
}

Describe 'CheckMetricSummaryMsg'{

    $Metric = [Metric]::New(@{Name = "Metric"; Value = 1024; UOM = 'bps';})
    $MetricA = [Metric]::New(@{Name = "Metric A"; Value = 1000; UOM = 'b'; SiBytesConversion = $true})
    $MetricB = [Metric]::New(@{Name = "Metric B"; Value = 0.014; UOM = 's';})
    $MetricC = [Metric]::New(@{Name = "Metric C"; Value = 0.014; UOM = 's'; DisplayFormat = "{value} is {unit}{name}"})
    $MetricD = [Metric]::New(@{Name = "Metric D"; Value = 0.014; UOM = 's';
                            DisplayFormat = "the custom name: {name} is {value}{unit}"; DisplayName = "Custom"})
    $MetricE = [Metric]::New(@{Name = "Metric E"; Value = 10000.52; UOM = 'B';
                        DisplayFormat = "the custom name: {name} is {value}{unit}";
                        DisplayName = "Custom"; SummaryPrecision = 3})
    $MetricF = [Metric]::New(@{Name = "Metric F"; Value = 10.5123405; UOM = 's';
                               DisplayFormat = "the custom name: {name} is {value}{unit}"; DisplayName = "Custom";
                               SummaryPrecision = 4})

    It "Should match the summary"{
        ($Metric.Summary | Should -Be "Metric is 1Kbps")
    }
    It "Should match the summary"{
        ($MetricA.Summary | Should -Be "Metric A is 1Kb")
    }
    It "Should match the summary"{
        ($MetricB.Summary | Should -Be "Metric B is 14ms")
    }
    It "Should match the summary when custom Display Format"{
        ($MetricC.Summary | Should -Be "14 is msMetric C")
    }
    It "Should match the summary when custom Display Format and Custom display name"{
        ($MetricD.Summary | Should -Be "the custom name: Custom is 14ms")
    }
    It "Should match the summary when custom specifying the pref decimal points"{
        ($MetricE.Summary | Should -Be "the custom name: Custom is 9.766KB")
    }
    It "Should match the summary when custom specifying the pref decimal points and no conversion possible"{
        ($MetricF.Summary | Should -Be "the custom name: Custom is 10.5123s")
    }
}

Describe 'CheckMetricPerfDataOutput'{

    $Metric = [Metric]::New(@{Name = "Metric"; Value = 1024; UOM = 'bps'; WarningThreshold = 1100; CriticalThreshold = 200000})
    $MetricA = [Metric]::New(@{Name = "Metric A"; Value = 1500; UOM = 'b'; WarningThreshold = 1100; CriticalThreshold = 200000})
    $MetricB = [Metric]::New(@{Name = "MetricB"; Value = 1500; UOM = 'b'; CriticalThreshold = 200000})
    $MetricC = [Metric]::New(@{Name = "MetricC"; Value = 1500; UOM = 's'; WarningThreshold = 1100;})
    $MetricD = [Metric]::New(@{Name = "MetricD"; Value = 1500; UOM = 'bps';})

    It "Should match the PerfData output"{
        ($Metric.PerfOutput | Should -Be "Metric=1024bps;1100;200000 ")
    }
    It "Should match the PerfData output when space in metric name"{
        ($MetricA.PerfOutput | Should -Be "'Metric A'=1500b;1100;200000 ")
    }
    It "Should match the PerfData output when no Warning"{
        ($MetricB.PerfOutput | Should -Be "MetricB=1500B;;200000 ")
    }
    It "Should match the PerfData output when no Warning"{
        ($MetricC.PerfOutput | Should -Be "MetricC=1500s;1100; ")
    }
    It "Should match the PerfData output when no thresholds"{
        ($MetricD.PerfOutput | Should -Be "MetricD=1500bps "   )
    }
}

Describe 'CheckExitCodes'{
    $Metric = [Metric]::New(@{Name = "Metric"; Value = 10; UOM = 'bps'; WarningThreshold = 15; CriticalThreshold = 20})
    $MetricWarn = [Metric]::New(@{Name = "Metric"; Value = 10; UOM = 'bps'; WarningThreshold = 5; CriticalThreshold = 20})
    $MetricCritical = [Metric]::New(@{Name = "Metric"; Value = 10; UOM = 'bps'; WarningThreshold = 5; CriticalThreshold = 5})

    $MetricA = [Metric]::New(@{Name = "Metric"; Value = 10000; UOM = 'bps'; WarningThreshold = '1Kbps'; CriticalThreshold = '100Mbps'})
    $MetricB = [Metric]::New(@{Name = "Metric"; Value = 1000000; UOM = 'B'; WarningThreshold = '1KB'; CriticalThreshold = '10KB'})

    It "Should return 0"{
        ($Metric.ExitCode | Should -Be 0)
    }
    It "Should return 1"{
        ($MetricWarn.ExitCode | Should -Be 1)
    }
    It "Should return 2"{
        ($MetricCritical.ExitCode | Should -Be 2)
    }
    It "Should return 1 when using UOM for thresholds"{
        ($MetricA.ExitCode | Should -Be 1)
    }
    It "Should return 2 when using UOM for thresholds"{
        ($MetricB.ExitCode | Should -Be 2)
    }
    It 'Should throw an InvalidMetricName exception'{
        $out = {
            $MetricC = [Metric]::New(@{Name = 'Metric'; Value = 10000; WarningThreshold = '1Kdd'})
        } | Should -Throw -PassThru
        $out.Exception.ErrorMessage | Should -Be "Invalid Threshold Syntax '1Kdd'. Unit '' doesn't match 'dd'"
    }
}

Describe 'Check ranges in threshold returning correct status'{

    $MetricOK = [Metric]::New(@{Name = "Metric"; Value = 17; UOM = 'b'; WarningThreshold = '15:20'; CriticalThreshold = 25})
    $MetricWarn = [Metric]::New(@{Name = "Metric"; Value = 21; UOM = 'b'; WarningThreshold = '15:20'; CriticalThreshold = 25})
    $MetricCrit = [Metric]::New(@{Name = "Metric"; Value = 17; UOM = 'b'; WarningThreshold = '15:20'; CriticalThreshold = '1:2'})
    $MetricOK2 = [Metric]::New(@{Name = "Metric"; Value = 92233720368547758; UOM = 'b'; WarningThreshold = '10:'})

    It "Should return OK when value is inside the range"{
        ($MetricOK.ExitCode | Should -Be 0)
    }
    It "Should return Warning when value is outside the range"{
        ($MetricWarn.ExitCode | Should -Be 1)
    }
    It "Should return Critical when value is outside the range"{
        ($MetricCrit.ExitCode | Should -Be 2)
    }
    It "Should return OK when range inf"{
        ($MetricOK2.ExitCode | Should -Be 0)
    }
}

Describe 'Check ~ in threshold returning correct status'{

    $MetricA = [Metric]::New(@{Name = "Metric"; Value = 1; WarningThreshold = '~:~';})
    $MetricB = [Metric]::New(@{Name = "Metric"; Value = 1; WarningThreshold = '10:~';})
    $MetricC = [Metric]::New(@{Name = "Metric"; Value = 5; WarningThreshold = '~:20';})
    $MetricD = [Metric]::New(@{Name = "Metric"; Value = 5; WarningThreshold = '~:';})
    $MetricE = [Metric]::New(@{Name = "Metric"; Value = 5; WarningThreshold = ':~';})

    It "Should return OK when inside range inf-inf"{
        ($MetricA.ExitCode | Should -Be 0)
    }
    It "Should return Warning when value is outside the range"{
        ($MetricB.ExitCode | Should -Be 1)
    }
    It "Should return OK when value is in range -inf : 20"{
        ($MetricC.ExitCode | Should -Be 0)
    }
    It "Should return OK when value is in range -inf : "{
        ($MetricD.ExitCode | Should -Be 0)
    }
    It "Should return OK when value is in range :~ "{
        ($MetricE.ExitCode | Should -Be 0)
    }
}

Describe 'Check @ in threshold returning correct status'{

    $MetricA = [Metric]::New(@{Name = "Metric"; Value = 1; WarningThreshold = '@10:20';})
    $MetricB = [Metric]::New(@{Name = "Metric"; Value = 10; WarningThreshold = '@5:15';})
    $MetricC = [Metric]::New(@{Name = "Metric"; Value = 1; WarningThreshold = '@20';})

    It "Should return OK when @ outside range 10:20"{
        ($MetricA.ExitCode | Should -Be 0)
    }
    It "Should return Warning when value is inside the range @"{
        ($MetricB.ExitCode | Should -Be 1)
    }
    It "Should return Warning when value less than 20"{
        ($MetricB.ExitCode | Should -Be 1)
    }
}

Describe 'Check that Check Class methods work as expected'{
    $Check = [Check]::New("Check","v1.0","Preamble","Description")
    $Check2 = [Check]::New("Check","v1.0","Preamble","Description","Metric")
    $Check3 = [Check]@{Name = "Check3";}

    $MetricA = [Metric]::New(@{Name = "Metric"; Value = 1024; UOM = 'bps'; WarningThreshold = '1100';
                                CriticalThreshold = '2000'})
    $Metric2A = [Metric]::New(@{Name = "Metric"; Value = 2000; UOM = 'B'; WarningThreshold = '100';
                                CriticalThreshold = '200'; SiBytesConversion = $true; DisplayInPerf = $false})
    $Metric2B = [Metric]::New(@{Name = "Metric"; Value = 1000; UOM = 's'; WarningThreshold = '100';
                                CriticalThreshold = '200'; SiBytesConversion = $true; DisplayInSummary = $false})

    $Metric3A = [Metric]::New(@{Name = "Metric"; Value = 2000; UOM = 'B'; WarningThreshold = '100';
                                CriticalThreshold = '200'; SiBytesConversion = $true; DisplayName = "Custom 0"})
    $Metric3B = [Metric]::New(@{Name = "Metric"; Value = 1000; UOM = 's'; WarningThreshold = '100';
                                CriticalThreshold = '200'; SiBytesConversion = $true; DisplayName = "Custom 1";
                                DisplayFormat= "{name} equals {value}{unit}"})

    It 'Should return the correct number of metrics'{
        $Check.AddMetricObj($MetricA)
        $Check.AddMetric(@{Name = "Metric"; Value = 0; UOM = 'b'; WarningThreshold = '1100';
                                CriticalThreshold = '200000'})
        ($Check.MetricArr.Count | Should -Be 2)
    }
    It 'Should return the correct output'{
        $Output = $Check.CreateOutput()
        $Expected = "METRIC is 1Kbps, Metric A is 1.46Kb | Metric=1024bps;1100;2000 'Metric A'=1500b;1100;200000 "

    }

    It 'Should return the correct output'{
        $Check2.AddMetricObj($Metric2A)
        $Check2.AddMetricObj($Metric2B)

        $Output = $Check2.CreateOutput()
        $Expected = "METRIC is 2KB | Metric=1000s;100;200 "
        ($Output | Should -Be $Expected)
    }

    It 'Should return the correct output'{
        $Check3.AddMetricObj($Metric3A)
        $Check3.AddMetricObj($Metric3B)

        $Output = $Check3.CreateOutput()
        $Expected = "Custom 0 is 2KB, Custom 1 equals 1000s | Metric=2000B;100;200 Metric=1000s;100;200 "
        ($Output | Should -Be $Expected)
    }

}

Describe 'Check that multiple metrics addition is supported'{
    $Check = [Check]@{Name = "Check"}
    $MetricA = [Metric]::New(@{Name = "Metric A"; Value = 0; UOM = 'b'; SiBytesConversion = $true})
    $MetricB = [Metric]::New(@{Name = "Metric B"; Value = 0.014; UOM = 's';})
    $MetricC = [Metric]::New(@{Name = "Metric"; Value = 1024; UOM = 'bps';})
    $MetricArr = ($MetricA, $MetricB, $MetricC)

    It 'Should return the correct number of metric objects'{
        $Check.AddMetricObj($MetricArr)
        ($Check.MetricArr.Count | Should -Be 3)
    }
}

Describe 'CheckCompleteOutput'{
    $Check = [Check]@{Name = "Check"}
    $MetricA = [Metric]::New(@{Name = "Metric"; Value = 1000; UOM = 'bps'; WarningThreshold = '1100'; CriticalThreshold = '2000'; SiBytesConversion =1 })
    $MetricB = [Metric]::New(@{Name = "Metric"; Value = 100; UOM = 's'; WarningThreshold = '50'; CriticalThreshold = '150'})
    $MetricC = [Metric]::New(@{Name = "Metric"; Value = 10000; UOM = 'B'; WarningThreshold = '500'; CriticalThreshold = '1000'})

    It 'Should return Metric OK'{
        $Check.AddMetricObj($MetricA)
        $Expected ="METRIC OK - Metric is 1Kbps | Metric=1000bps;1100;2000 "
        (Get-Final($Check) | Should -Be $Expected)
    }
    It 'Should return Metric Warning'{
        $Check.AddMetricObj($MetricB)
        $Expected ="METRIC WARNING - Metric is 1Kbps, Metric is 100s | Metric=1000bps;1100;2000 Metric=100s;50;150 "
        (Get-Final($Check) | Should -Be $Expected)
    }
    It 'Should return Metric Critical'{
        $Check = [Check]@{}
        $Check.AddMetricObj(@($MetricA, $MetricB, $MetricC))
        $Expected = "METRIC CRITICAL - Metric is 1Kbps, Metric is 100s, Metric is 9.77KB | Metric=1000bps;1100;2000 Metric=100s;50;150 Metric=10000B;500;1000 "
        (Get-Final($Check) | Should -Be $Expected)
    }
}

Describe 'CheckPrecision'{
    $Check = [Check]@{Name = "Check";}
    $MetricA = [Metric]::New(@{Name = "disk_usage"; Value = 30.55432; UOM = '%'; WarningThreshold = '50'; CriticalThreshold = '60';
                             DisplayName = "Disk Usage"; DisplayFormat = "{name} is {value}{unit}";
                             SummaryPrecision = 3; PerfDataPrecision = 4})

    It 'Should return the correct precision details'{
        $Check.addMetricObj($metricA)
        $Expected = "METRIC OK - Disk Usage is 30.554% | disk_usage=30.5543%;50;60 "
        (Get-Final($Check)  | Should -Be $Expected)
    }
}

Describe 'CheckSeparator'{
    $Check = [Check]@{Name = "Check"; Sep =" ++ "}
    $MetricA = [Metric]::New(@{Name = "disk_usage"; Value = 30.55432; UOM = '%'; WarningThreshold = '50'; CriticalThreshold = '60';
                             DisplayName = "Disk Usage";})
    $MetricB = [Metric]::New(@{Name = "latency"; Value = 0.002; UOM = '%'; WarningThreshold = '0.0007'; CriticalThreshold = '0.0009';
                             DisplayName = "Disk Usage";})
    It 'Should return the correct precision details'{
        $Check.addMetricObj(@($metricA,$metricB))
        $Expected = "METRIC CRITICAL - Disk Usage is 30.55% ++ Disk Usage is 0% | disk_usage=30.55%;50;60 latency=0%;0.0007;0.0009 "
        (Get-Final($Check) | Should -Be $Expected)

    }
}

Describe 'CheckInvalidThreshold'{
    $Check = [Check] @{ Name = "Check"}

    It 'Should throw an exception when threshold UOM not equals value UOM'{
        $out = {
            $Metric = [Metric]::New(@{Name = 'Metric'; Value = '10'; UOM = 'b'; WarningThreshold = '15KBps'})
        } | Should -Throw -PassThru
        $out.Exception.ErrorMessage | Should -Match "Invalid Threshold Syntax "
    }
}

Describe 'CheckCompleteOutputWhenNotConverting'{
    $Check = [Check] @{
        Name = "Check"
    }
    $Check.AddMetric(@{Name = "Metric"; Value = 10200; UOM = 'bps'; WarningThreshold = '1100'; CriticalThreshold = '2000'; ConvertMetric = 0})
    $Expected = "METRIC CRITICAL - Metric is 10200bps | Metric=10200bps;1100;2000 "
    It 'Should not convert the metric'{
        Get-Final($Check) | Should -be $Expected
    }
}

Describe 'Check Static methods'{
    $value = 10000
    $unit = 'b'
    $precision = 2
    $siBytesConversion = $false
    it 'Should convert the value without an object'{
        $converted = [Metric]::ConvertValue($value, $unit, $precision, $siBytesConversion)
        $converted.value | should -be 9.77
        $converted.UOM | Should -Be 'Kb'
    }

    it 'Should convert the threshold'{
        $converted = [Metric]::ConvertThreshold('10MB','B',$false)
        $converted | Should -Be 10485760
    }
}






