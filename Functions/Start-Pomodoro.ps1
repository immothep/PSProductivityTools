#By MVP Ståle Hansen (http://msunified.net) with modifications by Jan Egil Ring
#Pomodoro function by Nathan.Run() http://nathanhoneycutt.net/blog/a-pomodoro-timer-in-powershell/
#Lync Custom states by Jan Egil Ring http://blog.powershell.no/2013/08/08/automating-microsoft-lync-using-windows-powershell/
#Note: for desktops you need to enable presentation settings in order to suppress email alerts, by MVP Robert Sparnaaij: https://msunified.net/2013/11/25/lock-down-your-lync-status-and-pc-notifications-using-powershell/

Function Start-Pomodoro {
    [CmdletBinding()]
    Param (
        #Duration of your Pomodoro Session
        [int]$Minutes = 25,
        [string]$AudioFilePath,
        [switch]$StartMusic,
        [string]$EndPersonalNote = ' ',
        [string]$IFTTMuteTrigger, #your_IFTTT_maker_mute_trigger
        [string]$IFTTUnMuteTrigger, #your_IFTTT_maker_unmute_trigger
        [string]$IFTTWebhookKey, #your_IFTTT_webhook_key
        [string]$StartNotificationSound = "C:\Windows\Media\Windows Proximity Connection.wav",
        [string]$EndNotificationSound = "C:\Windows\Media\Windows Proximity Notification.wav"
    )
      
 
    if ($StartMusic) {

        if ($PSBoundParameters.ContainsKey('AudioFilePath')) {

            if (Test-Path -Path $AudioFilePath) {

                # Invoke item if it is a file, else pick a random file from the folder (intended for folders containing audio files)
                if ((Get-Item -Path $AudioFilePath).PsIsContainer) {

                    $AudioFile = Get-ChildItem -Path $AudioFilePath -File | Get-Random
                    $AudioFile | Invoke-Item
                    
                    Write-Host "Started audio file $($AudioFile.FullName)" -ForegroundColor Green

                } else {

                    Invoke-Item -Path $AudioFilePath

                    Write-Host "Started audio file $AudioFilePath" -ForegroundColor Green

                }

            } else 

            {

                Write-Host "AudioFilePath $AudioFilePath does not exist, no music invoked"

            }

        } else {

            Write-Host 'AudioFilePath not specified, no music invoked'

        }

    }
  
    $PersonalNote = "Getting stuff done, will be available at $(Get-Date $((Get-Date).AddMinutes($Minutes)) -Format HH:mm)"
  
    #Set do-not-disturb Pomodoro Foucs custom presence, where 1 is my pomodoro custom presence state
    Publish-SfBContactInformation -CustomActivityId 1 -PersonalNote $PersonalNote

    Write-Host -Object "Updated Skype for Business client status to custom activity 1 (Pomodoro Sprint) and personal note: $PersonalNote" -ForegroundColor Green
  
    #Setting computer to presentation mode, will suppress most types of popups
    presentationsettings /start

    #Turn off Vibration and mute Phone using IFTTT
    if ($IFTTMuteTrigger -ne '' -and $IFTTWebhookKey -ne ''){Invoke-RestMethod -Uri https://maker.IFTTT.com/trigger/$IFTTMuteTrigger/with/key/$IFTTWebhookKey -Method POST}
  
    if (Test-Path -Path $StartNotificationSound) {
     
    $player = New-Object System.Media.SoundPlayer $StartNotificationSound -ErrorAction SilentlyContinue
     1..2 | ForEach-Object { 
         $player.Play()
        Start-Sleep -m 3400 
    }
    }
  
    #Counting down to end of Pomodoro
    $seconds = $Minutes * 60
    $delay = 1 #seconds between ticks
    for ($i = $seconds; $i -gt 0; $i = $i - $delay) {
        $percentComplete = 100 - (($i / $seconds) * 100)
        Write-Progress -SecondsRemaining $i `
            -Activity "Pomodoro Focus sessions" `
            -Status "Time remaining:" `
            -PercentComplete $percentComplete
        if ($i -lt 16){Publish-SfBContactInformation -PersonalNote "Getting stuff done, will be available in $i seconds"}
        Start-Sleep -Seconds $delay
    }
  
    #Stopping presentation mode to re-enable outlook popups and other notifications
    presentationsettings /stop
    #Turn vibration on android phone back on using IFTTT
    if ($IFTTUnMuteTrigger -ne '' -and $IFTTWebhookKey -ne ''){Invoke-RestMethod -Uri https://maker.IFTTT.com/trigger/$IFTTUnMuteTrigger/with/key/$IFTTWebhookKey -Method POST}

    #Pomodoro session finished, resetting status and personal note, availability 1 will reset the Lync status
    Publish-SfBContactInformation -PersonalNote $EndPersonalNote
    Publish-SfBContactInformation -Availability Available 

    if (Test-Path -Path $EndNotificationSound) {

    #Playing end of focus session notification
    $player = New-Object System.Media.SoundPlayer $EndNotificationSound -ErrorAction SilentlyContinue
     1..2 | ForEach-Object {
         $player.Play()
        Start-Sleep -m 1400 
    }

    }
  
    if ($EndPersonalNote -ne ' '){Write-Host -Object "Pomodoro sprint session ended, set status: Available and personal note: $EndPersonalNote" -ForegroundColor Green}
    else {Write-Host -Object "Pomodoro sprint session ended, set status: Available and personal note: blank" -ForegroundColor Green}

}
