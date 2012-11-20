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
# ex = require 'exiv2'

argv = require('optimist')
  .boolean('d')
  .describe('d','Displays files to be sorted but takes no action')
  .boolean('n')
  .describe('n','Append the name of the directory to the filename')  
  .usage('Sorts glob of photos by date taken\nUsage: $0 [-d (debug only)] -s [source glob] -t [target dir]')
  .demand(['s','t'])
  .describe('s','Source path (glob) to sort')
  .describe('t','Target path to move photos to')
  .string('r')
  .describe('r','Append a description to moved files')
  .argv

debug = argv.d
rename = argv.n
appendString = argv.r

sourceFiles = argv._
sourceFiles.push(argv.s)
targetDir = argv.t

fileIdx = 0
globalFileIdx = fileIdx
filesProcessed = 0

startLoop = (fileIdx) -> 
  try
    file = sourceFiles[fileIdx]
    exift.readData file, (err, stat) ->
    # im.readMetadata file, (err, stat) ->
    # new ExifImage {image: file}, (err, stat) ->
    # ex.getImageTags file, (err, stat) ->
      if (err)
        console.log(err.red)
        dttm = getCreatedDate file
      else
        # console.log "STAT", stat[]
        if stat[0]['DateTimeOriginal']
        # if stat["Exif.Photo.DateTimeOriginal"]
          dttm = Date.create(stat[0]['DateTimeOriginal'].split(' ')[0].replace(/\:/g,'-'))
          # dttm = Date.create(stat["Exif.Photo.DateTimeOriginal"].split(' ')[0].replace(/\:/g,'-'))
        # if stat.exif and stat.exif.dateTimeOriginal
        #   dttm = new Date stat.exif.dateTimeOriginal
        # dt = _.find stat.exif, (obj) ->
        #   obj.tagName == 'DateTimeOriginal'
        # console.log dt.value
        # if dt
        #   dttm = Date.create(dt.value.split(' ')[0].replace(/\:/g,'-'))
        else
          dttm = getCreatedDate file
      processImage file, dttm
      globalFileIdx++
      startLoop(globalFileIdx) if globalFileIdx < sourceFiles.length
      if (globalFileIdx) == sourceFiles.length
        msg = ""
        msg = "to be " if debug
        console.log "\n#{filesProcessed} Files #{msg}processed".bold.white        
  catch e
    globalFileIdx++
    startLoop(globalFileIdx) if globalFileIdx < sourceFiles.length
    console.log "Error: ".red + e.message

startLoop(globalFileIdx)
# globalFileIdx++
# startLoop(globalFileIdx)
# globalFileIdx++
# startLoop(globalFileIdx)

getCreatedDate = (file) ->
  stats = fs.statSync file
  new Date stats.mtime

processImage  = (file, dttm) ->
  yearAndMonth = dttm.getFullYear() + '-' + pad(2, dttm.getMonth()+1, "0")
  fileArray = file.split('/')
  filePath = fileArray[0..fileArray.length-2].join('/')
  dirName = fileArray[fileArray.length-2]
  fileName = fileArray[fileArray.length-1]
  newTargetDir = targetDir + yearAndMonth
  
  # Make new dir
  try
    fs.mkdirSync newTargetDir unless debug
  catch e
    # console.log "Error creating directory: ".bold.red + e.message
  
  # Rename file
  try
    isImageOrMovie = /\.(dng|nef|jpg|mov|avi|gif|png|tif|jpeg|mp4|bmp|psd)$/i.test(file)
    if rename and isImageOrMovie 
      appendToFilename = dirName + " - " 
    else if appendString and isImageOrMovie
      appendToFilename = appendString + " - "
    else
      appendToFilename = ""
    newFile = [newTargetDir, appendToFilename + fileName].join('/')
    if file != newFile and isImageOrMovie
      fs.renameSync file, newFile unless debug
      filesProcessed++
      console.log ("#{filesProcessed}: " + file + " -> " + newFile).green
    else
      console.log ("No change: " + file).red
  catch e
    console.log "Error moving file: ".bold.red + e.message
  
  # Delete dir if empty
  try
    fileCount = fs.readdirSync(filePath).length - 1
    fs.rmdirSync(filePath) if fileCount == 0 and !debug
  catch e
    console.log "Error removing directory: ".bold.red + e.message

