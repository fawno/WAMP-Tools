Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @"
	[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
	public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
"@

function Send-SettingChange {
	$HWND_BROADCAST = [IntPtr] 0xffff;
	$WM_SETTINGCHANGE = 0x1a;
	$result = [UIntPtr]::Zero

	[void] ([Win32.Nativemethods]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, "Environment", 2, 5000, [ref] $result))
}