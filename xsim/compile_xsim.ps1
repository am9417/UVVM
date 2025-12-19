param(
    $library
)

Write-Host "Library is $library"
$directory = (Join-Path ".." $library) | Resolve-Path
Write-Host "Directory $directory"
$script_dir = Join-Path $directory "script"
$compile_order = Get-Content (Join-Path $script_dir "compile_order.txt")

Write-Host $compile_order

$libname = $null
foreach ($line in $compile_order) {
    if($line.StartsWith("#"))
    {
        $libname = $line.Split(" ")[-1]
        "Library found in $line ==> $libname"
    }
    else
    {
        $filename = (Join-Path $script_dir $line) | Resolve-Path
        "File found in $line ==> `"$filename`""
        if($null -eq $libname)
        {
            Write-Error "Libname is null"
            exit
        }
        else
        {
            xvhdl --2019 -work $libname $filename
        }
    }

}