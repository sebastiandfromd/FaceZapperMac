# Clicks at a position relative to a process's main window (brought to the front first).
param([int]$ProcessId, [int]$X, [int]$Y)
Add-Type @"
using System; using System.Runtime.InteropServices;
public class Clk {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(int f, int dx, int dy, int d, int e);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
}
"@
[void][Clk]::SetProcessDPIAware()
$h = (Get-Process -Id $ProcessId).MainWindowHandle
[void][Clk]::SetForegroundWindow($h)
Start-Sleep -Milliseconds 400
$r = New-Object Clk+RECT
[void][Clk]::GetWindowRect($h, [ref]$r)
[void][Clk]::SetCursorPos($r.Left + $X, $r.Top + $Y)
Start-Sleep -Milliseconds 100
[Clk]::mouse_event(0x2, 0, 0, 0, 0); [Clk]::mouse_event(0x4, 0, 0, 0, 0)
"clicked at window position $X,$Y"
