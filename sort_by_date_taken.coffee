#!/usr/bin/env coffee
# ./sort_by_date_taken.coffee <glob of images> <target dir>
fs = require 'fs'
pad = require 'pad'
argv = require('optimist')
  .boolean('d')
  .usage('Usage: $0 [-d (debug only)] -s [source glob] -t [target dir]')
  .demand(['s','t'])
  .argv

debug = argv.d

sourceFiles = argv._
sourceFiles.push(argv.s)
targetDir = argv.t
i = 1

for file in sourceFiles
  stats = fs.statSync file
  dttm = new Date stats.mtime
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
    console.log "#{i}: ", file, " -> ", [newTargetDir, fileName].join('/')
  catch e
  
  try
    fs.rmdirSync(filePath) if fs.readdirSync(filePath).length == 0 and !debug
  catch e
  i++

msg = ""
msg = "to be " if debug
console.log "\n#{i-1} Files #{msg}processed"