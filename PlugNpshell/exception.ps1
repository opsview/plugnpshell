class ParamError: System.Exception {
    # To be thrown when user input causes the issue
    [string] $ErrorMessage
    ParamError([string]$Message) {
        $this.ErrorMessage = $Message
    }
}

class ResultError: System.Exception {
    # To be thrown when the API/Metric Check returns either no result (when this isn't expected)
    # or returns a result that is essentially unusable.
    [string] $Errormessage
    ResultError([string]$Message) {
        $this.ErrorMessage = $Message
    }
}

class AssumedOK: System.Exception {
    # To be thrown when the status of the check cannot be identified.
    # This is usually used when the check requires the result of a previous run and this is the first run.
    [string] $ErrorMessage
    AssumedOK([string]$Message) {
        $this.ErrorMessage = $Message
    }
}

class InvalidMetricThreshold: System.Exception {
    # To be thrown when you pass a metric threshold with wrong syntax
    [string] $ErrorMessage
    InvalidMetricThreshold([string]$Message) {
        $this.ErrorMessage = $Message
    }
}

class InvalidMetricName: System.Exception {
    # To be thrown when you pass an invalid metric name.
    [string] $ErrorMessage
    InvalidMetricName([string]$Message) {
        $this.ErrorMessage = $Message
    }
}
