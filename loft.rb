#!/usr/bin/env ruby

# Name:         loft (Logical Organisation of Files by Type)
# Version:      0.0.8
# Release:      1
# License:      Open Source
# Group:        System
# Source:       N/A
# URL:          http://github.com/lateralblast/loft
# Distribution: UNIX
# Vendor:       Lateral Blast
# Packager:     Richard Spindler <richard@lateralblast.com.au>
# Description:  Script to organise files by type

require 'rubygems'
require 'etc'
require 'fileutils'
require 'pathname'
require 'getopt/std'
require 'yomu'
require 'mimetype_fu'
require 'mahoro'

# Create array for files to ignore

ignore_list = [".DS_Store",".localized"]

# Set up some variables

test_mode = 0
home_dir  = Etc.getpwuid.dir
store_dir = home_dir+"/Documents"
sort_dir  = Dir.pwd

# Get code name and version

def get_code_name
  code_name = $0
  code_name = Pathname.new(code_name)
  code_name = code_name.basename.to_s
  return code_name
end

def get_code_version
  code_version = IO.readlines($0)
  code_version = code_version.grep(/^# Version/)
  code_version = code_version[0].to_s.split(":")
  code_version = code_version[1].to_s.gsub(" ","")
  return code_version
end

# Print usage insformation

def print_usage(options)
  code_name    = get_code_name()
  code_version = get_code_version()
  puts
  puts code_name+" v. "+code_version
  puts
  puts "Usage: "+code_name+" -["+options+"]"
  puts
  puts "-h: Print help"
  puts "-t: Run in test mode (don't move/rename any files)"
  puts "-c: Sort files"
  puts "-s: Source directory"
  puts "-d: Destination directory"
  puts "-f: Process an individual file"
  puts "-V: Print version"
  puts "-v: Verbose mode"
  puts
  exit
end

# Clean up filename

def get_file_base(file_base)
  file_base = file_base.gsub(/[A-z]\./) { "#{$&}_"}
  file_base = file_base.gsub(/\.[A-z]/) { "_#{$&}"}
  file_base = file_base.gsub(/\._/,'_')
  file_base = file_base.gsub(/_\./,'_')
  file_base = file_base.gsub(/_$/,'')
  file_base = file_base.gsub(/\.$/,'')
  return file_base
end

def get_new_name(new_name,full_file_type,file_type,file_name,verbose_mode)
  time = Time.new
  year = time.year
  pdf_test = 1
  if full_file_type.match(/pdf/)
    pdf_test = %x[head -1 '#{file_name}' |strings |wc -l |awk '{print $1}']
    pdf_test = pdf_test.to_i
  end
  if !full_file_type.match(/Bootloader/) and pdf_test == 1 and !file_type.match(/jpg|gz|bz2/)
    yomu_types = [
      'doc','docx','xls','xlsx','ppt','pptx','odt','ods','odp', 'rtf','pdf','jfif',
      'epub','pages','numbers','keynote','mp3','jpeg','jpg', 'tiff','tif','cdf',
      'hdf','dwg'
    ]
    if yomu_types.grep(/#{file_type}/)
      if new_name.scan(/[[:alpha:]]/).join.length < 5 or new_name.match(/^[0-9]/)
        file_data = File.read(file_name)
        meta_data = Yomu.read :metadata, file_data
        doc_title = meta_data["title"]
        if doc_title
          doc_title = File.basename(doc_title,".#{file_type}")
          if !file_name.match(/#{doc_title}/)
            new_name  = doc_title+"_"+new_name
          end
        end
      end
    end
  else
    if verbose_mode == 1
      puts "Information:\tNot using yomu to process file"
    end
  end
  new_name = new_name.gsub(/\s+/,'_')
  new_name = new_name.gsub(/[\',\(,\),\[,\]]/,'')
  new_name = new_name.gsub(/-_/,'_')
  new_name = new_name.gsub(/__/,'_')
  new_name = new_name.gsub(/_-_/,'_')
  new_name = new_name.gsub(/_-/,'_')
  new_name = new_name.gsub(/^-/,'')
  new_name = new_name.gsub(/^_/,'')
  new_name = new_name.gsub(/\+/,'and')
  new_name = new_name.gsub(/\&/,'and')
  new_name = new_name.gsub(/#{year}_#{year}/,"#{year}")
  return(new_name)
end

# update MD5 list

def update_md5s(dir_name,md5_list,ignore_list)
  if !Dir.exists?(dir_name)
    Dir.mkdir(dir_name)
  end
  dest_list = Dir.entries(dir_name)
  dest_list.each do |file_name|
    if File.file?(file_name)
      if !ignore_list.include?(file_name)
        full_name = dir_name+"/"+file_name
        md5_hash = %x[head -10 "#{full_name}" |md5]
        if !md5_list[md5_hash]
          md5_list[md5_hash] = full_name
        end
      end
    end
  end
  return md5_list
end

# Process file list

def process_files(verbose_mode,test_mode,ignore_list,sort_dir,store_dir,file_ext,file_name)
  md5_list  = {}
  file_list = []
  if file_name.match(/[A-z|0-9]/)
    if File.exist?(file_name)
      file_list[0] = file_name
    else
      puts "Warning:\tFile '"+file_name+"' does not exist"
    end
  else
    file_list = Dir.entries(sort_dir)
  end
  file_copy = 1
  file_list.each do |file_name|
    if File.file?(file_name)
      if !ignore_list.include?(file_name)
        if verbose_mode == 1
          puts
          puts "Processing:\t"+file_name
        end
        file_type = ""
        file_dot  = ""
        file_date = File.ctime(file_name).to_s.split(/ /)[0].gsub(/-/,'_')
        if verbose_mode == 1
          puts "Information:\tFile creation date: "+file_date
        end
        full_file_name = sort_dir+"/"+file_name
        full_file_type = File.mime_type?(file_name)
        if full_file_type.match(/unknown/)
          mahoro_obj = Mahoro.new(Mahoro::MIME)
          begin
            full_file_type = mahoro_obj.file(file_name)
          rescue
            full_file_type = %x[file '#{file_name}']
            if full_file_type.match(/,/)
              full_file_type = full_file_type.split(/,/)[0]
            end
            full_file_type = full_file_type.split(/: /)[1]
          end
          if full_file_type.match(/;/)
            full_file_type = full_file_type.split(/;/)[0]
          end
        end
        if verbose_mode == 1
          puts "Filetype:\t"+full_file_type
        end
        if full_file_type.match(/\//)
          file_type = full_file_type.split(/\//)[1]
        else
          file_type = full_file_type.split(/ /)[-1]
        end
        file_type = file_type.downcase
        file_type = file_type.chomp
        if file_name.match(/\./)
          if full_file_type.match(/compressed data/)
            if file_name.match(/\.tar\.|\.qcow2\./)
              file_dot = file_name.split(/\./).last(2).join(".")
            else
              file_dot = file_name.split(/\./)[-1]
            end
          else
            file_dot = file_name.split(/\./)[-1]
          end
          file_base = File.basename(file_name,file_dot)
          file_base = get_file_base(file_base)
          if !file_name.match(/\.tar\./)
            new_name  = file_base+"_"+file_date+"."+file_dot
          end
          case file_dot
          when /textClipping|ascii/
            file_dot = "txt"
          end
        else
          new_name = file_name+"_"+file_date
        end
        if !file_type.match(/[a-z]/)
          if file_dot.match(/[a-z]/)
            file_type = file_dot
          end
        end
        if file_dot != file_type
          if file_dot.match(/gz|bz/)
            if file_name.match(/tar/)
              file_type = "t"+file_dot
              new_name  = file_name.gsub(/\.tar\.#{file_dot}/,"")
            end
          else
            case file_type
            when /vax/
              file_type = "dmg"
            when /utf-8|ascii|text/
              file_type = "txt"
            else
              file_type = file_dot
            end
          end
        end
        if !file_type.match(/[a-z]/)
          if !file_dot.match(/[a-z]/)
            file_dot = file_name.split(/\./)[-1]
          end
          file_type = file_dot
        end
        file_type.gsub(/gzip/,'gz')
        file_type.gsub(/jpeg/,'jpg')
        if file_type.match(/\-/)
          file_type = file_type.split(/\-/)[0]
        end
        new_name = get_new_name(new_name,full_file_type,file_type,file_name,verbose_mode)
        if !new_name.match(/\.#{file_type}$/)
          new_name = new_name+"."+file_type
        end
        old_file = sort_dir+"/"+file_name
        old_md5  = %x[head -10 "#{old_file}" |md5]
        new_dir  = store_dir+"/"+file_type
        new_file = new_dir+"/"+new_name
        md5_list = update_md5s(new_dir,md5_list,ignore_list)
        if !md5_list[old_md5]
          if !File.exists?(new_file)
            if file_ext.match(/[A-z]/)
              if file_type.match(/#{file_ext}/)
                file_copy = 1
              else
                file_copy = 0
              end
            end
            if file_copy == 1
              puts "Moving:\t\t"+old_file+" to "+new_file
              new_dir = store_dir+"/"+file_type
              if test_mode != 1
                if !Dir.exists?(new_dir)
                  Dir.mkdir(new_dir)
                end
                system("mv \"#{old_file}\" \"#{new_file}\"")
              end
            end
          else
            puts "Information:\tFile "+new_file+" already exists"
          end
        else
          puts "Information:\tA copy of "+old_file+" already exists as "+md5_list[old_md5]
        end
      end
    end
  end
end

# Process commandline arguments

options = "chiotvVd:e:f:s:"

begin
  opt = Getopt::Std.getopts(options)
rescue
  print_usage(options)
end

if opt["t"]
  test_mode = 1
end

if opt["v"]
  verbose_mode = 1
end

if opt["h"]
  print_usage(options)
end

if opt["f"]
  file_name = opt["f"]
else
  file_name = ""
end

if opt["s"]
  sort_dir = opt["s"]
  if test_mode == 1
    puts "Source directory "+sort_dir
  end
  if !Dir.exists?(sort_dir)
    puts "Source directory "+sort_dir+" does not exist"
    exit
  end
end

if opt["e"]
  file_ext = opt["e"]
else
  file_ext = ""
end

if opt["d"]
  sort_dir = opt["d"]
  if test_mode == 1
    puts "Destination directory "+sort_dir
  end
  if !Dir.exists?(sort_dir)
    puts "Destination directory "+sort_dir+" does not exist"
    exit
  end
end

if opt["V"]
  code_name = get_code_name()
  code_version = get_code_version()
  puts code_name+" v. "+code_version
  exit
end

if opt["c"]
  process_files(verbose_mode,test_mode,ignore_list,sort_dir,store_dir,file_ext,file_name)
  exit
else
  print_usage(options)
end
