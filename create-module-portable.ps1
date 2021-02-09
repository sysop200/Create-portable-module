function Initialize-ModulePortable {
    [CmdletBinding()]
    param(
        [alias('ModuleName')][string] $Name,
        [string] $Path = $PSScriptRoot,
        [switch] $Download,
        [switch] $Import
    )
    function Get-RequiredModule {
        param(
            [string] $Path,
            [string] $Name
        )
        $PrimaryModule = Get-ChildItem -LiteralPath "$Path\$Name" -Filter '*.psd1' -Recurse -ErrorAction SilentlyContinue -Depth 1
        if ($PrimaryModule) {
            $Module = Get-Module -ListAvailable $PrimaryModule.FullName -ErrorAction SilentlyContinue -Verbose:$false
            if ($Module) {
                [Array] $RequiredModules = $Module.RequiredModules.Name
                if ($null -ne $RequiredModules) {
                    $null
                }
                $RequiredModules
                foreach ($_ in $RequiredModules) {
                    Get-RequiredModule -Path $Path -Name $_
                }
            }
        } else {
            Write-Warning "Initialize-ModulePortable - Модули $Name для загрузки не найдены в $Path"
        }
    }

    if (-not $Name) {
        Write-Warning "Initialize-ModulePortable - Имя модуля не указано. Завершение операции."
        return
    }
    if (-not $Download -and -not $Import) {
        Write-Warning "Initialize-ModulePortable - Укажите ключ Download или Import. Завершение операции."
        return
    }

    if ($Download) {
        try {
            if (-not $Path -or -not (Test-Path -LiteralPath $Path)) {
                $null = New-Item -ItemType Directory -Path $Path -Force
            }
            Save-Module -Name $Name -LiteralPath $Path -WarningVariable WarningData -WarningAction SilentlyContinue -ErrorAction Stop
        } catch {
            $ErrorMessage = $_.Exception.Message

            if ($WarningData) {
                Write-Warning "Initialize-ModulePortable - $WarningData"
            }
            Write-Warning "Initialize-ModulePortable - Ошибка $ErrorMessage"
            return
        }
    }

    if ($Download -or $Import) {
        [Array] $Modules = Get-RequiredModule -Path $Path -Name $Name | Where-Object { $null -ne $_ }
        if ($null -ne $Modules) {
            [array]::Reverse($Modules)
        }
        $CleanedModules = [System.Collections.Generic.List[string]]::new()

        foreach ($_ in $Modules) {
            if ($CleanedModules -notcontains $_) {
                $CleanedModules.Add($_)
            }
        }
        $CleanedModules.Add($Name)

        $Items = foreach ($_ in $CleanedModules) {
            Get-ChildItem -LiteralPath "$Path\$_" -Filter '*.psd1' -Recurse -ErrorAction SilentlyContinue -Depth 1
        }
        [Array] $PSD1Files = $Items.FullName
    }
    if ($Download) {
        $ListFiles = foreach ($PSD1 in $PSD1Files) {
            $PSD1.Replace("$Path", '$PSScriptRoot')
        }
        # Build File
        <#
        $Content = @(
            '$Modules = @('
            foreach ($_ in $ListFiles) {
                "   `"$_`""
            }
            ')'
            "foreach (`$_ in `$Modules) {"
            "   Import-Module `$_ -Verbose:`$false -Force"
            "}"
        )
        $Content | Set-Content -Path $Path\$Name.ps1 -Force
        #>
    }
    if ($Import) {
        $ListFiles = foreach ($PSD1 in $PSD1Files) {
            $PSD1
        }
        foreach ($_ in $ListFiles) {
            Import-Module $_ -Verbose:$false -Force
        }
    }
}

Clear-Host
$path="Указать_Путь_Где_нужно_Соханить_Модуль"

# Ниже строчка указывает, что нужно найти в репозитории
$modules = find-module -Verbose |Where-Object -Property Author -eq "Microsoft" 

foreach ($mod  in $modules) {
Write-Host "-------------------------------"
Write-Host "В репозитории найдена версия $($mod.Version) модуля $($mod.name)" -ForegroundColor Magenta
   
    $mymod= get-module -Name "$path\$($mod.name)" -ListAvailable
     $myVersion = $mymod |Measure-Object -Property Version -Maximum
     
         Write-Host "Текущая сохраненная версия модуля $($mod.name) в.$(($myVersion.Maximum).ToString())" -ForegroundColor Green

     
                if ($mod.Version -eq $(($myVersion.Maximum).ToString())){
                                        Write-Host "Обновление модуля $($mod.name) не требуется" -ForegroundColor Red
                                        }
                                        else {
                                        Write-Host "Требуется обновление модуля $($mod.name) с версии $(($myVersion.Maximum).ToString()) на версию $($mod.Version).`nСохраняю в каталог... $path" -ForegroundColor Yellow
                                        Initialize-ModulePortable -Name $mod.name  -Path $path -Verbose -Download
                                        }
}
 
