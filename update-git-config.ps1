# Prompt based Power Shell Script to update git config files

function Show-MultiSelectMenu {
    param(
        [string[]]$options,
        [string]$prompt
    )

    $selectedOptions = @()

    $options | ForEach-Object {
        $index = [array]::IndexOf($options, $_) + 1
        Write-Host "$index. $_"
    }

    Write-Host "`n$prompt (Separate multiple choices with commas, e.g., 1,3):"
    $input = Read-Host

    if ($input) {
        $selectedIndexes = $input.Split(',') | ForEach-Object { $_.Trim() }

        foreach ($index in $selectedIndexes) {
            if ($index -gt 0 -and $index -le $options.Length) {
                $selectedOptions += $options[$index - 1]
            } else {
                throw "Invalid selection: $index. Please select a valid option."
            }
        }
    }

    return $selectedOptions
}

try {

    $existingUserName = git config --global user.name 2>$null
    $existingEmail = git config --global user.email 2>$null


    $options = @(
        "User Name (Current: $existingUserName)",
        "Email (Current: $existingEmail)",
        "Password"
    )

    $selectedOptions = Show-MultiSelectMenu -options $options -prompt "Select the Git configuration items you want to update"

    if ($selectedOptions.Count -eq 0) {
        Write-Host "No items selected. Exiting..." -ForegroundColor Red
        exit
    }

    $updates = @{}

    if ($selectedOptions -contains "User Name (Current: $existingUserName)") {
        $userName = Read-Host -Prompt "Enter Git user name (Leave blank to keep '$existingUserName')"
        if ([string]::IsNullOrWhiteSpace($userName)) {
            $userName = $existingUserName
        }
        $updates["User Name"] = $userName
    }
    if ($selectedOptions -contains "Email (Current: $existingEmail)") {
        $userEmail = Read-Host -Prompt "Enter Git email address (Leave blank to keep '$existingEmail')"
        if ([string]::IsNullOrWhiteSpace($userEmail)) {
            $userEmail = $existingEmail
        }
        $updates["Email"] = $userEmail
    }
    if ($selectedOptions -contains "Password") {
        $userPassword = Read-Host -Prompt "Enter Git password"
        $updates["Password"] = "(hidden)"
    }

    if ($updates.Count -gt 0) {
        Write-Host "`nYou have selected to update the following details:" -ForegroundColor Yellow
        foreach ($key in $updates.Keys) {
            Write-Host "$($key): $($updates[$key])"
        }
        Write-Host "`nDo you want to save these changes? (yes/no)" -ForegroundColor Cyan
        $confirmation = Read-Host -Prompt "Enter 'yes' to save, or 'no' to cancel"

        if ($confirmation -eq "yes") {
            Write-Host "Saving changes..." -ForegroundColor Green
            if ($updates.ContainsKey("User Name")) {
                git config --global user.name "$userName"
            }
            if ($updates.ContainsKey("Email")) {
                git config --global user.email "$userEmail"
            }
            if ($updates.ContainsKey("Password")) {
                git config --global user.password "$userPassword"
            }
            git config --global credential.helper store

            Write-Host "Git configuration updated successfully!" -ForegroundColor Green
        } elseif ($confirmation -eq "no") {
            Write-Host "No changes were made. Exiting..." -ForegroundColor Red
        } {
            Write-Host "Invalid option!, No changes were made. Exiting..." -ForegroundColor Red
        }
    } else {
        Write-Host "No items selected for update. Exiting..." -ForegroundColor Red
    }

} catch {
    Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Exiting the program..." -ForegroundColor Red
    exit 1
}
