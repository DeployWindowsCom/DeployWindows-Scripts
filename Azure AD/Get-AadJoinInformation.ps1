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
        [MarshalAs(UnmanagedType.LPWStr)] public string pszUserEmail;
        [MarshalAs(UnmanagedType.LPWStr)] public string pszUserKeyId;
        [MarshalAs(UnmanagedType.LPWStr)] public string pszUserKeyName;
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
        [MarshalAs(UnmanagedType.LPWStr)] public string pszDeviceId;
        [MarshalAs(UnmanagedType.LPWStr)] public string pszIdpDomain;
        [MarshalAs(UnmanagedType.LPWStr)] public string pszTenantId;
        [MarshalAs(UnmanagedType.LPWStr)] public string pszJoinUserEmail;
        [MarshalAs(UnmanagedType.LPWStr)] public string pszTenantDisplayName;
        [MarshalAs(UnmanagedType.LPWStr)] public string pszMdmEnrollmentUrl;
        [MarshalAs(UnmanagedType.LPWStr)] public string pszMdmTermsOfUseUrl;
        [MarshalAs(UnmanagedType.LPWStr)] public string pszMdmComplianceUrl;
        [MarshalAs(UnmanagedType.LPWStr)] public string pszUserSettingSyncUrl;
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

#[NetAPI32]::NetFreeAadJoinInformation([IntPtr]::Zero);
$retValue = [NetAPI32]::NetGetAadJoinInformation($pcszTenantId, [ref]$ptrJoinInfo);

if ($retValue -eq 0) 
{
    #https://support.microsoft.com/en-us/help/2909958/exceptions-in-windows-powershell-other-dynamic-languages-and-dynamical

    $ptrJoinInfoObject = New-Object NetAPI32+DSREG_JOIN_INFO
    $joinInfo = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ptrJoinInfo, [System.Type] $ptrJoinInfoObject.GetType())
    $joinInfo | fl

    $ptrUserInfo = $joinInfo.pUserInfo
    $ptrUserInfoObject = New-Object NetAPI32+DSREG_USER_INFO
    $userInfo = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ptrUserInfo, [System.Type] $ptrUserInfoObject.GetType())
    $userInfo | fl

    switch ($joinInfo.joinType)
    {
        ([NetAPI32+DSREG_JOIN_TYPE]::DSREG_DEVICE_JOIN.value__)    { Write-Host "Device is joined" }
        ([NetAPI32+DSREG_JOIN_TYPE]::DSREG_UNKNOWN_JOIN.value__)   { Write-Host "Device is not joined, or unknown type" }
        ([NetAPI32+DSREG_JOIN_TYPE]::DSREG_WORKPLACE_JOIN.value__) { Write-Host "Device workplace joined" }
    }

    $ptrJoinCertificate = $joinInfo.pJoinCertificate
    $ptrJoinCertificateObject = New-Object NetAPI32+CERT_CONTEX
    $joinCertificate = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ptrJoinCertificate, [System.Type] $ptrJoinCertificateObject.GetType())
    $JoinCertificate | fl


    #Release pointers
    [System.Runtime.InterOpServices.Marshal]::Release($ptrJoinInfo) | Out-Null
    [System.Runtime.InterOpServices.Marshal]::Release($ptrUserInfo) | Out-Null
    [System.Runtime.InterOpServices.Marshal]::Release($ptrJoinCertificate) | Out-Null
}
else
{
    Write-Host "Not Azure Joined"
}
