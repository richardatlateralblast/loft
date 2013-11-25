#!/usr/bin/env ruby

# Name:         loft (Logical Organisation of Files by Type)
# Version:      0.0.2
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

# Create array for files to ignore

ignore_list=['.DS_Store','.localized']

# Set up some variables

test_mode=0
home_dir=Etc.getpwuid.dir
store_dir=home_dir+"/Documents"
sort_dir=Dir.pwd

# Get code name and version

def get_code_name
  code_name=$0
  code_name=Pathname.new(code_name)
  code_name=code_name.basename.to_s
  return code_name
end

def get_code_version
  code_version=IO.readlines($0)
  code_version=code_version.grep(/^# Version/)
  code_version=code_version[0].to_s.split(":")
  code_version=code_version[1].to_s.gsub(" ","")
  return code_version
end

# Print usage insformation

def print_usage(options)
  code_name=get_code_name()
  code_version=get_code_version()
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
  puts "-V: Print version"
  puts
  exit
end

# Clean up filename

def get_file_base(file_base)
  file_base=file_base.gsub(/[A-z]\./) { "#{$&}_"}
  file_base=file_base.gsub(/\.[A-z]/) { "_#{$&}"}
  file_base=file_base.gsub(/\._/,'_')
  file_base=file_base.gsub(/_\./,'_')
  file_base=file_base.gsub(/_$/,'')
  file_base=file_base.gsub(/\.$/,'')
  return file_base
end

def get_new_name(new_name,file_type,file_name)
  time=Time.new
  year=time.year
  yomu_types=[
    'doc','docx','xls','xlsx','ppt','pptx','odt','ods','odp', 'rtf','pdf',
    'epub','pages','numbers','keynote','mp3','jpeg','jpg', 'tiff','tif','cdf',
    'hdf','dwg'
  ]
  if yomu_types.grep(/#{file_type}/)
    if new_name.scan(/[[:alpha:]]/).join.length < 5 or new_name.match(/^[0-9]/)
      file_data=File.read(file_name)
      meta_data=Yomu.read :metadata, file_data
      doc_title=meta_data["title"]
      if doc_title
        new_name=doc_title+"_"+new_name
      end
    end
  end
  new_name=new_name.gsub(/\s+/,'_')
  new_name=new_name.gsub(/[\',\(,\),\[,\]]/,'')
  new_name=new_name.gsub(/-_/,'_')
  new_name=new_name.gsub(/__/,'_')
  new_name=new_name.gsub(/_-_/,'_')
  new_name=new_name.gsub(/_-/,'_')
  new_name=new_name.gsub(/\+/,'and')
  new_name=new_name.gsub(/\&/,'and')
  new_name=new_name.gsub(/#{year}_#{year}/,"#{year}")
  return(new_name)
end

# Process file list

def process_files(test_mode,ignore_list,sort_dir,store_dir)
  file_list=Dir.entries(sort_dir)
  file_list.each do |file_name|
    if File.file?(file_name)
      if !ignore_list.include?(file_name)
        file_type=""
        file_dot=""
        file_date=File.ctime(file_name).to_s.split(/ /)[0].gsub(/-/,'_')
        full_file_type=`file "#{file_name}"`
        file_type=full_file_type.split(/: /)[1].split(/ /)[0]
        file_type=file_type.downcase
        file_type=file_type.chomp
        if file_name.match(/\./)
          if full_file_type.match(/compressed data/)
            if file_name.match(/\.tar\.|\.qcow2\./)
              file_dot=file_name.split(/\./).last(2).join(".")
            else
              file_dot=file_name.split(/\./)[-1]
            end
          else
            file_dot=file_name.split(/\./)[-1]
          end
          file_base=File.basename(file_name,file_dot)
          file_base=get_file_base(file_base)
          new_name=file_base+"_"+file_date+"."+file_dot
          case file_dot
          when /textClipping|ascii/
            file_dot="txt"
          end
        else
          new_name=file_name
        end
        if !file_type.match(/[a-z]/)
          if file_dot.match(/[a-z]/)
            file_type=file_dot
          end
        end
        if file_dot != file_type
          case file_type
          when /vax/
            file_type="dmg"
          when /utf-8|ascii/
            file_type="txt"
          else
            file_type=file_dot
          end
        end
        if !file_type.match(/[a-z]/)
          if !file_dot.match(/[a-z]/)
            file_dot=file_name.split(/\./)[-1]
          end
          file_type=file_dot
        end
        file_type.gsub(/gzip/,'gz')
        file_type.gsub(/jpeg/,'jpg')
        file_type.gsub(/tgz/,'gz')
        if file_type.match(/\-/)
          file_type=file_type.split(/\-/)[0]
        end
        new_name=get_new_name(new_name,file_type,file_name)
        old_file=sort_dir+"/"+file_name
        new_file=store_dir+"/"+file_type+"/"+new_name
        if !File.exists?(new_file)
          puts "Moving "+old_file+" to "+new_file
          new_dir=store_dir+"/"+file_type
          if test_mode != 1
            if !Dir.exists?(new_dir)
              Dir.mkdir(new_dir)
            end
            system("mv \"#{old_file}\" \"#{new_file}\"")
          end
        else
          puts "File "+new_file+" already exists"
        end
      end
    end
  end
end

# Process commandline arguments

options="chiotVd:s:"

begin
  opt=Getopt::Std.getopts(options)
rescue
  print_usage(options)
end

if opt["t"]
  test_mode=1
end

if opt["h"]
  print_usage(options)
end

if opt["s"]
  sort_dir=opt["s"]
  if test_mode == 1
    puts "Source directory "+sort_dir
  end
  if !Dir.exists?(sort_dir)
    puts "Source directory "+sort_dir+" does not exist"
    exit
  end
end

if opt["d"]
  sort_dir=opt["d"]
  if test_mode == 1
    puts "Destination directory "+sort_dir
  end
  if !Dir.exists?(sort_dir)
    puts "Destination directory "+sort_dir+" does not exist"
    exit
  end
end

if opt["V"]
  code_name=get_code_name()
  code_version=get_code_version()
  puts code_name+" v. "+code_version
  exit
end

if opt["c"]
  process_files(test_mode,ignore_list,sort_dir,store_dir)
  exit
end
