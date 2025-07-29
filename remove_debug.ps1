# PowerShell script to remove debug statements from Dart files

# Define the files to clean
$files = @(
    "lib\services\simple_pdf_service.dart",
    "lib\services\pdf_service.dart"
)

foreach ($file in $files) {
    Write-Host "Cleaning debug statements from $file"
    
    # Read the file content
    $content = Get-Content $file -Raw
    
    # Remove lines containing debug prints
    $cleanContent = $content -split "`n" | Where-Object {
        $_ -notmatch "print\('🚀" -and 
        $_ -notmatch "print\('❌" -and 
        $_ -notmatch "print\('🔧"
    } | Join-String -Separator "`n"
    
    # Write back to file
    Set-Content -Path $file -Value $cleanContent -NoNewline
    
    Write-Host "Cleaned $file"
}

Write-Host "Debug cleanup completed!"
