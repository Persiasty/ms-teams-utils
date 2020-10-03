function Get-TeamChannelCreated {
    [OutputType([bool])]
    param (
        [Parameter(Mandatory)]
        [string]
        $GroupId,
        [Parameter(Mandatory)]
        [string]
        $ChannelName
    )
    process {
        $channels = Get-TeamChannel -GroupId $GroupId
        $flag = $FALSE
        foreach ($channel in $channels) {
            if ($channel.DisplayName -eq $ChannelName) {
                $flag = $TRUE
            }
        }
        return $flag
    }
}

function New-TeamChannelUser {
    param (
        [Parameter(Mandatory)]
        [string]
        $ChannelName,
        [Parameter(Mandatory)]
        [System.Object]
        $User
    )
    process {
        $userName = $User.Name
        Write-Host -ForegroundColor Cyan "+ Adding user: $userName"
        $flag = $TRUE
        while ($flag) {
            try {
                Add-TeamChannelUser -GroupId $GroupId -DisplayName $channelName -User $User.User -erroraction 'silentlycontinue'
                Write-Host -ForegroundColor Green "OK"
                $flag = $FALSE
            } catch {
                # no-op
            }
            Start-Sleep -Milliseconds 100
        }
    }
}

function New-TeamChannelWithUser {
    param (
        [Parameter(Mandatory)]
        [string]
        $GroupId,
        [Parameter(Mandatory)]
        [System.Object]
        $User
    )
    process {
        try {
            $channelName = -join($User.Name, " - ", $User.User.Split("@")[0])
            Write-Host -ForegroundColor Cyan "Creating channel: $channelName"
            New-TeamChannel -GroupId $GroupId -DisplayName $channelName -MembershipType Private -erroraction 'silentlycontinue'
            do {
                Start-Sleep -Milliseconds 500
                $Created = Get-TeamChannelCreated -GroupId $GroupId -ChannelName $channelName
            } while ($Created -ne $TRUE)
            Write-Host -ForegroundColor Green "OK"
            
            New-TeamChannelUser -ChannelName $channelName -User $User
        } catch {
            Write-Host -ForegroundColor Red "Error occured: $_"
        }
    }
}

Write-Host -ForegroundColor Cyan "Getting credentials..."
$credential = Get-Credential
Write-Host -ForegroundColor Green "OK"

Write-Host -ForegroundColor Cyan "Logging in..."
Connect-MicrosoftTeams -Credential $credential
Write-Host -ForegroundColor Green "OK"
Start-Sleep -Milliseconds 500

foreach ($Team in $args) {
    Write-Host -ForegroundColor Cyan "Getting team $Team GroupId..."
    $team = Get-Team -DisplayName $Team
    Write-Host -ForegroundColor Green "OK"
    Start-Sleep -Milliseconds 100
    
    Write-Host -ForegroundColor Cyan "Getting team members..."
    $users = Get-TeamUser -GroupId $team.GroupId -Role member
    Write-Host -ForegroundColor Green "OK"
    Start-Sleep -Milliseconds 100
    
    foreach ($user in $users) {
        New-TeamChannelWithUser -GroupId $team.GroupId -User $user
    }
}
