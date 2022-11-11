<#	
	.NOTES
	===========================================================================
	 
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>
function Initialize-ModulePortable
{
	[CmdletBinding()]
	param (
		[alias('ModuleName')]
		[string]
		$Name,
		[string]
		$Path = $PSScriptRoot,
		[switch]
		$Download,
		[switch]
		$Import
	)
	function Get-RequiredModule
	{
		param (
			[string]
			$Path,
			[string]
			$Name
		)
		$PrimaryModule = Get-ChildItem -LiteralPath "$Path\$Name" -Filter '*.psd1' -Recurse -ErrorAction SilentlyContinue -Depth 1
		if ($PrimaryModule)
		{
			$Module = Get-Module -ListAvailable $PrimaryModule.FullName -ErrorAction SilentlyContinue -Verbose:$false
			if ($Module)
			{
				[Array]$RequiredModules = $Module.RequiredModules.Name
				if ($null -ne $RequiredModules)
				{
					$null
				}
				$RequiredModules
				foreach ($_ in $RequiredModules)
				{
					Get-RequiredModule -Path $Path -Name $_
				}
			}
		}
		else
		{
			Write-Warning "Initialize-ModulePortable - Модули $Name для загрузки не найдены в $Path"
		}
	}
	
	if (-not $Name)
	{
		Write-Warning "Initialize-ModulePortable - Имя модуля не указано. Завершение операции."
		return
	}
	if (-not $Download -and -not $Import)
	{
		Write-Warning "Initialize-ModulePortable - Укажите ключ Download или Import. Завершение операции."
		return
	}
	
	if ($Download)
	{
		try
		{
			if (-not $Path -or -not (Test-Path -LiteralPath $Path))
			{
				$null = New-Item -ItemType Directory -Path $Path -Force
			}
			Save-Module -Name $Name -LiteralPath $Path -WarningVariable WarningData -WarningAction SilentlyContinue -ErrorAction Stop
		}
		catch
		{
			$ErrorMessage = $_.Exception.Message
			
			if ($WarningData)
			{
				Write-Warning "Initialize-ModulePortable - $WarningData"
			}
			Write-Warning "Initialize-ModulePortable - Ошибка $ErrorMessage"
			return
		}
	}
	
	if ($Download -or $Import)
	{
		[Array]$Modules = Get-RequiredModule -Path $Path -Name $Name | Where-Object { $null -ne $_ }
		if ($null -ne $Modules)
		{
			[array]::Reverse($Modules)
		}
		$CleanedModules = [System.Collections.Generic.List[string]]::new()
		
		foreach ($_ in $Modules)
		{
			if ($CleanedModules -notcontains $_)
			{
				$CleanedModules.Add($_)
			}
		}
		$CleanedModules.Add($Name)
		
		$Items = foreach ($_ in $CleanedModules)
		{
			Get-ChildItem -LiteralPath "$Path\$_" -Filter '*.psd1' -Recurse -ErrorAction SilentlyContinue -Depth 1
		}
		[Array]$PSD1Files = $Items.FullName
	}
	if ($Download)
	{
		$ListFiles = foreach ($PSD1 in $PSD1Files)
		{
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
	if ($Import)
	{
		$ListFiles = foreach ($PSD1 in $PSD1Files)
		{
			$PSD1
		}
		foreach ($_ in $ListFiles)
		{
			Import-Module $_ -Verbose:$false -Force
		}
	}
}

Clear-Host
[System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy('SERVER:PORT')
[System.Net.WebRequest]::DefaultWebProxy.BypassProxyOnLocal = $true

$path = "ПУть до библиотеки с модулями"

Write-Host "Начало поиска доступных модулей" -ForegroundColor Blue
$modules = find-module | Where-Object -Property Author -eq "Автор для сокращения поисков"

foreach ($mod  in $modules)
{
	Write-Host "-------------------------------"
	Write-Host "Найден модуль $($mod.name) в репозитории. Версия: $($mod.Version) " -ForegroundColor Magenta
	
	try {
		$mymod = get-module -Name "$path\$($mod.name)" -ListAvailable -ErrorAction SilentlyContinue
		$myVersion = $mymod | Measure-Object -Property Version -Maximum
		Write-Host "Текущая сохраненная версия модуля $($mod.name) в.$(($myVersion.Maximum).ToString())" -ForegroundColor Green	
		
			if ($mod.Version -eq $(($myVersion.Maximum).ToString()))
			{
				Write-Host "Обновление модуля $($mod.name) не требуется" -ForegroundColor DarkCyan
			}
			else
			{
				Write-Host "Требуется обновление модуля $($mod.name) с версии $(($myVersion.Maximum).ToString()) на версию $($mod.Version).`nСохраняю в каталог... $path" -ForegroundColor Yellow
				Initialize-ModulePortable -Name $mod.name -Path $path -Verbose -Download
			}
			
	}
	catch {
		write-host "Модуль $($mod.name) отсутствует в каталоге. Обновления не требуется" -ForegroundColor Red
	}
}
