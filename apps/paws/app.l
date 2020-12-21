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
   (html 0 "paws - the picolisp audio workstation" "app.css" NIL
      (<ProjectHeader>)
      (<ProjectContent>)
      (setupServerEvents)
      (collapsibleJS)
      ) )

(de <ProjectHeader> ()
   (<div> 'logo
      (<h5> NIL (<strong> "||") " paws")
      (<p> NIL "the picolisp audio workstation")
      (<RecordButton>) )
      (<CurrentProject> ) )

(de <CurrentProject> ()
   (let Prj (pack (car (split (chop (blobFn)) "%")))  # current (default/test) project on app start
      (<h1> NIL
         "Projects / " Prj) ) )

(de <ProjectContent> ()
      (<tab>
         ("charts"
            (collectCharts) )
         ("tracks"
            (collectTracks) )
         ("mixes"
            (<h2> NIL "mixes") ) ) )

# server sent event for each +Chart
(de setupServerEvents ()
   (serverSentEvent "tracks" '*Tracks)
   (for Obj (collect 'id '+Chart)
      # add more events here
      (serverSentEvent
         (pack (sseId> Obj)  "name")
         (any (pack (sseVar> Obj) "name")) )
      (serverSentEvent
         (pack (sseId> Obj)  "chart")
         (any (pack (sseVar> Obj) "chart")) ) ) )

(de collectCharts ()
   (for Obj (collect 'id '+Chart)
      (<Chart> Obj) ) )

# REFACTOR THIS MESS
(de <Chart> (Obj)
   # see https://stackoverflow.com/questions/1077041/refresh-image-with-a-new-one-at-the-same-url/9943419#9943419
   # '(date)' and '(time)' to fool browser cache and update image
   (macro
      (<div> '(style . "display: flex; flex-direction: column; margin-bottom: 16px")
         (<div> '(#^(list (if (; Obj tracks) 'collapsible))
                  (style . "display: flex; flex-direction: column; position: relative;") )
            (<div> '(^(list (cons 'id (pack (sseId> Obj) "chart")) '(style . "align-self: start")))
               (<img> ^(list (pack "http://localhost:8080/" (blob Obj 'cropped.svg) "#" (date) (time)))) )
            (<div> '(^(list (cons 'id (pack (sseId> Obj) "name")) '(style . "order: -1")))
               (<h2> NIL
                  ^(list (; Obj nm)) ) ) )
         (if (; Obj tracks)
            (<div> NIL #"collapsible-content"
               (<TracksTable> @) ) )
         ) ) )

(de collectTracks ()
   (<div> '((id . "tracks") (style . "margin-top: 32px;"))
      (<TracksTable>) ) )

(de <TracksTable> (Tracks)
   (<table> NIL NIL  # No title
      '((align "track") (align "channels") (align "time") (align "size"))
      (for Track (list-tracks Tracks)
         (macro
            (<row> NIL
               ^ Track (<TrackMenu>) ) ) ) ) )

(de <TrackMenu> ()
   (<div> '(style . "position: relative;")
      (<div> "collapsible dotmenu"
         (<span> 'dot)
         (<span> 'dot)
         (<span> 'dot) )
      (<div> "collapsible-content trackmenu"
         (<ul> NIL
            (<li> NIL "preloopify")
            (<li> NIL "loopify") ) ) ) )

(de <RecordButton> ()
   (<div> 'record
      (<bar>
         ("record"
            ("new mono track" "!api-record")
            ("new stereo track" NIL) ) ) ) )

(de <RecordButton%> ()
   (<btn> '((type . "button") "record%")
      "record" ) )

(de openLinkJS () 
   (<javascript>
      "function openLink(evt, animName) {
         var i, x, tablinks;
         x = document.getElementsByClassName('city');
         for (i = 0; i < x.length; i++) {
            x[i].style.display = 'none';
         }
         tablinks = document.getElementsByClassName('tablink');
         for (i = 0; i < x.length; i++) {
            tablinks[i].className = tablinks[i].className.replace(' w3-red', '');
         }
         document.getElementById(animName).style.display = 'block';
         evt.currentTarget.className += ' w3-red';
      }") )


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

