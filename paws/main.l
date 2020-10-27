(load "../pond.l")

(class +MusicObj +Entity)
(rel id (+Need +Key +Number))
(rel nm (+Ref +String))

(rel l (+Blob))
(rel ly (+Blob))
(rel svg (+Blob))
(rel cropped.svg (+Blob))

# '+MusicObj' creator method
#
#   creates picolisp file with unique fn, e.g. 'test%1' (see 'blobFn')
#
(dm T ()
   (put!> This 'id (genKey 'id '+MusicObj))
   (put!> This 'l T)
   # put prototype in file
   (out (blob This 'l) (prin "(de " (blobFn This) " ())"))
   # load it
   (load (blob This 'l)) )

(de new-music () (new! '(+MusicObj)))

# edit picolisp file
(dm vi> ()
   (macro
      (vi (quote ^(list (blobFn This)))) )
   (load (blob This 'l)) )  # and reload it

# write lilypond file
(dm ly> ()
   (unless (: ly) (put!> This 'ly T))
   (out (blob This 'ly)
      # need to write variation of 'lilypond' here
      (lyVersion)
      (lyLayout)
      (lyInclude "lilyjazz.ily")
      (lyInclude "jazzchords.ly")
      ((blobFn This)) ) )  # call function in pl file

(dm echo> ()
   (in (blob This 'ly) (echo)) )

# render lilypond file to svg
(dm render> ()
   (unless (: svg) (put!> This 'svg T))
   (unless (: cropped.svg) (put!> This 'cropped.svg T))
   (t (call 'lilypond "-dcrop" "-dbackend=svg" "-o" (blobDir This) (blob This 'ly))) )

# FIXME - this method makes a mess of the console. figure out way to mute
# output
(dm clean> ()
   (let CleanSvg
      (in (blob This 'svg)
         (pack
            (make
               (while (line T)
                  # remove <a> tags from svg
                  (unless (or (pre? "<a" @) (pre? "</a>" @))
                     (link @) ) ) ) ) )
      (out (blob This 'svg) (prin CleanSvg)) )
   (let CleanCroppedSvg
      (in (blob This 'cropped.svg)
         (pack
            (make
               (while (line T)
                  # remove <a> tags from svg
                  (unless (or (pre? "<a" @) (pre? "</a>" @))
                     (link @) ) ) ) ) )
      (out (blob This 'cropped.svg) (prin CleanCroppedSvg)) ) )

# send updated SVG to the browser
(dm send> ()
   (let @Sse (any (pack "*Obj" (: id)))
      (macro
         (serverSend @Sse
            (<MusicObj> This) ) )
      T ) )

(de <MusicObj> (Obj)
   # see https://stackoverflow.com/questions/1077041/refresh-image-with-a-new-one-at-the-same-url/9943419#9943419
   # '(date)' and '(time)' to fool browser cache and update image
   (macro
      (<div> '(style . "display: flex; flex-direction: column; min-width: 380px;")
         # for some reason the 'img' won't show on update if it's not first...
         # haven't figured out why, but a little flexbox hacking gives the 
         # desired result for now
         (<div> '(collapsible (style . "display: flex; flex-direction: column; position: relative;"))
            (<div> '(style . "align-self: start")
               (<img> ^(list (pack "http://localhost:8080/" (blob Obj 'cropped.svg) "#" (date) (time)))) )
            (<h2> '(style . "order: -1")
               ^(list (; Obj nm))) )
         # (<btn> '((type . "button") (class . "collapsible") (style . "order: -1"))
         #    ^(list (; Obj nm)))
         (<div> "collapsible-content"
            (<table> NIL
               NIL  # No title
               '((align "Tracks")(align "Tempo")(align "Time")(align "Created"))
               (<row> NIL
                  "take1.wav" "86" "0:16" "2020-10-26" )
               (<row> NIL
                  "messed-up-take.wav" "64" "0:22" "2020-10-26") ) )
         ) ) )

(de <RecordButton> ()
   (<btn> '((type . "button") "record")
      NIL ) )

(de collapsibleJS ()
   (<javascript>
     "var coll = document.getElementsByClassName('collapsible');
      var i;

for (i = 0; i < coll.length; i++) {
        coll[i].addEventListener('click', function() {
               this.classList.toggle('active');
                   var content = this.nextElementSibling;
                       if (content.style.maxHeight){
                                content.style.maxHeight = null;
                                    } else {
                                             content.style.maxHeight = content.scrollHeight + 'px';
                                                 }
                                                   });
   }" ) )

(dm work> ()
   (vi> This)
   (ly> This)
   (render> This)
   (clean> This)
   (send> This) )

(dm rename> (Name)
   (put!> This 'nm Name)
   (send> This) )

# start a new project or change to an existing project
#
# each project is a directory, with a db file and +Blob's
(de stitch (Name)
   (let (Pool (pack "db/" Name "/" Name ".db")
         Blob (pack "db/" Name "/") )
      (setq
         *Pool Pool
         *Blob Blob )
      (call "mkdir" "-p" *Blob)
      (pool *Pool) ) )

(setq
   *Pool "db/test/test.db"
   *Blob "db/test/" )

(de main ()
   (call "mkdir" "-p" *Blob)
   (pool *Pool *Dbs)
   # load +MusicObj's
   (for Obj (collect 'id '+MusicObj) (load (blob Obj 'l))) )

(de go () (server 8080 "!work"))

(load "@lib/http.l" "@lib/xhtml.l")

(de <btn> (Attr . Prg)
   (tag 'button Attr 2 Prg)
   (prinl) )

(de work ()
   (app)
   (timeout)
   (redirect (baseHRef) *SesId "!musicApp") )

(de musicApp ()
   (html 0 "music app" "app.css" NIL
      (<ProjectHeader>)
      (setupServerEvents)
      (collectMusicObjs)
      (collapsibleJS)
      ) )

(de <ProjectHeader> ()
   (let Prj (pack (car (split (chop (blobFn)) "%")))  # current (default/test) project on app start
      # (serverSentEvent "project" '*Project)
      (<h1> '(id . "project")
         "Project - " Prj) ) )

# server sent event for each +MusicObj
(de setupServerEvents ()
   (for Obj (collect 'id '+MusicObj)
      (serverSentEvent
         (sseId> Obj)
         (sseVar> Obj) ) ) )

# sse helpers, e.g. *SsEvt -> (("obj3" *Obj3) ... )
(dm sseVar> () (any (pack "*Obj" (: id))))
(dm sseId>  () (pack "obj" (: id)))  # connects to <div> from 'collectMusicObjs'

# <div> containing svg for each +MusicObj
(de collectMusicObjs ()
   (for Obj (collect 'id '+MusicObj)
      (<MusicDiv> Obj) ) )

(de <MusicDiv> (Obj)
   (<div>
      (list
         (cons 'id (sseId> Obj))  # connect to sse
         '(style . "width: min-content; padding-top: 16px; padding-bottom: 32px") )
      (<MusicObj> Obj) ) )


### utils

# return list of all +MusicObjs with (optional) names
(de musicObjs ()
   (make
      (for Obj (collect 'id '+MusicObj)
         (link
            (list Obj (if (; Obj nm) @)) ) ) ) )

# list projects
(de projects () (chdir "db/" (dir)))

# returns blob subdirectory
# (blobDir '{A1}) -> "db/blob/A/"
# (blobDir '{2}) -> "db/blob/"
(de blobDir (Obj)
   (pack
      (glue "/"
         (filter '((X) (not (num? (any (car X)))))
            (split (chop (blob Obj)) "/") ) )
      "/" ) )

# returns fn from +MusicObj
(de blobFn (Obj)
   (and (blobDir Obj)
      (chop @)
      (split @ "/" ".")
      (pack (cdr @) "%" (; Obj id))
      (any @) ) )  # -> e.g. test%1 (project%id)

NIL
###
# the following was an attempt to dynamically add server events after the app is running
# i've decided it's a waste of time for now

(de serverSentEvent+ (Id Var . Prg)
# same as 'serverSentEvent' but uses 'insertAdjacentHTML' instead of 'innerHTML'
# used to add new events to the document AFTER the document has loaded
###
   (allow "!ssEvt")
   (<javascript>
      "(new EventSource(SesId+'!ssEvt?'+'"
      Id
      "')).onmessage = function(ev) {if (ev.data.charAt(0) == '&') document.title = ev.data.substr(1); else document.getElementById('"
      Id
      "').insertAdjacentHTML = ('beforeend', ev.data);}" )
   (if (assoc Id *SsEvts)
      (con @ (cons Var (unless (val Var) Prg)))
      (push '*SsEvts (cons Id Var Prg)) ) )

(de serverSentEvent+js (Id Var . Prg)
# FIXME - attempt to insert/execute script into dom, to dynamically add server
# events after the app is running. 'serverSentEvent+' is not sufficient because
# the browser will not run <script>'s created with
# innerHTML/insertAdjacentHTML. need to do something like:
#
#    var newScript = document.createElement('script')
#    newScript.text = script text goes here
#    document.getElementById('id').append(newScript)
   (allow "!ssEvt")
   (<javascript>
      "(new EventSource(SesId+'!ssEvt?'+'" Id "')).onmessage = function(ev) {
         if (ev.data.charAt(0) == '&') {
            document.title = ev.data.substr(1);
         } else {
            var newScript = document.createElement('script');
            newScript.text = ev.data;
            document.getElementById('" Id "').appendChild(newScript);
         }
      }" )
   (if (assoc Id *SsEvts)
      (con @ (cons Var (unless (val Var) Prg)))
      (push '*SsEvts (cons Id Var Prg)) ) )
