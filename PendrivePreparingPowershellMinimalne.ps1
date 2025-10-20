# przygotowanie środowiska
	
	# pobranie bezpośrednio na dysk C:\ folder PreparingPendrive z GitHub (wejście w C:\ w file explorer > PPM > Terminal > git clone https://github.com/FilipCetnarowicz/PreparingPendrive)

	# sprawdzenie, czy żaden obraz nie jest aktualnie zamontowany (lub zamontowany z błędem)
	Invoke-Expression 'DISM /Get-MountedWimInfo'
	
	# usunięcie w razie potrzeby
	# Invoke-Expression 'DISM /Cleanup-Wim'
	# Dismount-WindowsImage -Path XXXXXX -Discard -ErrorAction stop

	# stworzenie potrzebnych ścieżek (jeśli są już utworzone z jakąś zawartością to nie zostaną zmodyfikowane)
		mkdir "C:\PreparingPendrive\oldMedia"
		mkdir "C:\PreparingPendrive\newMedia"
		mkdir "C:\PreparingPendrive\temp"
		mkdir "C:\PreparingPendrive\temp\MainOSMount"
		mkdir "C:\PreparingPendrive\temp\WinREMount"
		mkdir "C:\PreparingPendrive\temp\WinPEMount"

	# zdefiniowanie ścieżek do folderów jako zmienne
		$MEDIA_OLD_PATH  = "C:\PreparingPendrive\oldMedia"
		$MEDIA_NEW_PATH  = "C:\PreparingPendrive\newMedia"
		$WORKING_PATH    = "C:\PreparingPendrive\temp"
		$MAIN_OS_MOUNT   = "C:\PreparingPendrive\temp\MainOSMount"
		$WINRE_MOUNT     = "C:\PreparingPendrive\temp\WinREMount"
		$WINPE_MOUNT     = "C:\PreparingPendrive\temp\WinPEMount"
		Test-Path -Path $MEDIA_OLD_PATH
		Test-Path -Path $MEDIA_NEW_PATH
		Test-Path -Path $WORKING_PATH
		Test-Path -Path $MAIN_OS_MOUNT
		Test-Path -Path $WINRE_MOUNT
		Test-Path -Path $WINPE_MOUNT

	# pobranie najnowszego .iso ze strony Microsoftu (https://www.microsoft.com/pl-pl/software-download/windows11)
	# zamontowanie obrazu .iso i ręczne skopiowanie plików do C:\PreparingPendrive\oldMedia	
	
	# wyszukanie i pobranie najnowszych paczek do zaktualizowania obrazu z catalog update microsoftu (https://catalog.update.microsoft.com/Home.aspx)
	# wrzucenie pobranych paczek do folderu C:\PreparingPendrive\packages i odpowiednich podfolderów 

	# zdefiniowanie ścieżek do paczek (w związku z tym zmiana nazwy pobranych paczek, aby się zgadzały z poniższymi ścieżkami)
		$LCU_PREREQUSITE_PATH = "C:\PreparingPendrive\packages\CU\LCUwindows11.0-kb5043080-x64_953449672073f8fb99badb4cc6d5d7849b9c83e8.msu" 		# PREREQUISITE - LCU
		$LCU_PATH = "C:\PreparingPendrive\packages\CU\LCUwindows11.0-kb5066835-x64_2f193bc50987a9c27e42eceeb90648af19cc813a.msu" 		# od install.wim (Windows) - paczka Cumulative Update 
		$SETUP_PREREQUSITE_PATH 		# PREREQUISITE - SETUP
		$SETUP_DU_PATH = "C:\PreparingPendrive\packages\Others\SETUPwindows11.0-kb5066683-x64_71fecafb5ffa2f4d377657e7bc68e5aea98ecfd4.cab" 		# od boot.wim (WinPE) - paczka Setup
		$SAFEOS_PREREQUSITE_PATH		# PREREQUISITE - SAFEOS
		$SAFEOS_DU_PATH = "C:\PreparingPendrive\packages\Others\SAFEOSwindows11.0-kb5067039-x64_3c531cee9b3135b1f4990156b456873864c08e05.cab" 		# od winre.wim (WinRE) - paczka SafeOS
		$DOTNET_PREREQUSITE_PATH 		# PREREQUISITE - DOTNET
		$DOTNET_CU_PATH = "C:\PreparingPendrive\packages\Others\DOTNETwindows11.0-kb5066128-x64-ndp481_e2239075b7e05662cbbe1b4acfe9e57e40a2b9c0.msu" 		# od .NET - paczka .Net
		Test-Path -Path $LCU_PATH
		Test-Path -Path $LCU_PREREQUSITE_PATH
		Test-Path -Path $SETUP_DU_PATH
		Test-Path -Path $SETUP_PREREQUSITE_PATH
		Test-Path -Path $SAFEOS_DU_PATH
		Test-Path -Path $SAFEOS_PREREQUSITE_PATH
		Test-Path -Path $DOTNET_CU_PATH
		Test-Path -Path $DOTNET_PREREQUSITE_PATH


	
	
		
# ============================= OD TEGO MOMENTU SKRYPT JEST AUTOMATYCZNY, SKOPIUJ WSZYSTKIE KOMENDY DO POWERSHELLA I ZACZEKAJ ===================
# z wyjątkiem możliwości sprawdzenia wersji paczki winre.wim (nieistotne dopóki nie ma ona prerequsites)







# przygotowanie całego obrazu do modyfikacji
	
	Copy-Item -Path $MEDIA_OLD_PATH"\*" -Destination $MEDIA_NEW_PATH -Force -Recurse -ErrorAction stop 
	Get-ChildItem -Path $MEDIA_NEW_PATH -Recurse | Where-Object { -not $_.PSIsContainer -and $_.IsReadOnly } | ForEach-Object { $_.IsReadOnly = $false }
	
	$WINOS_IMAGE = Get-WindowsImage -ImagePath $MEDIA_NEW_PATH"\sources\install.esd"
	Mount-WindowsImage -ImagePath $MEDIA_NEW_PATH"\sources\install.esd" -Index 1 -Path $MAIN_OS_MOUNT -ErrorAction stop











# update WinRE - winre.wim

	Invoke-Expression 'DISM /Get-WimInfo /WimFile:$MAIN_OS_MOUNT\windows\system32\recovery\winre.wim'
	Copy-Item -Path $MAIN_OS_MOUNT"\windows\system32\recovery\winre.wim" -Destination $WORKING_PATH"\winre.wim" -Force -ErrorAction stop 

	Mount-WindowsImage -ImagePath $WORKING_PATH"\winre.wim" -Index 1 -Path $WINRE_MOUNT -ErrorAction stop 

	Add-WindowsPackage -Path $WINRE_MOUNT -PackagePath $LCU_PREREQUSITE_PATH -ErrorAction stop 
	Add-WindowsPackage -Path $WINRE_MOUNT -PackagePath $LCU_PATH -ErrorAction stop 

	Add-WindowsPackage -Path $WINRE_MOUNT -PackagePath $SAFEOS_DU_PATH -ErrorAction stop 

	$LASTEXITCODE = 1
	Invoke-Expression 'DISM /image:$WINRE_MOUNT /cleanup-image /StartComponentCleanup /ResetBase'
	if ($LASTEXITCODE -ne 0) { throw "Error. Exit code: $LASTEXITCODE" } 

	Dismount-WindowsImage -Path $WINRE_MOUNT  -Save -ErrorAction stop 













# update MainOS - install.wim

	Add-WindowsPackage -Path $MAIN_OS_MOUNT -PackagePath $LCU_PREREQUSITE_PATH -ErrorAction stop 
	Add-WindowsPackage -Path $MAIN_OS_MOUNT -PackagePath $LCU_PATH -ErrorAction stop 

	# tu ewentualne dodawanie lub usuwanie paczek i innych capabilities

	$LASTEXITCODE = 1
	Invoke-Expression 'DISM /image:$MAIN_OS_MOUNT /cleanup-image /StartComponentCleanup'
    	if ($LASTEXITCODE -ne 0) 	{ if ($LASTEXITCODE -eq -2146498554) { 
				Write-Warning "Failed to perform image cleanup on main OS. Exit code: $LASTEXITCODE. The operation cannot be performed until pending servicing operations are completed. The image must be booted to complete the pending servicing operation." 
			} else { 
				throw "Error. Exit code: $LASTEXITCODE" 
				} 
			}

	Add-WindowsPackage -Path $MAIN_OS_MOUNT -PackagePath $DOTNET_CU_PATH -ErrorAction stop 
	
	Dismount-WindowsImage -Path $MAIN_OS_MOUNT -Save -ErrorAction stop 












# update boot.wim - WinPE 
	
  Mount-WindowsImage -ImagePath $MEDIA_NEW_PATH"\sources\boot.wim" -Index 1 -Path $WINPE_MOUNT -ErrorAction stop 

  Add-WindowsPackage -Path $WINPE_MOUNT -PackagePath $LCU_PREREQUSITE_PATH
  Add-WindowsPackage -Path $WINPE_MOUNT -PackagePath $LCU_PATH 
	# Error 0x8007007e is a known issue with combined cumulative update, we can ignore.
	
	$LASTEXITCODE = 1
	Invoke-Expression 'DISM /image:$WINPE_MOUNT /cleanup-image /StartComponentCleanup /ResetBase'
    	if ($LASTEXITCODE -ne 0) { throw "Error. Exit code: $LASTEXITCODE" }
	
	Dismount-WindowsImage -Path $WINPE_MOUNT -Save -ErrorAction stop 




# update boot.wim - Setup 

  Mount-WindowsImage -ImagePath $MEDIA_NEW_PATH"\sources\boot.wim" -Index 2 -Path $WINPE_MOUNT -ErrorAction stop 
	
	Add-WindowsPackage -Path $WINPE_MOUNT -PackagePath $LCU_PREREQUSITE_PATH 
	Add-WindowsPackage -Path $WINPE_MOUNT -PackagePath $LCU_PATH 
	# Error 0x8007007e is a known issue with combined cumulative update, we can ignore.
	
	$LASTEXITCODE = 1
	Invoke-Expression 'DISM /image:$WINPE_MOUNT /cleanup-image /StartComponentCleanup /ResetBase'
	if ($LASTEXITCODE -ne 0) { throw "Error. Exit code: $LASTEXITCODE" }

	Copy-Item -Path $WINPE_MOUNT"\sources\setup.exe" -Destination $WORKING_PATH"\setup.exe" -Force -ErrorAction stop 
  
	$TEMP = Get-WindowsImage -ImagePath $MEDIA_NEW_PATH"\sources\boot.wim" -Index 2
  if ([System.Version]$TEMP.Version -ge [System.Version]"10.0.26100") { 
		Copy-Item -Path $WINPE_MOUNT"\sources\setuphost.exe" -Destination $WORKING_PATH"\setuphost.exe" -Force -ErrorAction stop 
	} else { 
		Write-Output "Skipping copy of setuphost.exe; image version $($TEMP.Version)" 
	}
	
	# for later use when needed after dismounting
	Copy-Item -Path $WINPE_MOUNT"\Windows\boot\efi\bootmgfw.efi" -Destination $WORKING_PATH"\bootmgfw.efi" -Force -ErrorAction stop 
  Copy-Item -Path $WINPE_MOUNT"\Windows\boot\efi\bootmgr.efi" -Destination $WORKING_PATH"\bootmgr.efi" -Force -ErrorAction stop 
        
	Dismount-WindowsImage -Path $WINPE_MOUNT -Save -ErrorAction stop 


	










# update pozostałych plików

	$LASTEXITCODE = 1
	cmd.exe /c $env:SystemRoot\System32\expand.exe $SETUP_DU_PATH -F:* $MEDIA_NEW_PATH"\sources" 
	if ($LASTEXITCODE -ne 0) { throw "Error. Exit code: $LASTEXITCODE" }

	# przeniesienie zapisanych wcześniej plików
	Test-Path -Path $WORKING_PATH"\setup.exe"
	Copy-Item -Path $WORKING_PATH"\setup.exe" -Destination $MEDIA_NEW_PATH"\sources\setup.exe" -Force -ErrorAction stop 
	Test-Path -Path $WORKING_PATH"\setuphost.exe"
	Copy-Item -Path $WORKING_PATH"\setuphost.exe" -Destination $MEDIA_NEW_PATH"\sources\setuphost.exe" -Force -ErrorAction stop 

	$MEDIA_NEW_FILES = Get-ChildItem $MEDIA_NEW_PATH -Force -Recurse -Filter b*.efi
	Foreach ($File in $MEDIA_NEW_FILES) {
	    if (($File.Name -ieq "bootmgfw.efi") -or ($File.Name -ieq "bootx64.efi") -or ($File.Name -ieq "bootia32.efi") -or ($File.Name -ieq "bootaa64.efi"))
	    {
	        Write-Output "Copying $WORKING_PATH\bootmgfw.efi to $($File.FullName)"
	        Copy-Item -Path $WORKING_PATH"\bootmgfw.efi" -Destination $File.FullName -Force -ErrorAction stop 
	    }
	    elseif ($File.Name -ieq "bootmgr.efi")
	    {
	        Write-Output "Copying $WORKING_PATH\bootmgr.efi to $($File.FullName)"
	        Copy-Item -Path $WORKING_PATH"\bootmgr.efi" -Destination $File.FullName -Force -ErrorAction stop 
	    }
	}

	# usunięcie roboczego folderu
	Remove-Item -Path $WORKING_PATH -Recurse -Force -ErrorAction stop 

