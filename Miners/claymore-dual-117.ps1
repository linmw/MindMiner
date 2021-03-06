<#
MindMiner  Copyright (C) 2018  Oleg Samsonov aka Quake4
https://github.com/Quake4/MindMiner
License GPL-3.0
#>

. .\Code\Include.ps1

if (![Config]::Is64Bit) { exit }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Cfg = [BaseConfig]::ReadOrCreate([IO.Path]::Combine($PSScriptRoot, $Name + [BaseConfig]::Filename), @{
	Enabled = $true
	BenchmarkSeconds = 120
	Algorithms = @(
	@{ Enabled = $true; Algorithm = "ethash"; DualAlgorithm = "keccak" }
	@{ Enabled = $true; Algorithm = "ethash"; DualAlgorithm = "blake2s" }
)})

if (!$Cfg.Enabled) { return }

$file = [IO.Path]::Combine($BinLocation, $Name, "epools.txt")
if ([IO.File]::Exists($file)) {
	[IO.File]::Delete($file)
}

$file = [IO.Path]::Combine($BinLocation, $Name, "dpools.txt")
if ([IO.File]::Exists($file)) {
	[IO.File]::Delete($file)
}

$Cfg.Algorithms | ForEach-Object {
	if ($_.Enabled) {
		$Algo = Get-Algo($_.Algorithm)
		$DualAlgo = Get-Algo($_.DualAlgorithm)
		if ($Algo -and $DualAlgo) {
			# find pool by algorithm
			$Pool = Get-Pool($Algo)
			$DualPool = Get-Pool($DualAlgo)
			if ($Pool -and $DualPool) {
				$esm = 2 # MiningPoolHub
				if ($Pool.Name -contains "nicehash") {
					$esm = 3
				}
				$extrargs = Get-Join " " @($Cfg.ExtraArgs, $_.ExtraArgs)
				[MinerInfo]@{
					Pool = "$($Pool.PoolName())+$($DualPool.PoolName())"
					PoolKey = "$($Pool.PoolKey())+$($DualPool.PoolKey())"
					Name = $Name
					Algorithm = $Algo
					DualAlgorithm = $DualAlgo
					Type = [eMinerType]::AMD
					API = "claymoredual"
					URI = "http://mindminer.online/miners/AMD/claymore/Claymore-Dual-Ethereum-AMD+NVIDIA-Miner-v11.7.zip"
					Path = "$Name\EthDcrMiner64.exe"
					ExtraArgs = $extrargs
					Arguments = "-epool $($Pool.Host):$($Pool.PortUnsecure) -ewal $($Pool.User) -epsw $($Pool.Password) -dpool $($DualPool.Host):$($DualPool.PortUnsecure) -dcoin $($_.DualAlgorithm) -dwal $($DualPool.User) -dpsw $($DualPool.Password) -retrydelay $($Config.CheckTimeout) -wd 0 -allpools 1 -esm $esm -mport -3350 -platform 1 -y 1 $extrargs"
					Port = 3350
					BenchmarkSeconds = if ($_.BenchmarkSeconds) { $_.BenchmarkSeconds } else { $Cfg.BenchmarkSeconds }
					RunBefore = $_.RunBefore
					RunAfter = $_.RunAfter
					Fee = 2
				}
				[MinerInfo]@{
					Pool = "$($Pool.PoolName())+$($DualPool.PoolName())"
					PoolKey = "$($Pool.PoolKey())+$($DualPool.PoolKey())"
					Name = $Name
					Algorithm = $Algo
					DualAlgorithm = $DualAlgo
					Type = [eMinerType]::nVidia
					API = "claymoredual"
					URI = "http://mindminer.online/miners/AMD/claymore/Claymore-Dual-Ethereum-AMD+NVIDIA-Miner-v11.7.zip"
					Path = "$Name\EthDcrMiner64.exe"
					ExtraArgs = $extrargs
					Arguments = "-epool $($Pool.Host):$($Pool.PortUnsecure) -ewal $($Pool.User) -epsw $($Pool.Password) -dpool $($DualPool.Host):$($DualPool.PortUnsecure) -dwal $($DualPool.User) -dcoin $($_.DualAlgorithm) -dpsw $($DualPool.Password) -retrydelay $($Config.CheckTimeout) -wd 0 -allpools 1 -esm $esm -mport -3360 -platform 2 $extrargs"
					Port = 3360
					BenchmarkSeconds = if ($_.BenchmarkSeconds) { $_.BenchmarkSeconds } else { $Cfg.BenchmarkSeconds }
					RunBefore = $_.RunBefore
					RunAfter = $_.RunAfter
					Fee = 2
				}
			}
		}
	}
}