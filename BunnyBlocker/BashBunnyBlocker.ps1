#############################################
#             bash bunny boiler
#############################################
# Will need to be run as admin to be able to disable/enable devices

# Used for input box
Add-Type -AssemblyName Microsoft.VisualBasic

#list of current keyboards
[System.Collections.Generic.list[string]]$allowed = (Get-PnpDevice -PresentOnly -Class "HIDClass","Keyboard").InstanceId
#test remove second item
#$allowed.Remove($allowed[1])

Start-Sleep -Seconds 1
# Look for new devices
While ($True)
{
    # get devices that are not in the allowed list
    $newDevs = ((Get-PnpDevice -PresentOnly -Class "HIDClass","Keyboard") | Where-Object -NotIn -Property InstanceId -Value $allowed).InstanceId
    if ($newDevs) { 
        #Disable each device
        ForEach ($item in $newDevs) {
            #Disable-PnpDevice -Confirm:$false -InstanceID $item
            Get-PnpDevice -InstanceID $item | Disable-PnpDevice -Confirm:$false
            Write-Output $item
        }
        # gen a 10 char alpha string
        $key= -join ((65..90) + (97..122) | Get-Random -Count 10 | % {[char]$_})
        # input dialog box
        $title = 'Real Keyboard?'
        $msg = 'Enter the Key to active new keyboard: ' + $key;
        # Test: Key
        Write-Output $key
        $text = [Microsoft.VisualBasic.Interaction]::InputBox($msg, $title)
        # Check entered text
        if($text -eq $key)
        {
            Write-Output 'Correct'
            #Enable each device
            ForEach ($item in $newDevs) {
                Get-PnpDevice -InstanceID $item | Enable-PnpDevice -Confirm:$false
	            #Enable-PnpDevice -Confirm:$false -InstanceID $item
                $allowed.Add($item);
            }
        }
        else
        {
            Write-Output 'Incorrect'
        }
    }
    Start-Sleep -Seconds 1 
}