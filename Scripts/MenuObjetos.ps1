$subdominio = Read-Host "Introduce el subdominio: "
$dominio = Read-Host "Introduce el dominio sin el sufijo: "
$sufijo = Read-Host "Introduce el sufijo"

$dc = "dc=" + $subdominio + ",dc=" + $dominio + ",dc=" + $sufijo

function Show-Menu {
    Clear-Host
    Write-Host "-------- Menu gestor de objetos --------"
    Write-Host "1: Política de contraseñas"
    Write-Host "2: Añadir Grupos"
    Write-Host "3: Añadir UOs"
    Write-Host "4: Añadir Usuarios"
    Write-Host "q: Salir del menu"
}

function añadirUsuarios {

    if (!(Get-Module -Name ActiveDirectory)) {
        Import-Module ActiveDirectory
    }

    $fileUsersCsv = Read-Host "Introduce el fichero csv de los usuarios:"

    $fichero = import-csv -Path $fileUsersCsv -Delimiter : 
					     
    foreach($linea in $fichero) {
	    $containerPath = $linea.ContainerPath + "," + $dc 
	    $passAccount = ConvertTo-SecureString ($linea.DNI + "@altamira-2") -AsPlainText -force
	    $nameShort = $linea.Name.Substring(0,1) + $linea.FirstName + $linea.Lastname.Substring(0,1)
	    $Surnames = $linea.FirstName + ' ' + $linea.LastName
	    $nameLarge = $linea.Name + ' ' + $linea.FirstName + ' ' + $linea.LastName
	    $email = $nameShort + "@" + $subDominio + "." + $dominio + "." + "$sufijo"

	    [boolean]$Habilitado = $true
    	If($linea.Enabled -Match 'false') { 
            $Habilitado = $false
        }
	    
   	    $ExpirationAccount = $linea.ExpirationAccount
    	$timeExp = (get-date).AddDays($ExpirationAccount)

	    New-ADUser -SamAccountName $nameShort -UserPrincipalName $nameShort -Name $nameShort -Surname $Surnames -DisplayName $nameLarge -GivenName $linea.Name -LogonWorkstations:$linea.Computer -Description "Cuenta de $nameLarge" -EmailAddress $email -AccountPassword $passAccount -Enabled $Habilitado -CannotChangePassword $false -ChangePasswordAtLogon $true -PasswordNotRequired $false -Path $containerPath -AccountExpirationDate $timeExp
 
	    $cnGrpAccount = "Cn=" + $linea.Group + "," + $containerPath
	    Add-ADGroupMember -Identity $cnGrpAccount -Members $nameShort
    }
}

function añadirGrupos {

    $gruposCsv = Read-Host "Introduce el fichero csv de Grupos:"
    $fichero = import-csv -Path $gruposCsv -delimiter :

    foreach($linea in $fichero) {
	    $pathObject=$linea.Path+","+$dc
            Write-Host "Has creado el grupo: " + $linea.Name
		    New-ADGroup -Name:$linea.Name -Description:$linea.Description -GroupCategory:$linea.Category -GroupScope:$linea.Scope  -Path:$pathObject
    }
}

function añadirUO {

    $fichero_csv=Read-Host "Introduce el fichero csv de las UO:"

    $fichero_csv_importado = import-csv -Path $fichero_csv -Delimiter :
     			     
    foreach($linea in $fichero_csv_importado) {
        Write-Host "Se ha creado la UO: "$linea.Name
        New-ADOrganizationalUnit -Name $linea.Name

    }

}


#Menu Principal
do {
    Show-Menu
    $input = Read-Host "Por favor, elija una opción"
    switch ($input) {
        '1' {
            Get-ADDefaultDomainPasswordPolicy
        }
        '2' {
            Clear-Host
            añadirGrupos
        }
        '3' {
            Clear-Host
            añadirUO
        }
        '4' {
            Clear-Host
            añadirUsuarios
        }
        'q' {
            Clear-Host
            'Saliendo del menu...'
            return
        }
    }
    pause
} 
until ($input -eq 'q')
