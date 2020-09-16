<#PSScriptInfo

.VERSION 1.0

.GUID 

.AUTHOR Mattias Fors

.COMPANYNAME DeployWindows.com

.COPYRIGHT 

.TAGS Windows AzureAD TenantID AAD AADJ ADJ AD DeviceID

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
Version 1.0:  Original

#>

<#
.SYNOPSIS
Get information from the local computer such as Azure AD join status, tenant Id, device id
.DESCRIPTION
Get information from the local computer such as Azure AD join status, tenant Id, device id and such. Similar information as dsregcmd /status
.EXAMPLE
.\Get-AadJoinInformation.ps1

#>


Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;

public class NetAPI32{
    public enum DSREG_JOIN_TYPE {
      DSREG_UNKNOWN_JOIN,
      DSREG_DEVICE_JOIN,
      DSREG_WORKPLACE_JOIN
    }

	[StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    public struct DSREG_USER_INFO {
        [MarshalAs(UnmanagedType.LPWStr)] public string UserEmail;
        [MarshalAs(UnmanagedType.LPWStr)] public string UserKeyId;
        [MarshalAs(UnmanagedType.LPWStr)] public string UserKeyName;
    }

    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    public struct CERT_CONTEX {
        public uint   dwCertEncodingType;
        public byte   pbCertEncoded;
        public uint   cbCertEncoded;
        public IntPtr pCertInfo;
        public IntPtr hCertStore;
    }

	[StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    public struct DSREG_JOIN_INFO
    {
        public int joinType;
        public IntPtr pJoinCertificate;
        [MarshalAs(UnmanagedType.LPWStr)] public string DeviceId;
        [MarshalAs(UnmanagedType.LPWStr)] public string IdpDomain;
        [MarshalAs(UnmanagedType.LPWStr)] public string TenantId;
        [MarshalAs(UnmanagedType.LPWStr)] public string JoinUserEmail;
        [MarshalAs(UnmanagedType.LPWStr)] public string TenantDisplayName;
        [MarshalAs(UnmanagedType.LPWStr)] public string MdmEnrollmentUrl;
        [MarshalAs(UnmanagedType.LPWStr)] public string MdmTermsOfUseUrl;
        [MarshalAs(UnmanagedType.LPWStr)] public string MdmComplianceUrl;
        [MarshalAs(UnmanagedType.LPWStr)] public string UserSettingSyncUrl;
        public IntPtr pUserInfo;
    }

    [DllImport("netapi32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern void NetFreeAadJoinInformation(
            IntPtr pJoinInfo);

    [DllImport("netapi32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern int NetGetAadJoinInformation(
            string pcszTenantId,
            out IntPtr ppJoinInfo);
}
'@

$pcszTenantId = $null
$ptrJoinInfo = [IntPtr]::Zero

# https://docs.microsoft.com/en-us/windows/win32/api/lmjoin/nf-lmjoin-netgetaadjoininformation
#[NetAPI32]::NetFreeAadJoinInformation([IntPtr]::Zero);
$retValue = [NetAPI32]::NetGetAadJoinInformation($pcszTenantId, [ref]$ptrJoinInfo);

# https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-erref/18d8fbe8-a967-4f1c-ae50-99ca8e491d2d
if ($retValue -eq 0) 
{
    # https://support.microsoft.com/en-us/help/2909958/exceptions-in-windows-powershell-other-dynamic-languages-and-dynamical

    $ptrJoinInfoObject = New-Object NetAPI32+DSREG_JOIN_INFO
    $joinInfo = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ptrJoinInfo, [System.Type] $ptrJoinInfoObject.GetType())
    $joinInfo | fl

    $ptrUserInfo = $joinInfo.pUserInfo
    $ptrUserInfoObject = New-Object NetAPI32+DSREG_USER_INFO
    $userInfo = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ptrUserInfo, [System.Type] $ptrUserInfoObject.GetType())
    $userInfo | fl

    Write-Host "Device is $([NetAPI32+DSREG_JOIN_TYPE]($joinInfo.joinType))"
    switch ($joinInfo.joinType)
    {
        ([NetAPI32+DSREG_JOIN_TYPE]::DSREG_DEVICE_JOIN.value__)    { Write-Host "Device is joined" }
        ([NetAPI32+DSREG_JOIN_TYPE]::DSREG_UNKNOWN_JOIN.value__)   { Write-Host "Device is not joined, or unknown type" }
        ([NetAPI32+DSREG_JOIN_TYPE]::DSREG_WORKPLACE_JOIN.value__) { Write-Host "Device workplace joined" }
    }

    $ptrJoinCertificate = $joinInfo.pJoinCertificate
    $ptrJoinCertificateObject = New-Object NetAPI32+CERT_CONTEX
    $joinCertificate = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ptrJoinCertificate, [System.Type] $ptrJoinCertificateObject.GetType())
    #$JoinCertificate | fl

    #Release pointers
    [System.Runtime.InterOpServices.Marshal]::Release($ptrJoinInfo) | Out-Null
    [System.Runtime.InterOpServices.Marshal]::Release($ptrUserInfo) | Out-Null
    [System.Runtime.InterOpServices.Marshal]::Release($ptrJoinCertificate) | Out-Null
}
else
{
    Write-Host "Not Azure Joined"
}
