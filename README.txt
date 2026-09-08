EZCab [version 1.1]

Usage:

EZCAB /C [/T:{MSZIP|LZX|NONE}] source [output]
EZCAB /S [/T:{MSZIP|LZX|NONE}] [/L:launcher] [/G] [/H:title] source [output]
EZCAB /X file [extract]
EZCAB /L file

  /C        Compress a file or folder into a CAB archive.
  /S        Compress a file or folder into a Self-Extracting CMD script.
  /X        Extract the contents of a CAB archive or a self-extracting CMD.
  /L        List the contents of a CAB archive without extracting.

  /T:type   Compression types: "MSZIP" (default), "LZX" (better compression)
            or "NONE".
  /L:file   Entry-point script inside the bundle (default: "start.cmd").
  /G        Hide the console window (GUI mode).
  /H:text   Title of the console window.

  source    File or directory you want to compress.
  output    Path or name of the resulting CAB file.
  file      Path to the CAB archive you want to read or extract.
  extract   Destination folder for extracted files (defaults to current
            directory).

EZCAB /C /T:LZX "My File.txt" "My CAB"
EZCAB /C /T:LZX "My Folder\*" "My CAB"
EZCAB /S /T:LZX /L:"App Launcher.exe" /G /H:"My App" "App Src" "My Script"
EZCAB /X "My CAB.cab" "My Folder\New Files"
EZCAB /X "My Script.cmd" "Scripts Folder"
EZCAB /L "My CAB.cab"
EZCAB /L "My Script.cmd"
