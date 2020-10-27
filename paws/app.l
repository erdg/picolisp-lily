### html utils
(de <btn> (Attr . Prg)
   (tag 'button Attr 2 Prg)
   (prinl) )
##

### app
(de work ()
   (app)
   (timeout)
   (redirect (baseHRef) *SesId "!paws") )

(de paws ()
   (html 0 "music app" "app.css" NIL
      (<ProjectHeader>)
      (collectMusicObjs)
      (setupServerEvents)
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
      # add more events here
      (serverSentEvent
         (pack (sseId> Obj)  "name")
         (any (pack (sseVar> Obj) "name")) )
      (serverSentEvent
         (pack (sseId> Obj)  "music")
         (any (pack (sseVar> Obj) "music")) ) ) )

(de collectMusicObjs ()
   (for Obj (collect 'id '+MusicObj)
      (<MusicObj> Obj) ) )

# REFACTOR THIS MESS
(de <MusicObj> (Obj)
   # see https://stackoverflow.com/questions/1077041/refresh-image-with-a-new-one-at-the-same-url/9943419#9943419
   # '(date)' and '(time)' to fool browser cache and update image
   (macro
      (<div> '(style . "display: flex; flex-direction: column; min-width: 380px;")
         (<div> '(collapsible (style . "display: flex; flex-direction: column; position: relative;"))
            (<div> '(^(list (cons 'id (pack (sseId> Obj) "music")) '(style . "align-self: start")))
               (<img> ^(list (pack "http://localhost:8080/" (blob Obj 'cropped.svg) "#" (date) (time)))) )
            (<div> '(^(list (cons 'id (pack (sseId> Obj) "name")) '(style . "order: -1")))
               (<h2> NIL
                  ^(list (; Obj nm)) ) ) )
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

