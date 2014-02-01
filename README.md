loft
====

Logical Organisation of Files by Type

A Ruby script to organise files.

The script uses the yomu gem to get the title of the document if the file name
doesn't include a title (e.g. the file name only has numbers).
The file will be renamed and sorted into a subdirectory according to it's file
type (e.g. pdf). It also renames the file with the creation date.

If no source directory is given it uses the current directory.
If no destination directory is given it uses ~/Documents as a base.

Usage
=====

```
loft.rb -[chiotvVd:s:]

-h: Print help
-t: Run in test mode (don't move/rename any files)
-c: Sort files
-s: Source directory
-d: Destination directory
-V: Print version
-v: Verbose mode
```

Examples
========

```
$ loft.rb -c
Moving Documents/28885-8.txt to Documents/txt/28885-8_2013_11_12.txt
Moving Documents/4AA4-5167ENW.pdf to Documents/pdf/HP_Integrated_Lights-Out_Portfolio_Datasheet_U.S_English_4AA4-5167ENW_2013_11_08.pdf
Moving Documents/alice.txt to Documents/txt/alice_2013_11_12.txt
Moving Documents/BRKNMS-2031-ciscolive-syslog.pdf to Documents/pdf/BRKNMS-2031-ciscolive-syslog_2013_11_10.pdf
Moving Documents/desktop.ini to Documents/ini/desktop_2013_11_21.ini
Moving Documents/E20760.pdf to Documents/pdf/StorageTek_8_Gb_FC_PCI-Express_HBA_Installation_Guide_E20760_2013_11_03.pdf
Moving Documents/Leadership to Documents/txt/Leadership
Moving Documents/notes to Documents/txt/notes
```
