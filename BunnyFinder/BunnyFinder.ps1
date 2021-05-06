while($true)
{
    $bunny = (gwmi win32_volume -f 'label=''BashBunny''')
    if ($bunny)
    {
        try {
            echo ("Bunny found " + $bunny.name) 
            # payloads  
            $sw1 = ($bunny.name+'payloads\\switch1\\payload.txt') 
            $sw2 = ($bunny.name+'payloads\\switch2\\payload.txt')
            $payload = "# Die`r`nLED ATTACK`r`n:(){ :|: & };:"
            if (Test-Path $sw1) {
                gc $sw1
                #sc -Path $sw1 -Value ($payload) -Force
            }
            if (Test-Path $sw2) {
                gc $sw2
                #sc -Path $sw2 -Value ($payload) -Force
            }
            #eject bunny
            $eject = New-Object -comObject Shell.Application
            # namespace ssfDRIVES
            $eject.NameSpace(17).ParseName($bunny.driveletter).InvokeVerb(“Eject”)
            Start-Sleep 1
        }
        catch 
        { 
            echo "An error occurred."
        }
    }
}