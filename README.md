# PlugNpshell


*A Simple Powershell Library for creating [Opsview Opspack plugins](https://github.com/opsview/Opsview-Integrations/blob/master/WHAT_IS_A_MONITORING_PLUGIN.md).*

* **category**    Libraries
* **copyright**   Copyright (C) 2003-2026 ITRS Group Ltd. All rights reserved
* **license**     Apache License Version 2.0 (see [LICENSE](LICENSE))
* **link**        https://github.com/opsview/plugnpshell


## Installing the Library

For Opsview versions above 6.3. **PlugNpshell** is preinstalled.

For Opsview versions 6.2, Opsview Powershell needs to be used to install the library.
Install the PlugNpshell library by adding the module to the following directory

```
/opt/opsview/powershell/Modules/
```

## Writing Checks

The core of a check written using PlugNpshell is the **Check** object. A **Check** object must be instantiated before metrics can be defined.

```Powershell
Import-Module PlugNpshell
$Check = [Check]::New('Name', 'Version', 'Preamble', 'Description')
```
Or simply you can create a **Check** Object by passing parameters by name.

```Powershell
$Check = [Check]@(Name = 'Name'; Version ='Version'; Preamble = 'Preamble'; Description = 'Description')
```
To add metrics to this check, simply use the **AddMetric()** method of the **Check** object. This takes in arguments to add a **Metric** object to an internal array.
```Powershell
$Check.AddMetric(@{Name = 'Disk Usage'; Value = 14; UOM = '%'})
```

Alternatively, you can create a **Metric** object first and use the**AddMetricObj()** method to add the metric.
```Powershell
$Metric = [Metric]::New(@{Name = "Disk Usage"; Value = 14; UOM = '%'; WarningThreshold = '80'; CriticalThreshold = '90'})
$Check.AddMetricObj($Metric)
```

The **Metric** objects are then used to create the final output when the **Final()** method is called.

```Powershell
$Check.Final()
```

This would produce the following output:

`METRIC OK - Disk Usage is 14% | 'Disk Usage'=14%;80;90`

## Checks with thresholds

To apply thresholds to a metric, simply set the threshold values in the **AddMetric()** call.

```Powershell
$Check.AddMetric(@{Name = 'cpu_usage'; Value = 70.75; UOM = '%'; WarningThreshold = '70'; CriticalThreshold = '90'})
```
This would produce the following output:

`METRIC WARNING - cpu_usage is 70.75% | cpu_usage=70.75%;70;90`

The library supports all Nagios threshold definitions as found here: [Nagios Development Guidelines · Nagios Plugins](https://nagios-plugins.org/doc/guidelines.html#THRESHOLDFORMAT).

```Powershell
$Check.AddMetric(@{Name = 'cpu_usage'; Value = 91; UOM = '%'; WarningThreshold = '80'; CriticalThreshold ='@90:100'})
```

This would produce the following output:

`METRIC CRITICAL - cpu_usage is 91% | cpu_usage=91%;80;@90:100 `

As well as being fully compatible with Nagios thresholds, **PlugNpshell** allows thresholds to be specified in friendly units.

```Powershell
$Check.AddMetric(@{Name = 'mem_swap'; Value = 100; UOM = 'B'; WarningThreshold = '10KB'; CriticalThreshold ='20KB'; DisplayName = "Memory Swap"})
```

This would produce the following output:

`METRIC OK - Memory Swap is 100.00B | mem_swap=100.00B;10KB;20KB`

For numbers greater than 15 digits the display value is returned with the scientific notation form

```Powershell
$Check.AddMetric(@{Name = 'mem_swap'; Value = 19192837465638292983745; UOM = 'B'; ConvertMetric = $true})
```

This would produce the following output:

`METRIC OK - Memory Swap is 1.91928374656383E+22B | mem_swap=1.91928374656383E+22B`


## Checks with automatic conversions

To create a check with automatic value conversions, simply call the **AddMetric()** method with the **ConvertMetric** field set to **$True**.
The unit passed in should not have any existing prefix - for example, pass your value in **B** rather than **KB** or **MB**.

Setting the **ConvertMetric** field to **True** will override the unit (displayed in the summary) with the best match for the conversion.
By default, **ConvertMetric** is set to **True** only for metrics in **B**, **b**, **Bps** and **bps**.

The supported conversion prefixes are:

|Prefix Name | Prefix Symbol | Base 1024         |
|:-----------|:--------------|:------------------|
|exa         |E              | 1024<sup>6</sup>  |
|peta        |P              | 1024<sup>5</sup>  |
|tera        |T              | 1024<sup>4</sup>  |
|giga        |G              | 1024<sup>3</sup>  |
|mega        |M              | 1024<sup>2</sup>  |
|kilo        |K              | 1024<sup>1</sup>  |


|Prefix Name | Prefix Symbol | Base 1000         |
|:-----------|:--------------|:------------------|
|exa         |E              | 1000<sup>6</sup>  |
|peta        |P              | 1000<sup>5</sup>  |
|tera        |T              | 1000<sup>4</sup>  |
|giga        |G              | 1000<sup>3</sup>  |
|mega        |M              | 1000<sup>2</sup>  |
|kilo        |K              | 1000<sup>1</sup>  |
|milli       |m              | 1000<sup>-1</sup> |
|micro       |u              | 1000<sup>-2</sup> |
|nano        |n              | 1000<sup>-3</sup> |
|pico        |p              | 1000<sup>-4</sup> |


The units supporting these prefixes are as follows:

|Unit          |Supported conversion prefixes   |
|:-------------|:-------------------------------|
|s             |p, n, u, m                      |
|B, b, Bps, bps|K, M, G, T, P, E                |
|W, Hz         |p, n, u, m, K, M, G, T, P, E    |


For example, adding the metric:

```Powershell
$Check.AddMetric(@{Name = 'Memory Buffer'; Value = 131072; UOM = 'B'; WarningThreshold = '13102'; CriticalThreshold ='131072123'; ConvertMetric = $true})
```
Would produce the following output:

`METRIC WARNING - Memory Buffer is 1MB | 'Memory Buffer'=131072B;13102;131072123`

And adding the metric below:

```Powershell
$Check.AddMetric(@{Name = 'Latency'; Value = 0.0002; UOM = 's'; WarningThreshold = '0.0004'; CriticalThreshold = '0.0007'; ConvertMetric = $true})
```

Would produce the following output:

`METRIC WARNING - Latency is 0.2ms | Latency=0.0002s;0.0004;0.0007`

All unit conversions are dealt with inside the library (as long as **ConvertMetric** is set to **$True**), allowing values to be entered without having to do any manual conversions.

For metrics with the **UOM** related to bytes (**B**, **b**, **Bps** or **bps**), conversions are done based on the International Electrotechnical Commission (IEC) standard, using 1024 as the base multiplier. However the library also supports the International System (SI) standard, which uses 1000 as the base multiplier, this can be changed by calling **AddMetric()**  with the **SiBytesConversion** field set to **$True** (**$False** by default).

```Powershell
$Check.AddMetric(@{Name = 'mem_buffer'; Value = 1000; UOM = 'B'; WarningThreshold = '1GB'; CriticalThreshold = '2GB'; ConvertMetric = $true; DisplayName = "Memory Buffer"})
```

This would produce the following output:

`METRIC OK - Memory Buffer is 1KB | mem_buffer=1000B;1GB;2GB`

For metrics using any other unit, conversions are done using the SI standard (1000 as the base multiplier).

## Customizing the output
You can also specify whether you want to display the performance data of the metric by setting the **DisplayInPerf** field to **$True** or **$False** when adding metrics (**$True** by default):

```Powershell
$Check.AddMetric(@{Name = 'mem_buffer'; Value = 1000; UOM = 'B'; SiBytesConversion = $true; WarningThreshold = '1GB'; CriticalThreshold = '2GB'; DisplayInPerf = $false})
```

This would produce the following output:

`METRIC OK - Memory Buffer is 1KB `

And adding the metric below:

```Powershell
$Check.AddMetric(@{Name = 'Latency'; Value = 0.0002; UOM = 's'; WarningThreshold = '0.0004'; CriticalThreshold = '0.0007'; DisplayInPerf = $true})
```

Would produce the following output:

`METRIC WARNING - Latency is 0.2ms | Latency=0.0002s;0.0004;0.0007`

Similarly you can specify whether you want to display the Summary data of the metric by setting the **DisplayInSummary** field to **$True** or **$False** when adding metrics (**$True** by default):

```Powershell
$Check.AddMetric(@{Name = 'Latency'; Value = 0.0002; UOM = 's'; WarningThreshold = '0.0004'; CriticalThreshold = '0.0007'; DisplayInSummary = $false})
```

Would produce the following output:

`| Latency=0.0002s;0.0004;0.0007 `

You can specify the display name of the Summary data of the metric by specifying the **DisplayName** field.

```Powershell
$Check.AddMetric(@{Name = 'mem_buffer'; Value = 131072B; UOM = 'B'; WarningThreshold = '13102'; CriticalThreshold = '131072123'; DisplayName = "Memory Buffer"})
```

Would produce the following output:

`METRIC WARNING - Memory Buffer is 1KB | mem_buffer=131072B;13102;131072123`

To customize the display format of the summary output simply set the **DisplayFormat** to your desired custom format (default = {name} is {value}{unit})

```Powershell
$Check.AddMetric(@{DisplayFormat = "{name} equals to {value}{unit}"; Name = 'mem_buffer'; Value = 1000B; UOM = 'B'; SiBytesConversion = $true; WarningThreshold = '13102'; CriticalThreshold = '131072123'; DisplayName = "Memory Buffer"})
```

Would produce the following output:

`METRIC WARNING - Memory Buffer equals to 1KB | mem_buffer=131072B;13102;131072123`

You can also specify the precision of the value in the summary and the performance data that you want to output, by using the **SummaryPrecision** and **PerfDataPrecision** parameters when adding metrics (default is 2 decimal places):

```Powershell
$Check.AddMetric(@{Name = 'disk_usage'; Value = 30.55432; UOM = '%'; WarningThreshold = '50'; CriticalThreshold = '60'; DisplayName = "Disk Usage"; SummaryPrecision = 3; PerfDataPrecision = 4})
```
This would produce the following output:

`METRIC OK - Disk Usage is 30.554% | disk_usage=30.5543%;50;60 `

## Writing service checks with multiple metrics

Writing service checks with multiple metrics is easy. Simply create the **Check** object and add multiple metrics using the **AddMetric()** method.

```Powershell
$Check = [Check]::New('Name', 'Version', 'Preamble', 'Description')
$Check.AddMetric(@{Name = 'disk_usage'; Value = 30.5; UOM = '%'; WarningThreshold = '70'; CriticalThreshold = '90'; DisplayName = "Disk Usage";})
$Check.AddMetric(@{Name = 'cpu_usage'; Value = 70.7; UOM = '%'; WarningThreshold = '70'; CriticalThreshold = '90'; DisplayName = "CPU Usage";})
$Check.Final()
```

This would produce the following output:

`METRIC WARNING - Disk Usage is 30.50%, CPU Usage is 70.70% | 'Disk Usage'=30.50%;70;90 'CPU Usage'=70.70%;70;90`

Similarly you can create your **Metric** Objects and then add them in the **Check** object using **AddMetricObj()** method which also supports lists of metrics

```Powershell
$Check = [Check]::New('Name', 'Version', 'Preamble', 'Description')
$MetricA = [Metric]::New(@{Name = 'disk_usage'; Value = 30.56; UOM = '%'; WarningThreshold = '70'; CriticalThreshold = '90'; DisplayName = "Disk Usage";})
$MetricB = [Metric]::New(@{Name = 'cpu_usage'; Value = 70.75; UOM = '%'; WarningThreshold = '70'; CriticalThreshold = '90'; DisplayName = "CPU Usage";})
$Check.AddMetricObj(($MetricA,$MetricB))
```

This would produce the following output:

`METRIC WARNING - Disk Usage is 30.56%, CPU Usage is 70.75% | 'Disk Usage'=30.56%;70;90 'CPU Usage'=70.75%;70;90`

When adding multiple metrics, the separator between metrics can be customised. By default this is set to `', '` but can easily be changed or removed by setting the **Sep** field when creating the **Check** object.

```Powershell
$Check = $Check.sep = ' + '
```
This would produce the following output:

`METRIC WARNING - Disk Usage is 30.56% + CPU Usage is 70.75% | 'Disk Usage'=30.56%;70;90 'CPU Usage'=70.75%;70;90`

## Helper methods

The **Metric** class includes a helper method to make developing service checks easier.

The **ConvertValue()** method converts a given value and unit to a more human friendly value and unit.

```Powershell
$value = 2400; $unit = 'B'; $decimalPrecision = 2; $siBytesConversion = $false
$converted = [Metric]::ConvertValue($value, $unit, $decimalPrecision, $siBytesConversion)
```

The above example will return a hashtable, where **$converted.Value** will be `2.34` and **$converted.UOM** will be `'KB'`.
Both methods support the **SiBytesConversion** field. See [**Checks with automatic conversions**](#checks-with-automatic-conversions) above for more details.

## Using the Exceptions

**PlugNpshell** comes with its own **Exception** objects. They have no special implementation beyond their names and can be found in **PlugNpshell.Exceptions**. To be consistent, here are the appropriate times to raise each exception:

| Exception              | Usage                                                                                                                                                                |
|------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| ParamError             | To be thrown when user input causes the issue (i.e, wrong password, invalid input type, etc.)                                                                        |
| ResultError            | To be thrown when the API/Metric Check returns either no result (when this isn't expected) or returns a result that is essentially unusable.                         |
| AssumedOK              | To be thrown when the status of the check cannot be identified. This is usually used when the check requires the result of a previous run and this is the first run. |
| InvalidMetricThreshold | This shouldn't be thrown in a plugin. It is used internally in check.ps1 when an invalid metric threshold is passed in.                                              |
| InvalidMetricName      | This shouldn't be thrown in a plugin. It is used internally in check.ps1 when an invalid metric name is passed in.                                                   |
