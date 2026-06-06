$text = Get-Content 'E:\Ideaproject\dify\temp_data\20260605-dify离线安装插件需要镜像地址导致报错.md' -Raw
$chinese = [regex]::Matches($text, '[\u4e00-\u9fff]')
Write-Output "中文字符数: $($chinese.Count)"
Write-Output "总字符数: $($text.Length)"
Write-Output "总行数: $((Get-Content 'E:\Ideaproject\dify\temp_data\20260605-dify离线安装插件需要镜像地址导致报错.md').Count)"
