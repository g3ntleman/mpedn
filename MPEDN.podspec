# coding: utf-8

Pod::Spec.new do |s|

  s.name         = "MPEDN"
  s.version      = "2.0.0"
  s.summary      = "An EDN (Extensible Data Notation) Objective C library for OS X and iOS."

  s.description  = <<-DESC
    The library includes:

    * `MPEdnCoder`, a parser / generator for reading EDN into equivalent Cocoa data and for writing EDN from Cocoa data structures.

    For most uses, parsing EDN is as simple as:

        [@"{:a 1}" ednStringToObject];

    Which returns the parsed object or nil on error.

    And to generate EDN from a Cocoa object:

        [myObject objectToEdnString];

    See the headers for API docs.
    DESC

  s.homepage     = "https://github.com/g3ntleman/mpedn"
  s.license      = { :type => "Eclipse", :file => "LICENSE" }
  s.author       = { "Matthew Phillips, Dirk Theisen" => "m@mattp.name, d.theisen@objectpark.org" }
  s.source       = { :git => "https://github.com/g3ntleman/mpedn.git", :tag => "2.0.0" }
  s.source_files = "MPEdn"
  s.requires_arc = true
end
