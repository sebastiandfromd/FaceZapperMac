# Saves a screenshot of a process's largest visible top-level window (only that rectangle).
# For checking the Windows build: capture-window.ps1 -ProcessId <pid> -OutFile shot.png
# Needs an unlocked screen (a locked screen gives a 0x0 window). Run the app with
# QT_FORCE_STDERR_LOGGING=1 to see its warnings as well.
param([int]$ProcessId, [string]$OutFile)
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices; using System.Collections.Generic;
public class Win {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc f, IntPtr l);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern void keybd_event(byte k, byte s, int f, int e);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  public static RECT Largest(uint target) {
    RECT best = new RECT(); long bestArea = 0;
    EnumWindows((h, l) => { uint pid; GetWindowThreadProcessId(h, out pid);
      if (pid == target && IsWindowVisible(h)) { RECT r; GetWindowRect(h, out r);
        long a = (long)(r.Right - r.Left) * (r.Bottom - r.Top); if (a > bestArea) { bestArea = a; best = r; } }
      return true; }, IntPtr.Zero);
    return best; }
}
"@
[void][Win]::SetProcessDPIAware()
$hw = (Get-Process -Id $ProcessId).MainWindowHandle
[Win]::keybd_event(0x12, 0, 0, 0); [Win]::keybd_event(0x12, 0, 2, 0)   # Alt press lets Windows switch windows
[void][Win]::ShowWindow($hw, 9); [void][Win]::SetForegroundWindow($hw)
Start-Sleep -Milliseconds 700
$r = [Win]::Largest($ProcessId)
$w = $r.Right - $r.Left; $hh = $r.Bottom - $r.Top
$bmp = New-Object System.Drawing.Bitmap $w, $hh
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($r.Left, $r.Top, 0, 0, $bmp.Size)
$bmp.Save($OutFile, [System.Drawing.Imaging.ImageFormat]::Png)
"saved ${w}x${hh}"
