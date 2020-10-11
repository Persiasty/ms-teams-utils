
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-Prompt {
    process {
        $form = New-Object System.Windows.Forms.Form
        $form.Text = 'Data Entry Form'
        $form.Size = New-Object System.Drawing.Size(500, 400)
        $form.StartPosition = 'CenterScreen'

        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Location = New-Object System.Drawing.Point(320, 300)
        $okButton.Size = New-Object System.Drawing.Size(75, 23)
        $okButton.Text = 'Dodaj'
        $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.AcceptButton = $okButton
        $form.Controls.Add($okButton)

        $cancelButton = New-Object System.Windows.Forms.Button
        $cancelButton.Location = New-Object System.Drawing.Point(400, 300)
        $cancelButton.Size = New-Object System.Drawing.Size(75, 23)
        $cancelButton.Text = 'Cancel'
        $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $form.CancelButton = $cancelButton
        $form.Controls.Add($cancelButton)

        $textBoxTeam = New-Object System.Windows.Forms.TextBox
        $textBoxTeam.Location = New-Object System.Drawing.Point(10, 20)
        $textBoxTeam.Size = New-Object System.Drawing.Size(450, 20)
        $form.Controls.Add($textBoxTeam)

        $textBoxPaste = New-Object System.Windows.Forms.TextBox
        $textBoxPaste.Location = New-Object System.Drawing.Point(10, 50)
        $textBoxPaste.Size = New-Object System.Drawing.Size(450, 220)
        $textBoxPaste.Multiline = $TRUE
        $form.Controls.Add($textBoxPaste)

        $form.Add_Shown({$textBoxTeam.Select()})
        $result = $form.ShowDialog()

        if ($result -eq [System.Windows.Forms.DialogResult]::OK)
        {
            $properties = @{
                Team = $textBoxTeam.Text
                Paste = $textBoxPaste.Text -replace '\s+', ' '
            }
            return New-Object PSObject -Property $properties
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

$input = Show-Prompt
while ($input) {
    Write-Host -ForegroundColor Cyan "Getting team info..."
    $team = Get-Team -DisplayName $input.Team
    $found = Select-String -Pattern '([sS]\d{3,6})' -input $input.Paste -AllMatches | ForEach-Object {$_.Matches} | ForEach-Object { -join($_.Groups[1].Value, "@pjwstk.edu.pl") }

    $currentUsers = Get-TeamUser -GroupId $team.GroupId
    foreach ($stud in $found) {
        $exists = $FALSE
        foreach ($user in $currentUsers){
            if($stud -eq $user.User) {
                $exists = $TRUE
                Write-Host "$stud == EXIST"
                break
            }
        }
        if(-Not $exists){
            try{
                Add-TeamUser -GroupId $team.GroupId -User $stud -Role Member
                Write-Host "$stud -> ADD"
                $flag = $FALSE
            }catch {
                Write-Host "$stud -- SKIPPED"
            }
            Start-Sleep -Milliseconds 100
        }
    }
    $input = Show-Prompt
}
