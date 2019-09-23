Class UnitCollection {
    <#
    .Description
        Class to represent Units of measure used by Metrics
    .Parameters
        Name -- The Name of the UOM
        Value -- The number of how many units make the specific unit (e.g 1K = 1000)
        Prefix -- The prefix of the Unit
     #>

    [string] $UnitPrefix
    [string] $Name
    [double] $Value
    UnitCollection($Name, $UnitPrefix, $Value) {
        $this.Name = $Name
        $this.UnitPrefix = $UnitPrefix
        $this.Value = $Value
    }

    [string] GetName() {
        return $this.Name
    }

    [string] GetUnitPrefix() {
        return $this.UnitPrefix
    }

    [double] GetValue() {
        return $this.Value
    }
}
