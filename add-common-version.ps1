Add-Type -AssemblyName System.Core

Function AddSluVersion($csprojPath, $commonAssemblyName)
{ 
    
     ls  -Filter ($csprojPath + "\*.csproj") | 
            ForEach-Object -Process{
                $xml = [XML](Get-Content  $_.FullName)
                $assemblyInfoNode = $null
                foreach($ig in $xml.Project.ItemGroup){
                    foreach($cn in $ig.ChildNodes){
                        if(($cn.Link ) -and ($cn.Include -eq "..\SolutionInfo.cs")){
                            return;
                        }
                        elseif($cn.Include -eq "Properties\AssemblyInfo.cs"){
                            $assemblyInfoNode = $ig
                        }
#                        elseif($cn.Include.EndsWith( "AssemblyVersionInfo.cs")) {
#                            $ig.RemoveChild($cn);
#                        }
                    }
                }

                if($assemblyInfoNode -ne $null){
                    $verlink = $xml.CreateElement("Compile")
                    $verlink.SetAttribute("Include","..\SolutionInfo.cs")
                     $verlinkIn = $xml.CreateElement("Link")
                     $verlinkIn.InnerText = "Properties\SolutionInfo.cs"
                     $verlink.AppendChild($verlinkIn)

                     $assemblyInfoNode.AppendChild($verlink);
                }   
                
                $xml.Save($_.FullName)


                $info = Get-Content ($csprojPath + "\Properties\AssemblyInfo.cs") -Encoding UTF8
                for($i = 0; $i -lt $info.Count; $i+=1){
                    $line = $info[$i]
                    if($line.StartsWith("[assembly:")){
                        $last = $line.IndexOf('(');
                        $key = $line.SubString(0,$last).Substring("[assembly:".Length).Trim()
                        if($commonAssemblyName.Contains($key)){
                            $info[$i] = "//" + $info[$i]
                        }
                    }
                }

                Set-Content -Path ($csprojPath + "\Properties\AssemblyInfo.cs") -Value $info -Encoding UTF8               



           }      
}

function GetCommonAssemblyInfo($commonInfoPath){
    $ret = New-Object 'System.Collections.Generic.HashSet[string]'

    $info = Get-Content $commonInfoPath -Encoding UTF8
    foreach($line in $info){
        if($line.StartsWith("[assembly:")){
            $last = $line.IndexOf('(');
            $key = $line.SubString(0,$last).Substring("[assembly:".Length).Trim()
            $ret.Add($key);
        }
    }

    return $ret;
}

$commonFile = "SolutionInfo.cs"

if ( Test-Path $commonFile  ){
   $commonAssemblyName = GetCommonAssemblyInfo($commonFile)
   ls -Directory |
        ForEach-Object -Process { 
           AddSluVersion -csprojPath $_.Name  -commonAssemblyName  $commonAssemblyName
        }
     
}
else{
    echo "解决方案目录必须有文件：SolutionInfo.cs"
}


