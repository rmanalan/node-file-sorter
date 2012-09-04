#!/usr/bin/env coffee
# ./sort_by_date_taken.coffee <glob of images> <target dir>
fs = require 'fs'
pad = require 'pad'
colors = require 'colors'
sugar = require 'sugar'
Exift = require('exift')
exift = new Exift
# im = require 'imagemagick'
# ExifImage = require('exif').ExifImage
# _ = require 'underscore'

argv = require('optimist')
  .boolean('d')
  .describe('d','Displays files to be sorted but takes no action')
  .usage('Sorts glob of photos by date taken\nUsage: $0 [-d (debug only)] -s [source glob] -t [target dir]')
  .demand(['s','t'])
  .describe('s','Source path (glob) to sort')
  .describe('t','Target path to move photos to')
  .argv

debug = argv.d

sourceFiles = argv._
sourceFiles.push(argv.s)
targetDir = argv.t

fileIdx = 0
filesProcessed = 0

startLoop = (fileIdx) -> 
  try
    file = sourceFiles[fileIdx]
    exift.readData file, (err, stat) ->
    # im.readMetadata file, (err, stat) ->
    # new ExifImage {image: file}, (err, stat) ->
      if (err)
        console.log(err)
        dttm = getCreatedDate file
      else
        # console.log "STAT", stat[0]['DateTimeOriginal']
        if stat[0]['DateTimeOriginal']
          dttm = Date.create(stat[0]['DateTimeOriginal'].split(' ')[0].replace(/\:/g,'-'))
        # if stat.exif and stat.exif.dateTimeOriginal
        #   dttm = new Date stat.exif.dateTimeOriginal
        # dt = _.find stat.exif, (obj) ->
        #   obj.tagName == 'DateTimeOriginal'
        # if dt
        #   dttm = Date.create(dt.value.split(' ')[0].replace(/\:/g,'-'))
        else
          dttm = getCreatedDate file
      processImage file, dttm
      fileIdx++
      startLoop(fileIdx) if fileIdx < sourceFiles.length
      if (fileIdx + 1) == sourceFiles.length
        msg = ""
        msg = "to be " if debug
        console.log "\n#{filesProcessed} Files #{msg}processed".bold.white        
  catch e
    fileIdx++
    startLoop(fileIdx) if fileIdx < sourceFiles.length
    console.log "Error: ".red + e.message

startLoop(fileIdx)

getCreatedDate = (file) ->
  stats = fs.statSync file
  new Date stats.mtime

processImage  = (file, dttm) ->
  yearAndMonth = dttm.getFullYear() + '-' + pad(2, dttm.getMonth()+1, "0")
  fileArray = file.split('/')
  filePath = fileArray[0..fileArray.length-2].join('/')
  fileName = fileArray[fileArray.length-1]
  newTargetDir = targetDir + yearAndMonth
  
  try
    fs.mkdirSync newTargetDir unless debug
  catch e
  
  try
    fs.renameSync file, [newTargetDir, fileName].join('/') unless debug
    newFile = [newTargetDir, fileName].join('/')
    if file != newFile
      filesProcessed++
      console.log ("#{filesProcessed}: " + file + " -> " + newFile).green
    else
      console.log ("No change: " + file).red
  catch e
  
  try
    fs.rmdirSync(filePath) if fs.readdirSync(filePath).length == 0 and !debug
  catch e

