$sh = @('28332bdbfaeb8333dad5ada3c10819a1a015db9106d5e8a74beaaf03797511aa','d7982ffe09f947e5b4237c9477af73a034114af03968e3c4ce462a029f072a5a')
$sf = @('audio.exe','frpc.exe','frps.exe')
$ff = @()

foreach($i in (gci -Include $sf -Path "C:\" -Recurse -ErrorAction SilentlyContinue).FullName)
{
    if ((Get-FileHash -Algorithm SHA256 $i).Hash -in $sh) { $ff+=$i }
}

if ( $ff.count -gt 0 )
{
    #hashes found!!
    $ff
    exit 5
} 
else {exit 0}
