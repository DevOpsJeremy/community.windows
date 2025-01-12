#!powershell

# Copyright: (c) 2025, Jeremy Watkins (@DevOpsJeremy) <DevOpsJeremy@gmail.com>
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
using namespace Ansible.Basic
using namespace System.IO

#region Functions
function Find-Git {
    [CmdletBinding()]
    param (
        [string] $Executable = 'git.exe',
        [string[]] $Paths = @(
            'C:\Program Files\Git\bin',
            'C:\Program Files\Git\usr\bin',
            'C:\Program Files (x86)\Git\bin',
            'C:\Program Files (x86)\Git\usr\bin'
        )
    )
    $env:Path = $env:Path, ($Paths -join [Path]::PathSeparator) -join [Path]::PathSeparator
    try {
        return (Get-Command -Name $Executable -ErrorAction Stop).Source
    } catch [System.Management.Automation.CommandNotFoundException] {
        throw ('Failed to find required executable "{0}" in paths: {1}' -f $Executable, $env:Path)
    }
}
#endregion Functions

# Define the spec
$spec = @{
    options = @{
        dest                = @{ type = 'path' }
        repo                = @{ required = $true ; aliases = 'name' }
        version             = @{ default = 'HEAD' }
        remote              = @{ default = 'origin' }
        refspec             = @{}
        reference           = @{}
        force               = @{ type = 'bool' ; default = $false }
        depth               = @{ type = 'int' }
        clone               = @{ type = 'bool' ; default = $true }
        update              = @{ type = 'bool' ; default = $true }
        verify_commit       = @{ type = 'bool' ; default = $false }
        gpg_allowlist       = @{ type = 'list' ; default = @() ; aliases = 'gpg_whitelist' ; elements = 'str' }
        accept_hostkey      = @{ type = 'bool' ; default = $false }
        accept_newhostkey   = @{ type = 'bool' ; default = $false }
        key_file            = @{ type = 'path' }
        ssh_opts            = @{}
        executable          = @{ type = 'path' }
        bare                = @{ type = 'bool' ; default = $false }
        recursive           = @{ type = 'bool' ; default = $true }
        single_branch       = @{ type = 'bool' ; default = $false }
        track_submodules    = @{ type = 'bool' ; default = $false }
        archive             = @{ type = 'path' }
        archive_prefix      = @{}
        separate_git_dir    = @{ type = 'path' }
    }
    mutually_exclusive      = @(
        @('separate_git_dir', 'bare'),
        @('accept_hostkey', 'accept_newhostkey')
    )
    required_by             = @{ archive_prefix = @('archive') }
    supports_check_mode     = $true
}
$module = [AnsibleModule]::Create($args, $spec)
$result = @{ changed = $false }

$dest               = $module.Params.dest
$repo               = $module.Params.repo
$version            = $module.Params.version
$remote             = $module.Params.remote
$refspec            = $module.Params.refspec
$force              = $module.Params.force
$depth              = $module.Params.depth
$update             = $module.Params.update
$clone              = $module.Params.clone
$bare               = $module.Params.bare
$verify_commit      = $module.Params.verify_commit
$gpg_allowlist      = $module.Params.gpg_allowlist
$reference          = $module.Params.reference
$single_branch      = $module.Params.single_branch
$key_file           = $module.Params.key_file
$ssh_opts           = $module.Params.ssh_opts
$archive            = $module.Params.archive
$archive_prefix     = $module.Params.archive_prefix
$separate_git_dir   = $module.Params.separate_git_dir

# Find the git executable
$executable         = if ($module.Params.executable -and (Test-Path -Path $module.Params.executable)) {
    $module.Params.executable
} else {
    try {
        Find-Git
    } catch {
        $module.FailJson($_.Exception.Message)
    }
}
$module.Result = $result
$module.ExitJson()
